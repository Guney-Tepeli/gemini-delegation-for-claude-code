#!/usr/bin/env bash
# Delegates a single task to Gemini (Antigravity CLI) and measures its cost.
#
# WHY A WRAPPER: a correct call needs three things at once — cd into the repo,
# pass `--output-format json`, and add `--mode accept-edits` for write work.
# Reminding the model of these every time did not work (measured: flag skipped,
# token report fabricated). The call pattern is fixed here.
#
# Usage:
#   gemini-is.sh <repo-path> "<task>"            # read-only
#   gemini-is.sh --write <repo-path> "<task>"    # may modify files
#
# Output: TOKEN line first, then Gemini's answer. Full answer in the ANSWER file.
#
# TOKEN SAVING: Gemini's answer enters Claude's context and is resent on every
# later turn, so a long answer wipes out the gain. The printed answer is capped
# at GEMINI_MAX_LINES lines (default 40) AND GEMINI_MAX_CHARS characters
# (default 3000, ~750 tokens). The full text stays in the ANSWER file.
#
# Working files live in a private 0700 temp directory (umask 077). The raw JSON
# path is never printed to stdout — it is measurement data, not context.
#
# SCOPE: the `agy` binary path is hardcoded (no env override) and <repo-path>
# must resolve inside ALLOWED_ROOTS below, or the run is refused with exit 2.
#
# Exit codes:
#   0  success
#   1  agy failed or produced no output
#   2  usage / environment error
#   3  agy status is not SUCCESS
#   4  empty answer (usually a silently denied action — see the DENIED line)
#   5  agy JSON could not be parsed
set -euo pipefail
umask 077

# Pinned on purpose: an env-var override would let anything be launched through
# this script while the audit trail still reads gemini-is.sh. Claude is granted
# permission to this script, never to `agy` itself, so the path must be fixed.
AGY="$HOME/.local/bin/agy"

# EDIT THIS LIST: delegation is refused outside these roots. Keep it as narrow
# as your work allows — every path below is a directory `agy` may run in.
ALLOWED_ROOTS=(
  "$HOME/Documents/GitHub"
)

MODE=()
case "${1:-}" in
  --write)
    MODE=(--mode accept-edits); shift ;;
  --yaz)
    echo "WARNING: --yaz is deprecated, use --write" >&2
    MODE=(--mode accept-edits); shift ;;
esac

REPO="${1:?usage: gemini-is.sh [--write] <repo-path> \"<task>\"}"
TASK="${2:?task text required}"

[ -d "$REPO" ] || { echo "ERROR: no such directory: $REPO" >&2; exit 2; }
[ -x "$AGY" ] || { echo "ERROR: agy not found: $AGY" >&2; exit 2; }

# Root containment. Resolved with `pwd -P`, so a symlinked path cannot point out
# of an allowed root. Checked before `cd`, and before agy sees anything.
REPO_REAL="$(cd "$REPO" 2>/dev/null && pwd -P)" || {
  echo "ERROR: cannot resolve directory: $REPO" >&2; exit 2; }
IN_ROOT=0
for ROOT in "${ALLOWED_ROOTS[@]}"; do
  ROOT_REAL="$(cd "$ROOT" 2>/dev/null && pwd -P)" || continue
  case "$REPO_REAL/" in
    "$ROOT_REAL"/*) IN_ROOT=1; break ;;
  esac
done
if [ "$IN_ROOT" -ne 1 ]; then
  echo "ERROR: $REPO_REAL is outside every allowed root:" >&2
  printf '  %s\n' "${ALLOWED_ROOTS[@]}" >&2
  echo "ERROR: edit ALLOWED_ROOTS in $0 if this directory should be allowed" >&2
  exit 2
fi

TMPROOT="${TMPDIR:-/tmp}"
WORKDIR="$(mktemp -d "${TMPROOT%/}/gemini-is.XXXXXXXX")"
RAW="$WORKDIR/raw.json"
ERRLOG="$WORKDIR/stderr.log"
ANSWER="$WORKDIR/answer.md"

cd "$REPO"
set +e
"$AGY" -p "$TASK" ${MODE[@]+"${MODE[@]}"} --output-format json >"$RAW" 2>"$ERRLOG"
AGY_CODE=$?
set -e

if [ ! -s "$RAW" ]; then
  echo "ERROR: agy produced no output (exit code $AGY_CODE). Last stderr lines:" >&2
  tail -3 "$ERRLOG" >&2
  echo "ERROR: raw stderr kept at $ERRLOG" >&2
  exit 1
fi

# JSON exists, so report the run even when agy exited non-zero: the TOKEN and
# DENIED lines are the only trustworthy failure signal.
set +e
MAX_LINES="${GEMINI_MAX_LINES:-${GEMINI_MAX_SATIR:-40}}" \
MAX_CHARS="${GEMINI_MAX_CHARS:-3000}" \
python3 - "$RAW" "$ANSWER" <<'PY'
import json, os, sys


def cap(name, default):
    try:
        value = int(os.environ.get(name, default))
    except ValueError:
        print("ERROR: %s must be an integer, using %s" % (name, default),
              file=sys.stderr)
        return default
    return value if value > 0 else default


try:
    data = json.load(open(sys.argv[1]))
except (ValueError, OSError) as exc:
    print("ERROR: could not parse agy JSON: %s" % exc, file=sys.stderr)
    sys.exit(5)

usage = data.get("usage", {})
status = data.get("status", "?")
print("TOKEN %s | TIME %ss | TURN %s | STATUS %s" % (
    usage.get("total_tokens", "?"), round(data.get("duration_seconds", 0)),
    data.get("num_turns", "?"), status))

denied = data.get("denied_actions")
if denied:
    print("DENIED: %s" % ", ".join(sorted({d.get("action", "?") for d in denied})))

answer = (data.get("response") or "").strip()
with open(sys.argv[2], "w") as handle:
    handle.write(answer + "\n")

cap_lines = cap("MAX_LINES", 40)
cap_chars = cap("MAX_CHARS", 3000)

print("---")
if not answer:
    print("(empty answer)")
else:
    lines = answer.splitlines()
    shown = "\n".join(lines[:cap_lines])
    cut_lines = len(lines) - cap_lines
    if len(shown) > cap_chars:
        print(shown[:cap_chars])
        print("... [character limit reached; full output in file]")
    else:
        print(shown)
        if cut_lines > 0:
            print("... [%d more lines cut; full output in file]" % cut_lines)

if not answer:
    sys.exit(4)
sys.exit(0 if status == "SUCCESS" else 3)
PY
PY_CODE=$?
set -e

echo "---"
if [ -f "$ANSWER" ]; then
  echo "ANSWER: $ANSWER"
else
  echo "ERROR: no answer file was written; working files kept in $WORKDIR" >&2
fi

if [ "$AGY_CODE" -ne 0 ]; then
  echo "ERROR: agy exited with code $AGY_CODE; stderr kept at $ERRLOG" >&2
  exit 1
fi
exit "$PY_CODE"

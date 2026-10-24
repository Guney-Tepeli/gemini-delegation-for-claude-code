#!/usr/bin/env bash
# Contract tests for bin/gemini-is.sh. Runs the real, unmodified script against
# a stub agy (tests/stub/agy), so no Gemini quota is spent and every run is
# deterministic.
#
# HOW THE STUB GETS IN: the script pins agy to $HOME/.local/bin/agy and its
# allowed root to $HOME/Documents/GitHub. Each test sets HOME to a fresh fake
# home, which moves both — the script itself is never edited.
#
# Usage: tests/test_wrapper.sh            (exit 0 = all passed)
set -u

HERE="$(cd "$(dirname "$0")" && pwd -P)"
WRAPPER="$HERE/../bin/gemini-is.sh"
STUB="$HERE/stub/agy"
SANDBOX="$(mktemp -d "${TMPDIR:-/tmp}/gemini-is-test.XXXXXXXX")"
trap 'rm -rf "$SANDBOX"' EXIT

PASS=0
FAIL=0
FAILED=()

# --- harness ---------------------------------------------------------------

# Fresh fake home: stub agy installed, one allowed repo, private TMPDIR.
setup() {
  FAKE_HOME="$SANDBOX/home.$1"
  REPO="$FAKE_HOME/Documents/GitHub/repo"
  WORK_TMP="$FAKE_HOME/tmp"
  mkdir -p "$FAKE_HOME/.local/bin" "$REPO" "$WORK_TMP"
  cp "$STUB" "$FAKE_HOME/.local/bin/agy"
  chmod 755 "$FAKE_HOME/.local/bin/agy"
  unset STUB_JSON STUB_STDERR STUB_EXIT
}

# Writes a JSON body for the stub to emit.
stub_json() {
  printf '%s' "$1" >"$FAKE_HOME/agy.json"
  export STUB_JSON="$FAKE_HOME/agy.json"
}

# Runs the wrapper; sets OUT, ERR, CODE.
run() {
  HOME="$FAKE_HOME" TMPDIR="$WORK_TMP" bash "$WRAPPER" "$@" \
    >"$FAKE_HOME/out" 2>"$FAKE_HOME/err"
  CODE=$?
  OUT="$(cat "$FAKE_HOME/out")"
  ERR="$(cat "$FAKE_HOME/err")"
}

check() {  # check <name> <condition-exit-status>
  if [ "$2" -eq 0 ]; then
    PASS=$((PASS + 1)); printf '  ok    %s\n' "$1"
  else
    FAIL=$((FAIL + 1)); FAILED+=("$1"); printf '  FAIL  %s\n' "$1"
    printf '        exit=%s\n        stdout: %s\n        stderr: %s\n' \
      "$CODE" "$(printf '%s' "$OUT" | head -5 | tr '\n' '|')" \
      "$(printf '%s' "$ERR" | head -5 | tr '\n' '|')"
  fi
}

has()    { printf '%s' "$1" | grep -qF -- "$2"; }
code_is() { [ "$CODE" -eq "$1" ]; }
logged() { grep -qxF -- "$1" "$FAKE_HOME/stub.log"; }
answer_file() { printf '%s\n' "$OUT" | sed -n 's/^ANSWER: //p'; }

OK_JSON='{"status":"SUCCESS","response":"hello","usage":{"total_tokens":123},"duration_seconds":4.6,"num_turns":1}'

# --- exit codes ------------------------------------------------------------
echo "exit codes"

setup e0; stub_json "$OK_JSON"; run "$REPO" "task"
check "0  success prints TOKEN line and answer" \
  "$(code_is 0 && has "$OUT" 'TOKEN 123 | TIME 5s | TURN 1 | STATUS SUCCESS' && has "$OUT" 'hello'; echo $?)"

setup e1a; run "$REPO" "task"
check "1  agy produced no stdout" \
  "$(code_is 1 && has "$ERR" 'agy produced no output'; echo $?)"

setup e1b; stub_json "$OK_JSON"; export STUB_EXIT=7; run "$REPO" "task"
check "1  agy non-zero exit wins over a valid JSON body" \
  "$(code_is 1 && has "$OUT" 'TOKEN 123' && has "$ERR" 'exited with code 7'; echo $?)"

setup e2a; run
check "2  missing arguments" "$(code_is 2 && has "$ERR" 'usage'; echo $?)"

setup e2d; run "$REPO"
check "2  missing task text" "$(code_is 2 && has "$ERR" 'task text required'; echo $?)"

setup e2b; rm "$FAKE_HOME/.local/bin/agy"; run "$REPO" "task"
check "2  agy binary missing" "$(code_is 2 && has "$ERR" 'agy not found'; echo $?)"

setup e2c; run "$REPO/does-not-exist" "task"
check "2  repo directory missing" "$(code_is 2 && has "$ERR" 'no such directory'; echo $?)"

setup e3; stub_json '{"status":"ERROR","response":"partial","usage":{}}'; run "$REPO" "task"
check "3  status other than SUCCESS" "$(code_is 3 && has "$OUT" 'STATUS ERROR'; echo $?)"

setup e4; stub_json '{"status":"SUCCESS","response":"","denied_actions":[{"action":"command"},{"action":"read_file"},{"action":"command"}]}'
run "$REPO" "task"
check "4  empty answer, DENIED line deduplicated and sorted" \
  "$(code_is 4 && has "$OUT" 'DENIED: command, read_file' && has "$OUT" '(empty answer)'; echo $?)"

setup e5; stub_json '{not json'; run "$REPO" "task"
check "5  malformed JSON" "$(code_is 5 && has "$ERR" 'could not parse agy JSON'; echo $?)"

# --- call pattern ----------------------------------------------------------
echo "call pattern"

setup c1; stub_json "$OK_JSON"; run "$REPO" "read task"
check "read-only: exact argv, no --mode" \
  "$(logged 'ARG=-p' && logged 'ARG=read task' && logged 'ARG=--output-format' \
     && logged 'ARG=json' && ! grep -q 'ARG=--mode' "$FAKE_HOME/stub.log"; echo $?)"
check "agy runs inside the repo" "$(logged "PWD=$(cd "$REPO" && pwd -P)"; echo $?)"

setup c2; stub_json "$OK_JSON"; run --write "$REPO" "edit task"
check "--write adds --mode accept-edits" \
  "$(logged 'ARG=--mode' && logged 'ARG=accept-edits'; echo $?)"

setup c3; stub_json "$OK_JSON"; run --yaz "$REPO" "edit task"
check "--yaz still works and warns" \
  "$(code_is 0 && logged 'ARG=accept-edits' && has "$ERR" 'deprecated'; echo $?)"

setup c4; stub_json "$OK_JSON"
TRICKY='a "quoted" $(touch PWNED) `id` ; rm -rf x | y'
run "$REPO" "$TRICKY"
check "task text reaches agy verbatim, never shell-evaluated" \
  "$(logged "ARG=$TRICKY" && [ ! -e "$REPO/PWNED" ]; echo $?)"

setup c5; stub_json "$OK_JSON"
mkdir -p "$SANDBOX/evil"; printf '#!/bin/sh\ntouch %s/AGY_OVERRIDE\n' "$SANDBOX/evil" >"$SANDBOX/evil/agy"
chmod +x "$SANDBOX/evil/agy"
AGY="$SANDBOX/evil/agy" PATH="$SANDBOX/evil:$PATH" run "$REPO" "task"
check "AGY / PATH cannot redirect the launched binary" \
  "$(code_is 0 && [ ! -e "$SANDBOX/evil/AGY_OVERRIDE" ]; echo $?)"

# --- scope (ALLOWED_ROOTS) -------------------------------------------------
echo "scope"

setup s1; stub_json "$OK_JSON"; mkdir -p "$FAKE_HOME/outside"; run "$FAKE_HOME/outside" "task"
check "outside every root: exit 2, agy never called" \
  "$(code_is 2 && has "$ERR" 'outside every allowed root' && [ ! -e "$FAKE_HOME/stub.log" ]; echo $?)"

setup s2; stub_json "$OK_JSON"; mkdir -p "$FAKE_HOME/outside"
ln -s "$FAKE_HOME/outside" "$REPO/escape"; run "$REPO/escape" "task"
check "symlink inside a root pointing out: refused" \
  "$(code_is 2 && [ ! -e "$FAKE_HOME/stub.log" ]; echo $?)"

setup s3; stub_json "$OK_JSON"; mkdir -p "$FAKE_HOME/Documents/GitHub-evil"
run "$FAKE_HOME/Documents/GitHub-evil" "task"
check "sibling with root as name prefix (GitHub-evil): refused" \
  "$(code_is 2 && [ ! -e "$FAKE_HOME/stub.log" ]; echo $?)"

setup s4; stub_json "$OK_JSON"; mkdir -p "$FAKE_HOME/Documents/outside-dots"
run "$REPO/../../outside-dots" "task"
check "dot-dot path resolving outside: refused" \
  "$(code_is 2 && [ ! -e "$FAKE_HOME/stub.log" ]; echo $?)"

setup s5; stub_json "$OK_JSON"; run "$REPO/../repo" "task"
check "dot-dot path resolving inside: allowed" "$(code_is 0; echo $?)"

# --- output caps -----------------------------------------------------------
echo "output caps"

LONG_LINES="$(python3 -c 'import json;print(json.dumps({"status":"SUCCESS","response":"\n".join("line%d"%i for i in range(100))}))')"
setup o1; stub_json "$LONG_LINES"; run "$REPO" "task"
check "line cap 40 by default, rest reported" \
  "$(has "$OUT" 'line39' && ! has "$OUT" 'line40' && has "$OUT" '60 more lines cut'; echo $?)"
check "full answer kept in ANSWER file" \
  "$([ "$(wc -l <"$(answer_file)")" -eq 100 ]; echo $?)"

BLOB="$(python3 -c 'import json;print(json.dumps({"status":"SUCCESS","response":"A"*20000}))')"
setup o2; stub_json "$BLOB"; run "$REPO" "task"
check "char cap 3000 on a single huge line" \
  "$(code_is 0 && has "$OUT" 'character limit reached' && [ "${#OUT}" -lt 3600 ]; echo $?)"

setup o3; stub_json "$LONG_LINES"; GEMINI_MAX_LINES=5 run "$REPO" "task"
check "GEMINI_MAX_LINES=5" "$(has "$OUT" 'line4' && ! has "$OUT" 'line5' && has "$OUT" '95 more lines'; echo $?)"

setup o4; stub_json "$LONG_LINES"; GEMINI_MAX_SATIR=3 run "$REPO" "task"
check "GEMINI_MAX_SATIR legacy alias" "$(has "$OUT" '97 more lines'; echo $?)"

setup o5; stub_json "$LONG_LINES"; GEMINI_MAX_LINES=abc run "$REPO" "task"
check "non-integer cap: warns, falls back to 40" \
  "$(code_is 0 && has "$ERR" 'must be an integer' && has "$OUT" '60 more lines'; echo $?)"

setup o6; stub_json "$LONG_LINES"; GEMINI_MAX_LINES=-3 run "$REPO" "task"
check "non-positive cap falls back to 40" "$(has "$OUT" '60 more lines'; echo $?)"

# --- file hygiene ----------------------------------------------------------
echo "file hygiene"

setup f1; stub_json "$OK_JSON"; export STUB_STDERR="agy noise"; run "$REPO" "task"
WD="$(dirname "$(answer_file)")"
check "work dir is private (0700)" "$([ "$(stat -f '%Lp' "$WD")" = 700 ]; echo $?)"
check "answer file is private (0600)" "$([ "$(stat -f '%Lp' "$(answer_file)")" = 600 ]; echo $?)"
check "raw JSON path never printed" "$(! has "$OUT$ERR" 'raw.json'; echo $?)"
check "work dir lives under TMPDIR, random name" \
  "$(printf '%s' "$WD" | grep -qE "^$WORK_TMP/+gemini-is\.[A-Za-z0-9]{8}$"; echo $?)"
check "agy stderr not echoed on success" "$(! has "$OUT$ERR" 'agy noise'; echo $?)"

# --- robustness: valid JSON, unexpected shape -------------------------------
# agy's JSON is an external contract. A schema change should land on a
# documented exit code, not a Python traceback.
echo "robustness"

# Measurement fields degrade to "?"; a broken top level or answer is exit 5.
# Format: name|expected-exit|expected-stdout-fragment|json
for case_ in 'array|5||[]' \
             'null-usage|0|TOKEN ? |{"status":"SUCCESS","response":"x","usage":null}' \
             'string-duration|0|TIME ?s|{"status":"SUCCESS","response":"x","duration_seconds":"4"}' \
             'number-response|5||{"status":"SUCCESS","response":42}' \
             'string-denied|4|DENIED: command|{"status":"SUCCESS","response":"","denied_actions":["command"]}' \
             'object-denied|4|DENIED: command|{"status":"SUCCESS","response":"","denied_actions":{"action":"command"}}'; do
  name="${case_%%|*}"; rest="${case_#*|}"
  want="${rest%%|*}"; rest="${rest#*|}"
  frag="${rest%%|*}"; body="${rest#*|}"
  setup "r-$name"; stub_json "$body"; run "$REPO" "task"
  check "unexpected JSON shape ($name): exit $want, no traceback" \
    "$(code_is "$want" && ! has "$ERR" 'Traceback' && { [ -z "$frag" ] || has "$OUT" "$frag"; }; echo $?)"
done

# --- summary ---------------------------------------------------------------
echo
echo "wrapper: $PASS passed, $FAIL failed"
for name in ${FAILED[@]+"${FAILED[@]}"}; do echo "  - $name"; done
[ "$FAIL" -eq 0 ]

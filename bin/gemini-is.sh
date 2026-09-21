#!/usr/bin/env bash
# Gemini'ye (Antigravity CLI) tek iş devreder ve maliyetini ölçer.
#
# NEDEN SARMALAYICI: doğru çağrı üç şeyi birden gerektiriyor — repo klasörüne
# geçmek, `--output-format json` vermek, yazma işinde `--mode accept-edits`
# eklemek. Bunları her seferinde modele hatırlatmak çalışmadı (ölçüldü: bayrak
# atlandı, token raporu uyduruldu). Burada kalıp sabit.
#
# Kullanım:
#   gemini-is.sh <repo-yolu> "<görev>"          # salt okuma
#   gemini-is.sh --yaz <repo-yolu> "<görev>"    # dosya değiştirebilir
#
# Çıktı: önce TOKEN satırı, sonra Gemini'nin cevabı. Ham JSON /tmp altında.
#
# TOKEN TASARRUFU: Gemini'nin cevabı Claude'un bağlamına giriyor ve sonraki her
# turda yeniden gönderiliyor; uzun cevap kârı siler. Bu yüzden cevap
# GEMINI_MAX_SATIR satırında kesilir (varsayılan 40); tamamı CEVAP dosyasında
# durur, gerekirse oradan parça okunur.
set -euo pipefail

AGY="${AGY_YOLU:-$HOME/.local/bin/agy}"
MOD=()
if [ "${1:-}" = "--yaz" ]; then
  MOD=(--mode accept-edits)
  shift
fi

REPO="${1:?kullanim: gemini-is.sh [--yaz] <repo-yolu> \"<gorev>\"}"
GOREV="${2:?gorev metni gerekli}"

[ -d "$REPO" ] || { echo "HATA: klasor yok: $REPO" >&2; exit 2; }
[ -x "$AGY" ] || { echo "HATA: agy bulunamadi: $AGY" >&2; exit 2; }

CIKTI="/tmp/gemini-is-$(date +%s)-$$.json"
HATA="${CIKTI%.json}.err"

cd "$REPO"
"$AGY" -p "$GOREV" ${MOD[@]+"${MOD[@]}"} --output-format json >"$CIKTI" 2>"$HATA" || true

if [ ! -s "$CIKTI" ]; then
  echo "HATA: agy cikti uretmedi. stderr son satirlari:" >&2
  tail -3 "$HATA" >&2
  exit 1
fi

CEVAP="${CIKTI%.json}.md"

MAX_SATIR="${GEMINI_MAX_SATIR:-40}" python3 - "$CIKTI" "$CEVAP" <<'PY'
import json, os, sys
d = json.load(open(sys.argv[1]))
u = d.get("usage", {})
print("TOKEN %s | SURE %ss | TUR %s | DURUM %s" % (
    u.get("total_tokens", "?"), round(d.get("duration_seconds", 0)),
    d.get("num_turns", "?"), d.get("status", "?")))
red = d.get("denied_actions")
if red:
    print("REDDEDILEN: %s" % ", ".join(sorted({r.get("action", "?") for r in red})))

cevap = (d.get("response") or "").strip()
open(sys.argv[2], "w").write(cevap + "\n")

print("---")
if not cevap:
    print("(bos cevap)")
else:
    satirlar = cevap.splitlines()
    sinir = int(os.environ["MAX_SATIR"])
    print("\n".join(satirlar[:sinir]))
    if len(satirlar) > sinir:
        print("... [%d satir daha kesildi; tamami CEVAP dosyasinda]"
              % (len(satirlar) - sinir))
PY
echo "---"
echo "CEVAP: $CEVAP"
echo "HAM: $CIKTI"

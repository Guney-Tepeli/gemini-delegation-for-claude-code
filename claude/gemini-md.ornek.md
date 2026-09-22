<!-- Bu dosya her deponun KÖKÜNE `GEMINI.md` adıyla kopyalanır. Kısa tut:
     her `agy` çağrısında Gemini'nin kotasından yer. 15-25 satır hedefle. -->

## Araç kuralı — önce bunu oku

`grep`, `rg`, `cat`, `head`, `tail`, `sed`, `awk`, `cut`, `sort`, `uniq`, `diff`
KULLANMA — izin listesinde yok, çağırırsan komut reddedilir ve iş yarıda kalır.

Dosya içeriği: `read_file`. Kod araması: `git grep`.

İzinli komutlar: `ls`, `wc`, `find`, `pwd`, `echo`, `true`, `basename`,
`dirname`, `realpath`, `stat`, `tree`, `node --check` ve yalnız okuma yapan git
alt komutları: `git grep`, `git ls-files`, `git log --oneline`,
`git diff --stat`, `git status --short` (`--no-pager` öneki serbest).

`npm run` ve `npx` İZİNLİ DEĞİL — depo kontrolündeki kodu çalıştırıyorlar.
`git show`, `git push`, `git config`, `git checkout` de izinli değil.

git argümanları da sınırlı: izinli bayraklar `-e -i -l -n -w -E -F`, `--count`,
`--name-only`, `--files-with-matches`, `--untracked`, `--cached`,
`--max-count=N`, `--no-color`, `-N`. Desenleri ve yolları TIRNAKSIZ yaz.
`-c` yerine `--count` kullan.

Bir komut satırındaki HER ikili izinli olmalı. Dosyaları TAM YOLLA yaz — kabuk
komutları repo klasöründe değil `agy`'nin scratch klasöründe çalışıyor.

## Ne olduğu

Dil, çatı, derleme. 4-6 satır dosya haritası.

## Sert kurallar

Dokunulmayacak dosyalar, adlandırma, değişmezler. `.env*`, `.git/`,
`db/migrations/`, `compose.yaml`, `Caddyfile` sana kapalı.

## Doğrulama

Derleme, tip denetimi, linter, test komutlarını ANA SOHBET çalıştırır. Sen
yalnız `node --check` ile sözdizimi bakabilirsin.

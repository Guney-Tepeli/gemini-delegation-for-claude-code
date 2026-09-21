# Claude tarafı dosyalar

Depoda yalnız `.ornek.md` sürümleri var. Kendi kopyanı oluştur, yollarını
düzelt, sonra ev dizinine **symlink** et — iki kopya tutma, ayrışır.

```bash
cp command-gemini.ornek.md command-gemini.md
cp agent-gemini.ornek.md   agent-gemini.md
# içindeki /MUTLAK/YOL/depolar ve ~/projeler yollarını kendi yollarınla değiştir

ln -s "$PWD/command-gemini.md" ~/.claude/commands/gemini.md
ln -s "$PWD/agent-gemini.md"   ~/.claude/agents/gemini.md
```

Gerçek dosyalar `.gitignore`'da: kişisel mutlak yol ve proje adı taşıyorlar.

- `command-gemini.ornek.md` — `/gemini` slash komutu. **Ana yol budur.**
- `agent-gemini.ornek.md` — alt ajan tanımı. **İsteğe bağlı**; yalnız ham
  çıktının 50 bin token'ı aşacağı devasa taramada kullanılır. Ölçüldü: alt ajan
  katmanı çağrı başına 20-45 bin ana-sohbet token'ı yiyor, normal işte bu kârın
  tamamından büyük.

Üçüncü bir dosya daha gerekiyor ve depoda değil: ana sohbetin çalışma kuralı.
`~/.claude/CLAUDE.md` dosyasına yazılır, metin ana README'nin **9c** bölümünde.
Bu adım atlanırsa kurulum çalışır ama kullanılmaz — kimse hangi işin Gemini'lik
olduğunu hatırlamaz.

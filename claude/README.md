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
- `gemini-md.ornek.md` — her deponun köküne `GEMINI.md` olarak kopyalanır. Araç
  kuralı ilk madde; izinli komut ve git bayrak listesi betiğin güncel kuralıyla
  birebir aynı.
- `claude-md-kurali.ornek.md` — ana sohbetin çalışma kuralı, `~/.claude/CLAUDE.md`
  dosyasına eklenir.
- `agent-gemini.ornek.md` — alt ajan tanımı. **İsteğe bağlı**; yalnız ham
  çıktının 50 bin token'ı aşacağı devasa taramada kullanılır. Ölçüldü: alt ajan
  katmanı çağrı başına 20-45 bin ana-sohbet token'ı yiyor, normal işte bu kârın
  tamamından büyük.

Ana sohbetin çalışma kuralı artık depoda: `claude-md-kurali.ornek.md`. İçeriği
`~/.claude/CLAUDE.md` dosyasına ekle. Bu adım atlanırsa kurulum çalışır ama
kullanılmaz — kimse hangi işin Gemini'lik olduğunu hatırlamaz.

`GEMINI.md` her depoya ayrı konur ve izin listesiyle senkron kalmak zorundadır:
betikteki ya da `agy/settings.json`'daki izinler değiştiğinde şablonu ve
depolardaki kopyaları birlikte güncelle. Aksi hâlde Gemini izinsiz komut çağırır,
`DENIED: command` ile boş döner ve çağrı boşa gider.

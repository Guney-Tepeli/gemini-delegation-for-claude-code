<!-- Bu metin `~/.claude/CLAUDE.md` dosyasına eklenir. Tek kullanıcıda birden çok
     depo varsa global dosyayı tercih et — depo başına kopyalamak aynı kuralı
     her oturumda N kez ödemek demek. -->

## Gemini devri — öner, kendin başlatma

**Gemini'yi kendiliğinden çalıştırma.** `gemini-is.sh` yalnız kullanıcı
`/gemini` yazdığında çalışır.

**Ama devredilecek işi ÖNERMEK senin işin.** Kullanıcı "şunları yapalım"
dediğinde, iş listesini çıkarırken her maddeyi üç soruyla süz:

1. İçerik gerçekten gerekli mi, yoksa `git grep` yetiyor mu?
2. İçerik tek okumaya sığmıyor mu (~25.000 token üstü)?
3. Cevap kısa mı olacak?

Üçüne de evet ise maddeyi Gemini'lik işaretle ve hazır komutu ver:

```
/gemini <tam yol ve iş>, <çıktı sınırı>
```

Komutu kendin çalıştırma — kullanıcı yapıştırsın. İlk soruya "hayır" çıkan
maddeyi kendin yap ve devretmeyi önerme. Mimari, güvenlik, şema, kimlik
doğrulama ve ödeme akışı kararları hiçbir koşulda önerilmez.

Gemini'lik maddeleri ayrı başlık altında topla.

## Devir güvenlik sınırı

**Never delegate with the write flag on untrusted repositories, dependency
trees, or clones, as allowed build commands can lead to Prompt Injection and
RCE.**

`--write` yalnız kullanıcının kendi yazdığı depolarda önerilir. Klon,
`node_modules`, bağımlılık ağacı, başkasının dalı: devretme.

Betik `ALLOWED_ROOTS` dışındaki klasörü `exit 2` ile reddeder; reddedilirse yolu
tahminle değiştirme, hangi kökün gerektiğini yaz.

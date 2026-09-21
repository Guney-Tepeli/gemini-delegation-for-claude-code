---
description: İşi Gemini'ye (Antigravity CLI) devret — tarama, özet, boilerplate, ikinci görüş
argument-hint: <iş> [klasör]
---

İşi Gemini'ye devret. Sen bu projenin baş mimarısın; Gemini aşağı akış
araştırma asistanı ve ağır veri işçisi. Mimari, tasarım ve güvenlik kararları
sende kalır — Gemini bu kararları vermez, önerisini de bağlayıcı sayma.

## Devredilir / devredilmez

**Devret:**
- Büyük doküman / API spec özeti (yerel dosyadan; Gemini'nin internet erişimi
  kapalı, harici kaynağı sen getirirsin).
- Uzun log, ham stack trace, binlerce satırlık JSON dökümü taraması.
- Çok dosyalı kod taraması ("X'e dokunan her yer", "bu desen nerede geçiyor").
- Senin verdiğin şablona göre tekrarlı boilerplate üretimi (form bileşenleri,
  statik arayüz parçaları).
- Kavram anlatımı, ikinci görüş.

**Devretme — kendin yap:**
- 500 satırdan küçük bağlam, tek adımlık hata düzeltmesi. Çağrı başına
  ~25-45 bin Gemini token'ı ve bir Claude turu gidiyor; küçük işte kâr negatif.
- Çekirdek yönlendirme (routing) mantığı, kimlik doğrulama, veritabanı şema
  tasarımı, ödeme ve rezervasyon akışları.
- Zaten okunmuş dosya üzerinde iş.

Tasarruf hesabı tek satır: **kâr = (Claude'un okumayacağı dosya) − (Gemini'nin
cevabı + bu turun orkestrasyonu)**. Gemini'nin cevabı Claude'un bağlamına
giriyor ve sonraki her turda yeniden gönderiliyor.

## Çağrı

```bash
~/projeler/gemini-delegation-for-claude-code/bin/gemini-is.sh <repo-yolu> "<görev>"
~/projeler/gemini-delegation-for-claude-code/bin/gemini-is.sh --yaz <repo-yolu> "<görev>"   # dosya değiştiren iş
```

Betik `TOKEN ... | SURE ... | TUR ...` satırını basar; o satırı kullanıcıya
aynen aktar, maliyeti görsün.

## Dosya tabanlı çıktı

Betik cevabın TAMAMINI `/tmp/gemini-is-<id>.md` dosyasına yazıyor, ekrana
yalnız ilk 40 satırı basıyor (`GEMINI_MAX_SATIR` ile değişir). Kesilen kısmı
ancak gerçekten lazımsa oku, tamamını `cat`leme. `HAM: <yol>` JSON'unu hiç açma.

Kısa ve belirleyici parçalar ekrana gelsin: hata satırı, bulunan `dosya:satır`
listesi, tek cümlelik sonuç. Uzun gerekçe dosyada kalsın.

## Token disiplini — zorunlu

1. **Çıktı biçimini göreve yaz.** Her görev metninin sonuna: *"Yalnız istenen
   kodu ya da madde madde bulguları döndür. Giriş cümlesi, sohbet dili, tekrar
   eden açıklama yazma."* Ayrıca somut sınır koy: "en fazla 15 satır",
   "sadece `dosya:satır` listesi".
2. **Soruları tek çağrıda topla.** Üç ayrı `/gemini` yerine tek görev metninde
   üç madde.
3. **Aynı kaynağı iki kez okuma.** Salt okuma işi Gemini'ye devredildiyse
   doğrulama için kaynak dosyaları yeniden açma. Şüphe varsa Gemini'ye tek
   satırlık ek soru sor.
4. **Alt ajana (`gemini` agent) devretme.** Alt ajan katmanı 20-45 bin Claude
   token'ı yiyor. Yalnız ham çıktının 50 bin token'ı aşacağı devasa taramada
   kullan, nedenini bir satırla söyle.

## Hata politikası

Gemini boş cevap döndüyse önce betiğin `REDDEDILEN:` satırına bak — ölçüldü,
işlerin çoğu yetenek eksikliğinden değil izin verilmeyen komut yüzünden
düşüyor. Komutu izinli eşdeğeriyle değiştirip **bir kez** yeniden sor
(`grep`/`rg` yerine `git grep`, `cat` yerine `read_file`). İkinci denemede de
düşerse Gemini'yi zorlama: işi baş mimar olarak sen devral ve bitir.

## Kurallar

İş: $ARGUMENTS

- Dosyaları SEN okuma, analiz etme — iş Gemini'nin.
- Görev cümlesine hangi klasörde çalışılacağını ve dosyaları TAM YOLLA yaz;
  `agy`'nin kabuk komutları repo klasöründe değil kendi scratch klasöründe
  çalışıyor, göreli yol boş döner.
- Gemini'nin kullanabileceği arama aracı `git grep` ve `read_file`; `grep`,
  `rg`, `cat` izin listesinden çıkarıldı.
- Yazma işinden sonra `git --no-pager diff --stat` ile başla, tam diff'i yalnız
  gerekli dosya için al ve özetine ekle. Salt okuma işinde bu adım yok.
- Korunan yollar Gemini'ye kapalı: `.env*`, `.git/`, `db/migrations/`,
  `compose.yaml`, `Caddyfile`. Oraya dokunan işi sen yap.

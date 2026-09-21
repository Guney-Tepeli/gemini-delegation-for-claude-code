# Gemini görev kataloğu — devretmeye değen işler

Bu dosya `CLAUDE.md`'ye doğrudan kopyalanabilir. Ana sohbetin işi: aşağıdaki
kalıplardan birine uyan bir iş gördüğünde onu **Gemini'lik olarak işaretlemek**
ve kullanıcıya hazır `/gemini` komutunu vermek. Çalıştırma kararı kullanıcıda.

## Neden Gemini — üç gerçek avantaj

1. **Ayrı bağlam bütçesi.** Gemini'nin okuduğu ham içerik ana sohbetin bağlam
   penceresine hiç girmez. Ana sohbete yalnızca bitmiş cevap döner. Bu, tek
   ölçümde 217 bin token'lık bir taramanın ana sohbete ~400 token olarak
   yansıması demekti.
2. **Geniş tek seferlik pencere.** Ana sohbetin dosya okuma sınırı çağrı başına
   ~25 bin token; Gemini tek turda bunun katlarını yutabiliyor. Yani "dosyanın
   tamamı gerekli" sınıfındaki işler ana sohbette parçalanırken Gemini'de tek
   turda biter.
3. **Kalıcı maliyet farkı.** Ana sohbete giren her şey sonraki HER turda
   yeniden gönderilir. Bir kerelik 40 bin token'lık okuma, 20 turluk bir
   oturumda 40 bin değil çok daha fazlasına mal olur. Gemini'ye giden ham
   içeriğin böyle bir kuyruğu yoktur.

Not: "model yorulmaz" gibi bir avantaj yoktur; avantaj yukarıdaki üç maddedir
ve hepsi ölçülebilir.

## A. Devralınan / eski kod (legacy)

1. **Kod arkeolojisi.** Belgesiz bir modülün davranış haritasını çıkarmak:
   giriş noktaları, yan etkiler, dış bağımlılıklar.
   *Gerekçe:* soru "nerede" değil "ne yapıyor" olduğu için grep yetmez; dosyanın
   tamamı gerekir ve tek okumaya sığmaz.
2. **Ölü kod envanteri.** Hiçbir yerden çağrılmayan export, erişilemez dal,
   kullanılmayan bağımlılık.
   *Gerekçe:* çapraz tarama — N dosyanın içeriğini aynı anda tutmayı gerektirir.
   Ana sohbette N ayrı okuma turu demek.
3. **Belgesiz API'nin sözleşmesini çıkarma.** Uç listesi, gövde alanları,
   dönüş biçimleri, kimlik katmanı.
   *Gerekçe:* çıktı kısa (bir tablo), girdi devasa. Kâr formülünün ideal hâli.
4. **Göç öncesi envanter.** Eski çatıdan yenisine geçmeden önce "hangi
   özellikler kullanılıyor" taraması.
   *Gerekçe:* kapsam hatası pahalıya patlar; eksiksiz tarama ancak bütünü
   görebilen tarafta mümkün.

## B. Yeniden yapılandırma (refactoring)

5. **Tekrar eden mantık tespiti.** Farklı dosyalarda aynı işi yapan kod.
   *Gerekçe:* benzerlik yakalamak metnin tamamını yan yana tutmayı gerektirir;
   grep birebir eşleşme bulur, benzerlik bulmaz.
6. **Tek doğruluk kaynağı denetimi.** Aynı kuralın iki yerde ayrı ayrı
   uygulanıp uygulanmadığı.
   *Gerekçe:* en pahalı hata sınıfı budur ve ancak bütünü gören bir tarama
   yakalar.
7. **Test kapsamı boşluk haritası.** Hangi modülün testi yok, hangi testler
   yalnızca mutlu yolu sınıyor.
   *Gerekçe:* kaynak ağacı ile test ağacının karşılaştırılması — iki tarafın da
   aynı anda okunmasını ister.
8. **Büyük dosyayı bölme planı.** Modül sınırı önerisi, bağımlılık yönü.
   *Gerekçe:* dosyanın tamamı gerekir; bölme kararı parça okumayla verilemez.

## C. DevOps ve operasyon

9. **CI / derleme logu analizi.** Binlerce satırda gerçek arıza satırını ve
   tekrar eden uyarıları bulmak.
   *Gerekçe:* sinyal/gürültü oranı çok düşük; ham logu ana sohbete almak bütçeyi
   kalıcı olarak bozar.
10. **Altyapı manifest denetimi.** Terraform, Kubernetes, Helm, Ansible — onlarca
    YAML arasında tutarsızlık, açık port, eksik kaynak sınırı.
    *Gerekçe:* dosya sayısı çok, her biri küçük; toplam büyük. Çapraz tutarlılık
    sorusu tek bakış ister.
11. **Bağımlılık kilidi analizi.** Yinelenen sürümler, geçişli bağımlılıklar,
    bilinen açıklı paketler.
    *Gerekçe:* kilit dosyaları tek başına 60 bin token üstü; içerik gerekli.
12. **Olay sonrası korelasyon.** Birden çok kaynaktan (uygulama logu, erişim
    logu, metrik dökümü) aynı zaman aralığının birleştirilmesi.
    *Gerekçe:* korelasyon tüm kaynakların aynı anda görülmesini gerektirir.
13. **Konteyner ve ağ yüzeyi denetimi.** Yayınlanan portlar, bağlanan klasörler,
    ortam değişkeni sızıntısı.
    *Gerekçe:* tarama geniş, çıktı kısa liste.

## D. Ham veri ve veri madenciliği

14. **Büyük JSON/CSV şema çıkarımı.** Alan adları, tipler, opsiyonellik,
    aykırı kayıtlar.
    *Gerekçe:* veri dökümünün tamamı gerekli, özet birkaç satır.
15. **API yanıt dökümlerinden sözleşme türetme.** Örnek yanıtlardan tip tanımı
    ya da şema üretmek.
    *Gerekçe:* örnek sayısı arttıkça doğruluk artar; hepsini aynı anda görmek
    şart.
16. **Veritabanı göç geçmişi taraması.** "Hangi göç şu nesneye dokundu",
    "hangi kısıt ne zaman geldi".
    *Gerekçe:* onlarca SQL dosyasının içeriği; grep dosya adını bulur, değişimin
    anlamını bulmaz.
17. **Analitik export özeti.** Ham olay kayıtlarından eğilim çıkarımı.
    *Gerekçe:* satır sayısı yüksek, sonuç birkaç madde.

## E. Doküman ve bilgi işi

18. **Uzun spec / RFC / standart özeti.** Yerel dosyadan; Gemini'nin internet
    erişimi kapalıdır, kaynağı ana sohbet getirir.
    *Gerekçe:* belgenin tamamı gerekli, çıkarım kısa.
19. **Değişiklik günlüğünden sürüm notu.** Ham commit/PR listesinden kullanıcıya
    dönük metin.
    *Gerekçe:* girdi uzun ve tekrarlı, çıktı kısa ve biçimli.
20. **Ajan yönerge dosyasını bölme.** Büyüyen bir `CLAUDE.md` ya da benzerinde
    "aktif kural / tarihçe" ayrımı.
    *Gerekçe:* dosyanın tamamı gerekir ve bu dosya her oturumda yüklendiği için
    bölme işinin kendisi doğrudan bütçe kazandırır.
21. **Çoklu doküman tutarsızlık taraması.** Aynı gerçeğin iki belgede farklı
    yazılması.
    *Gerekçe:* karşılaştırma bütünü görmeyi ister.

## F. Üretim (tekrarlı kod ve veri)

22. **Şablona göre boilerplate.** Form bileşenleri, CRUD iskeletleri, i18n
    anahtar dosyaları, statik arayüz parçaları.
    *Gerekçe:* şablonu ana sohbet belirler, çoğaltma mekaniktir; mekanik işi
    pahalı tarafta yapmak israf.
23. **Test verisi ve sahte kayıt üretimi.** Sınır durumlar dahil gerçekçi
    örnekler.
    *Gerekçe:* hacimli çıktı; doğrudan dosyaya yazdırılır.
24. **Çeviri dosyası doldurma.** Eksik anahtarların tamamlanması.
    *Gerekçe:* tekrarlı ve hacimli; karar içermez.

## G. Bağımsız bakış

25. **İkinci görüş.** Bir tasarım kararının açık noktaları, gözden kaçan durum.
    *Gerekçe:* ana sohbetin bağlamını taşımaması burada özellik: aynı varsayım
    zincirine kapılmaz. Çıktı öneridir, karar değildir.

## Devredilmeyecekler — istisnasız

- **Kararlar:** mimari, güvenlik modeli, veritabanı şema tasarımı, kimlik
  doğrulama akışı, ödeme ve para hareketi, yetkilendirme sınırları. Bunlar
  yetenek meselesi değil sorumluluk meselesidir.
- **`git grep` ile biten sorular.** "Nerede tanımlı", "kim çağırıyor".
  Devretmenin maliyeti cevabın maliyetinden büyük.
- **Küçük bağlam.** Tek küçük dosya, 500 satır altı iş, tek adımlık düzeltme.
- **Zaten okunmuş içerik.** İkinci kez ödemenin karşılığı yok.
- **İnternet gerektiren araştırma.** Web erişimi bilinçli kapalı.
- **Uzak makine komutu.** `ssh` izin listesinde değil; log önce yerel dosyaya
  dökülür, sonra devredilir.

## Karar testi — üç soru

Sırayla sor, ilk **hayır**'da devretme:

1. İçerik gerçekten gerekli mi, yoksa `git grep` çıktısı yetiyor mu?
2. İçerik tek okumaya sığmıyor mu (tek dosya ~25 bin token üstü ya da toplam
   çok büyük)?
3. Cevap kısa mı olacak (liste, tablo, birkaç madde)?

Üçüne de evet ise devret. Cevabın da uzun olacağı işte kâr erir — cevap ana
sohbetin bağlamına girer ve sonraki her turda yeniden gönderilir.

## Görev metni kalıbı

Her devirde üçü birden yazılır: tam yol, somut soru, çıktı sınırı.

```
/gemini <tam/yol/dosya> içinde <somut soru> — sadece <biçim>, en fazla <N> satır
```

Görev metninin sonuna her zaman eklenir: *"Yalnız istenen kodu ya da madde madde
bulguları döndür. Giriş cümlesi, sohbet dili, tekrar eden açıklama yazma."*

Gemini'nin kullanabildiği araçlar: `read_file` / `view_file` (dosya içeriği) ve
`git grep` (arama). `grep`, `rg`, `cat`, `head`, `sed`, `awk` izin listesinde
değildir; çağrılırsa iş yarıda kalır.

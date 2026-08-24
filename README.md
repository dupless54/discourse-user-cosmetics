# Discourse User Cosmetics

Discourse forumunuza Discord tarzı kullanıcı kozmetikleri ekleyin! Bu eklenti sayesinde üyelerinize profillerini özelleştirebilecekleri avatar çerçeveleri, isim plakaları, kullanıcı kartı dekorasyonları ve **profil efektleri** sunabilirsiniz.

## Eklenti Ne İşe Yarıyor?

Kullanıcılar profil ayarlarındaki **Tercihler** sekmesinden kendi kozmetiklerini seçip anında kullanmaya başlayabilirler. Eklenti dört farklı kozmetik türü sunar:

| Kategori | Nerede Görünür? | Desteklenen Formatlar |
| --- | --- | --- |
| **Avatar Çerçevesi** | Gönderiler, konu listesi, alıntılar, bildirimler ve üst menü dahil avatarın olduğu her yer. | Ortası şeffaf PNG, GIF veya WEBP |
| **İsim Plakası** | Kullanıcı kartı ve profil sayfasında, kullanıcı adının hemen arkasında. | Görsel veya iki renkli CSS gradyanı |
| **Kart Dekorasyonu** | Kullanıcı kartının arka planında bir şerit/afiş olarak. | Görsel veya iki renkli CSS gradyanı |
| **Profil Efekti** | Kullanıcı kartının **çevresinde**, kartın sınırlarını taşarak (Discord'un profil efektleri gibi). | En fazla 4 şeffaf PNG/GIF/WEBP katman |

**Yönetici Özellikleri:**
Yöneticiler **Admin → Plugins → User Cosmetics** paneli üzerinden sınırsız sayıda yeni kozmetik ekleyebilir. Eklediğiniz her bir öğe için şu ayarları yapabilirsiniz:

* Belirli gruplara kilitleme (güven seviyeleri, rozet grupları veya moderatör/admin ekipleri).
* Herkese açık ve ücretsiz olarak ayarlama.
* Yalnızca belirli kullanıcılara özel olarak hediye etme.
* Herkese otomatik olarak tanımlama (varsayılan yapma).
* "Efsanevi", "Nadir" gibi tamamen görsel amaçlı nadirlik etiketleri ve renkleri ekleme.

Eklentiyi kurduğunuzda boş bir sayfayla karşılaşmamanız için sistem 5 avatar çerçevesi, 5 isim plakası ve 3 kart dekorasyonunu hazır örnek olarak (`public/default-cosmetics/`) otomatik yükler. Profil efektleri özel karakter/illüstrasyon sanatı gerektirdiğinden hazır örnek gelmez -- aşağıdaki "Profil Efektleri" bölümünde kendi efektinizi nasıl ekleyeceğiniz anlatılıyor.

---

## Kurulum

Bu bir Discourse eklentisidir (tema bileşeni değil), bu nedenle sunucunuza doğrudan erişiminiz olmalıdır.

1. Sunucunuzda `containers/app.yml` dosyasını açın.
2. `hooks` -> `after_code` bölümünün altına eklenti adresini ekleyin:

```yaml
hooks:
  after_code:
    - exec:
        cd: $home/plugins
        cmd:
          - git clone https://github.com/dupless54/discourse-user-cosmetics.git

```

3. Terminalden Discourse'u yeniden derleyin:

```bash
cd /var/discourse
./launcher rebuild app

```

4. Kurulum bittikten sonra forumunuzda **Admin → Ayarlar → Eklentiler** menüsünden `discourse_user_cosmetics_enabled` ayarının açık olduğunu kontrol edin.

---

## Kozmetikleri Yönetmek

Admin panelinden yeni bir öğe eklemek oldukça basittir. İlgili sekmeye gidip **Yeni Öğe** butonuna tıklamanız yeterlidir. Öğeye bir isim ve açıklama girdikten sonra görselini ayarlayabilirsiniz.

Görsel eklemek için bilgisayarınızdan dosya yükleyebilir, harici bir URL yapıştırabilir veya (özellikle isim plakaları için çok pratik olan) başlangıç ve bitiş renklerini seçerek saf CSS gradyanları oluşturabilirsiniz.

Görsellerinizi hazırlarken en iyi görünüm için şu standartları referans alabilirsiniz:

| Tür | Önerilen Boyut / Oran | Tasarım İpuçları |
| --- | --- | --- |
| **Avatar Çerçevesi** | Kare (En az 400×400, tercihen 512×512) | Avatarın görünmesi için ortası kesinlikle şeffaf PNG/GIF olmalıdır. Halka kalınlığı toplam genişliğin %12-15'i civarında olduğunda kusursuz durur. |
| **İsim Plakası** | Geniş (Örn: 400×120) | Görsel yükleyebilirsiniz ancak iki renkli CSS gradyanı kullanmak çoğu zaman çok daha net ve şık bir sonuç verir. |
| **Kart Dekorasyonu** | Geniş (Örn: 900×320) | Kartın içinde bir afiş gibi kırpılarak gösterilir. Üzerindeki beyaz yazıların okunabilmesi için koyu tonlar tercih edilmelidir. |

Animasyonlu (GIF/WEBP) dosyalar tarayıcı tarafından otomatik olarak döngüye sokulur ve ekstra bir ayar gerektirmez.

---

## Profil Efektleri (Discord Tarzı Katmanlı Çerçeve)

Bu özellik, Discord'un "Profil Efektleri" (Profile Effects) ürününün JSON şemasından esinlenerek tasarlandı ve o şemayla birebir eşleşen bir veri modeli kullanır:

| Discord JSON alanı | Bu eklentideki karşılığı |
| --- | --- |
| `items[].layers[].anchor` (`top` / `bottom`) | Katmanın `anchor` alanı |
| `items[].layers[].order` (`front` / `back`) | Katmanın `stack_order` alanı |
| `items[].inner_width` | `effect_inner_width` (varsayılan: 1200, Discord ile aynı referans genişlik) |
| `items[].overflow_top` / `overflow_bottom` / `overflow_horizontal` | Aynı adlarla, admin formunda piksel cinsinden girilen alanlar |

Bir profil efekti, her biri isteğe bağlı olmak üzere **en fazla 4 katmandan** oluşur: *Üst-Ön*, *Üst-Arka*, *Alt-Ön*, *Alt-Arka*. "Ön" (front) katmanlar kartın **üzerinde**, "arka" (back) katmanlar kartın **arkasında** görünür -- Discord'daki tavşanların kartın üst kenarından sarkması tam olarak bu mekanizmayla mümkün olur.

### Yeni bir profil efekti eklemek

1. **Admin → Plugins → User Cosmetics → Profil Efektleri** sekmesine gidin, **Yeni öğe**'ye tıklayın.
2. Dört katman kutusundan (Üst-Ön, Üst-Arka, Alt-Ön, Alt-Arka) ihtiyacınız olanlara şeffaf arka planlı **PNG, GIF veya WEBP** yükleyin. Hepsini doldurmak zorunda değilsiniz; örneğin sadece "Üst-Ön" dolu bir efekt de tamamen geçerlidir.
3. **Taşma (overflow)** değerlerini girin -- bu, efektin kartın kenarlarından piksel cinsinden ne kadar dışarı taşacağını belirler. Değerler 1200px genişliğindeki bir referans karta göredir ve gerçek kart boyutuna otomatik ölçeklenir (Discord'un `inner_width` mantığıyla aynı). Örnek JSON'daki değerler (üstten 304px, alttan 140px, yanlardan 56px) iyi bir başlangıç noktasıdır.
4. Kaydedin. Öğe, kilidini açan bir grup seçmediyseniz herkese açık olur; istediğiniz gruplara/kullanıcılara kısıtlamak için formun geri kalanı diğer kozmetik türleriyle birebir aynı şekilde çalışır.

### Nasıl render ediliyor?

Kart içine yerleştirilen küçük bir Ember bileşeni, açık olan kullanıcı kartını (`#user-card`) bulur, `document.body`'ye konumlandırılmış görünmez bir "portal" elemanı ekler ve katman görsellerini gerçek `<img>` etiketleri olarak bu portala yerleştirir. Görseller `document.body`'ye eklendiği için kartın (veya bir üst elemanının) olası bir `overflow: hidden` kuralından etkilenmezler; taşma değerleri her zaman doğru şekilde görünür. Kartın boyutu değişirse (`ResizeObserver` ile izlenir) konum otomatik yeniden hesaplanır, kart kapandığında portal elemanı temizlenir.

---

## Site Ayarları

Forum ayarlarında "user cosmetics" araması yaparak aşağıdaki seçenekleri kişiselleştirebilirsiniz:

* `discourse_user_cosmetics_enabled`: Eklentiyi tamamen açıp kapatır.
* `discourse_user_cosmetics_avatar_frames_enabled`: Sadece avatar çerçevelerini aktif/pasif yapar.
* `discourse_user_cosmetics_nameplates_enabled`: Sadece isim plakalarını aktif/pasif yapar.
* `discourse_user_cosmetics_card_decorations_enabled`: Sadece kart dekorasyonlarını aktif/pasif yapar.
* `discourse_user_cosmetics_profile_effects_enabled`: Sadece profil efektlerini aktif/pasif yapar.
* `discourse_user_cosmetics_frame_overhang_percent`: Çerçevenin avatar kenarından ne kadar dışarı taşacağını belirler (Varsayılan: %14).
* `discourse_user_cosmetics_max_image_kb`: Yüklenebilecek maksimum görsel boyutunu belirler (Varsayılan: 2048 KB).

---

## Olası Sorunlar ve Çözümleri

Discourse sürekli güncellenen dinamik bir platformdur. Bir şeyler ters giderse tarayıcı konsoluna (F12) ve şu detaylara göz atabilirsiniz:

* **Avatar çerçeveleri görünmüyorsa:** Tarayıcınızda doğrudan `/user-cosmetics/frames.css` adresini açın. Sayfa boşsa, site ayarlarından çerçevelerin açık olduğundan ve en az bir kullanıcının çerçeve seçtiğinden emin olun.
* **Plakalar veya dekorasyonlar görünmüyorsa:** Discourse'un yeni bir sürümünde genişletme (outlet) adları değişmiş olabilir. Eklentinin `assets/javascripts/discourse/api-initializers/user-cosmetics.js` dosyasındaki kanca isimlerini Discourse Geliştirici Araçları ile kontrol edip güncelleyebilirsiniz.
* **Metinler yerine ham kodlar (`discourse_user_cosmetics.xxx`) görünüyorsa:** Çeviri dosyaları yüklenememiş demektir. Sayfa çökmez ancak metinler ham haliyle kalır.

---

## Teknik Detaylar ve Geliştirici Notları

Eklentinin arka planında performansı ve güvenliği sağlamak için modern standartlar kullanılmıştır:

* **Veritabanı Yapısı:** Sistem 5 tablo üzerinde çalışır: `items` (öğeler), `item_groups` (grup izinleri), `user_items` (özel hediyeler), `user_selections` (aktif giyilenler) ve `effect_layers` (profil efektlerinin katmanları).
* **CSS Tabanlı Render (Çerçeveler İçin):** Çerçeveler sisteme tek tek Ember bileşenleriyle eklenmez. Bunun yerine sunucu tarafında her tıklanabilir avatardaki `data-user-card` özelliğini hedefleyen tek bir `frames.css` dosyası üretilir. Bu sayede Discourse HTML yapısını değiştirse bile çerçeveler bozulmadan çalışmaya devam eder.
* **Ember Outlets:** İsim plakaları ve dekorasyonlar doğrudan kullanıcı kartı şablonlarına `api.renderInOutlet` kullanılarak güvenli bir şekilde enjekte edilir.
* **Portal Tabanlı Render (Profil Efektleri İçin):** Kartın sınırlarını taşabilmesi gerektiği için profil efektleri, `document.body`'ye eklenen ve `getBoundingClientRect()` ile konumlandırılan ayrı bir katman olarak çizilir; bkz. `user-cosmetics-profile-effect.gjs`.
* **Önbellekleme (Cache):** Kullanıcıların aktif kozmetikleri veritabanını yormamak için `Discourse.cache` üzerinde tutulur. Yönetici bir değişiklik yaptığında global versiyon numarası artar ve cache anında temizlenir.
* **Yetkilendirme:** Sadece tam yetkili (admin) hesaplar paneli görebilir. Kullanıcılar, sunucu tarafındaki `usable_by?` kontrolünden geçmeyen hiçbir kozmetiği arayüzü manipüle ederek kullanamazlar.

---

## Bu Sürümde Neler Değişti?

* **450x880 kart dekorasyonları:** User-card, dekorasyonun özgün 450×880 oranını koruyarak ekrana sığacak biçimde ölçeklenir; animasyon artık kırpılmadan gerçek bir görsel katmanı olarak oynatılır.
* **Doğru katman sırası:** Kart dekorasyonu mesaj gönderme alanının üzerinde görünür; `pointer-events: none` sayesinde alttaki mesaj eylemi kullanılmaya devam eder.
* **Mobilde kalıcı kapatma eylemi:** My Cosmetics penceresinin altına, içerik ne kadar kaydırılırsa kaydırılsın erişilebilir kalan tam genişlikte bir **Kapat** düğmesi eklendi.
* **Yeni kozmetik seçici tasarımı:** Profil ayarlarındaki seçici, Crimson temasına uyumlu koyu/gradyan yüzeyler, daha okunaklı öğe kartları ve modern durum düğmeleriyle yenilendi.
* **Kaydırılabilir dört sekme:** Avatar Çerçeveleri, İsim Plakaları, Kart Dekorasyonları ve Profil Efektleri sekmeleri hem dokunarak/yatay kaydırmayla hem de sağ-sol ok düğmeleriyle gezilebilir.
* **User-card mesaj alanı:** Mesaj gönderilebilen kullanıcıların kartında `@kullanıcıadı kullanıcısına mesaj gönder` alanı görünür ve Discourse'un yerleşik özel mesaj oluşturucusunu açar.
* **Yeni:** Profil Efektleri (Discord JSON şemasına dayalı, 4 katmanlı, kart sınırlarını taşabilen efektler).
* Mevcut avatar çerçevesi / isim plakası / kart dekorasyonu / admin altyapısı dokunulmadan korundu; yeni özellik tamamen ek (additive) olarak eklendi.

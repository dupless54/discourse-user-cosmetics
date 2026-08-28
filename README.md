# Discourse User Cosmetics

Discourse forumunuza Discord tarzı kullanıcı kozmetikleri ekleyin! Bu eklenti sayesinde üyelerinize profillerini özelleştirebilecekleri avatar çerçeveleri, isim plakaları, kullanıcı kartı dekorasyonları ve **profil efektleri** sunabilirsiniz.

## Eklenti Ne İşe Yarıyor?

Kullanıcılar profil ayarlarındaki **Tercihler → Kozmetikler** sayfasından kendi kozmetiklerini seçebilir; seçim veya çıkarma işlemleri sayfayı yenilemeden mevcut oturuma uygulanır. Eklenti dört farklı kozmetik türü sunar:

| Kategori | Nerede Görünür? | Desteklenen Formatlar |
| --- | --- | --- |
| **Avatar Çerçevesi** | Gönderiler, konu listesi, alıntılar, bildirimler ve üst menü dahil avatarın olduğu her yer. | Ortası şeffaf PNG, GIF veya WEBP |
| **İsim Plakası** | Kullanıcı kartı ve profil sayfasında, kullanıcı adının hemen arkasında. | Görsel veya iki renkli CSS gradyanı |
| **Kart Dekorasyonu** | Kullanıcı kartının arka planında bir şerit/afiş olarak. | Görsel veya iki renkli CSS gradyanı |
| **Profil Efekti** | Kullanıcı kartının **çevresinde**, kartın sınırlarını taşarak (Discord'un profil efektleri gibi). | En fazla 10 isteğe bağlı şeffaf PNG/GIF/WEBP katman |

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

Bu özellik Discord'un "Profil Efektleri" (Profile Effects) yaklaşımından esinlenir, ancak eklenti modeli Discourse kullanıcı kartı için genişletilmiştir. Temel `front/back`, referans genişlik ve overflow mantığı korunurken `left`, `right` ve `full` anchor'ları da desteklenir:

| Profil efekti alanı | Bu eklentideki karşılığı |
| --- | --- |
| `layers[].anchor` | `top`, `bottom`, `left`, `right` veya `full` |
| `layers[].order` | Katmanın `stack_order` alanı: `front` veya `back` |
| Referans genişlik | `effect_inner_width` (varsayılan: 1200) |
| Üst/alt/yatay taşma | `effect_overflow_top`, `effect_overflow_bottom`, `effect_overflow_horizontal` |
| Yan katman başlangıç/bitiş kesintileri | `effect_side_offset_top`, `effect_side_offset_bottom` |

Bir profil efekti, her biri isteğe bağlı olmak üzere **en fazla 10 benzersiz katman slotundan** oluşabilir: *Tam*, *Üst*, *Alt*, *Sol* ve *Sağ* anchor'larının her biri için birer **Ön** (`front`) ve **Arka** (`back`) slotu vardır. "Ön" katmanlar kartın üzerinde, "arka" katmanlar kartın arkasında görünür. İhtiyacınız olmayan slotları boş bırakabilirsiniz.

### Yeni bir profil efekti eklemek

1. **Admin → Plugins → User Cosmetics → Profil Efektleri** sekmesine gidin, **Yeni öğe**'ye tıklayın.
2. On katman slotundan ihtiyacınız olanlara şeffaf arka planlı **PNG, GIF veya WEBP** yükleyin. Hepsini doldurmak zorunda değilsiniz; örneğin yalnızca "Üst-Ön" veya "Tam-Arka" dolu bir efekt de geçerlidir.
3. **Taşma (overflow)** değerlerini girin -- bu, efektin kartın kenarlarından piksel cinsinden ne kadar dışarı taşacağını belirler. Değerler 1200px genişliğindeki referans karta göre hesaplanır ve gerçek kart boyutuna otomatik ölçeklenir. Sol/sağ anchor kullanıyorsanız yan katmanların üst ve alt kesintilerini de ilgili offset alanlarıyla ayarlayabilirsiniz.
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

* **Native Discourse Tercihler entegrasyonu:** Kozmetik seçimi artık özel bir modal yerine kullanıcının **Tercihler → Kozmetikler** sayfasında, Discourse'un kendi navigasyon yapısı içinde açılır.
* **Tema ile doğal uyum:** Kozmetik sayfası Discourse'un renk ve tipografi değişkenlerini kullanır; açık/koyu mod ve özel tema renklerine ayrı bir yapay arayüz oluşturmadan uyum sağlar.
* **Mobil ve masaüstü uyumu:** Dört kozmetik kategorisi aynı inline sayfa içinde responsive sekmeler ve grid düzeniyle gösterilir; eski tam ekran/modal kapatma akışı kaldırılmıştır.
* **Anında seçim yenilemesi:** Kullan/Kaldır işlemlerinden sonra aktif kozmetik özeti `currentUser` üzerinde güncellenir; kullanıcı sonucu görmek için sayfayı yenilemek zorunda kalmaz.
* **Avatar çerçevesinde canlı güncelleme:** Avatar çerçevesi veya isim plakası değiştiğinde paylaşılan `frames.css` kaynağı yenilenir; üst menüdeki mevcut kullanıcı avatarı da aynı oturumda yeni çerçeveyi kullanır.
* **Ayarla uyumlu çerçeve taşması:** Üst menü avatar çerçevesi artık sabit bir değer yerine `discourse_user_cosmetics_frame_overhang_percent` site ayarını kullanır.
* **Legacy arayüz temizliği:** Native Preferences geçişinden sonra kullanılmayan preferences-entry bileşeni ve eski `.duc-picker-*` modal stilleri kaldırılmıştır.
* **Crimson Channels kart uyumu korunuyor:** Kart dekorasyonu gerçek user-card yüzeyine bağlanır; dekorasyon katmanı `pointer-events: none` ile kart kontrollerinin kullanılabilirliğini korur.
* **Profil Efektleri:** Genişletilmiş `top/bottom/left/right/full × front/back` modeliyle en fazla 10 benzersiz katman slotu ve kart sınırlarını aşan profil efektleri desteklenir.
* **Sunucu otoritesi korunuyor:** Sahiplik, grup erişimi ve kullanılabilirlik kararları backend'deki yetkilendirme/entitlement kontrollerinde kalır; frontend yalnız sunucunun izin verdiği durumu gösterir.

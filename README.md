# discourse-user-cosmetics

## 1. Neler yapar?

Kullanıcılar, **Tercihler** sayfalarında açılan bir seçim ekranından üç kategoriden istediklerini seçip kullanabilir:

| Kategori | Nerede görünür | Görsel biçim |
|---|---|---|
| **Avatar Çerçevesi** | Avatarın göründüğü *her yer*: gönderiler, konu listesi, kullanıcı kartı, alıntılar, bildirimler, üst menü | Ortası şeffaf PNG/GIF/WEBP halka |
| **İsim Plakası** | Kullanıcı kartı ve profil sayfası, kullanıcı adının yanında | Görsel *veya* iki renkli gradyan |
| **Kullanıcı Kartı Dekorasyonu** | Kullanıcı kartı içinde şerit/afiş | Görsel *veya* iki renkli gradyan |

Yöneticiler **Admin → Plugins → User Cosmetics** ekranından bu üç kategoriye sınırsız sayıda öğe ekleyebilir; her öğeyi:

- belirli **gruplara** kilitleyebilir (güven seviyeleri, rozet grupları, staff dahil — Discourse'ta hepsi birer "grup"tur),
- veya **herkese açık** bırakabilir,
- veya belirli **kullanıcılara tek tek** hediye edebilir,
- "**herkese otomatik ver**" diyerek varsayılan yapabilir,
- "nadirlik" etiketi/rengiyle süsleyebilir (Efsanevi, Nadir vb. — tamamen görsel, oyun mantığı yok).

Kutudan çıkar çıkmaz denenebilmesi için 5 avatar çerçevesi, 5 isim plakası ve 3 kart dekorasyonu **hazır örnek** olarak gelir (`public/default-cosmetics/`).

---

## 2. Mimari — nasıl çalışıyor?

### 2.1 Veritabanı

Dört tablo (`db/migrate/`):

- `discourse_user_cosmetics_items` — her kozmetik öğe (tür, ad, görsel/gradyan, nadirlik, sıra, etkin mi, herkese-açık mı).
- `discourse_user_cosmetics_item_groups` — bir öğeyi hangi grupların kilidini açtığı.
- `discourse_user_cosmetics_user_items` — bir öğenin belirli bir kullanıcıya elle hediye edilmesi.
- `discourse_user_cosmetics_user_selections` — bir kullanıcının o an **giydiği** (aktif) öğe, kategori başına.

`app/models/discourse_user_cosmetics/item.rb` içindeki `usable_by?(user)` metodu tek yetki kontrol noktasıdır: öğe herkese açıksa, kullanıcının grubu uyuyorsa, veya kullanıcıya elle verilmişse `true` döner.

### 2.2 Avatar çerçeveleri neden her yerde çıkıyor?

Discourse'ta avatarı tıklanabilir yapan her `<a>` etiketi, hangi kullanıcıya ait olduğunu **`data-user-card="kullaniciadi"`** özniteliğiyle taşır (kullanıcı kartını açan mekanizma buna bakar). Biz de tek tek her bileşeni (gönderi, konu listesi, alıntı...) uğraşıp değiştirmek yerine, sunucu tarafında **tek bir CSS dosyası** üretiyoruz:

```
GET /user-cosmetics/frames.css
```

Bu dosya, aktif çerçevesi olan her kullanıcı için şöyle bir kural içerir:

```css
[data-user-card="kullaniciadi"] { position: relative; display: inline-block; }
[data-user-card="kullaniciadi"]::after {
  content: "";
  position: absolute;
  inset: -14%;
  background-image: url("...çerçeve-görseli.png...");
  background-size: contain;
}
```

Bu dosya bir kere, sayfa ilk açıldığında `<link>` olarak yüklenir (bkz. `api-initializers/user-cosmetics.js`) ve tarayıcı tarafından cache'lenir; sürüm numarası değiştiğinde (bir kullanıcı çerçeve değiştirdiğinde) otomatik yenilenir. **Sonuç:** avatarın göründüğü her yerde, herhangi bir Ember bileşenine dokunmadan çerçeve görünür — Discourse'un arayüzü zamanla değişse bile bu mekanizma kırılmaya karşı oldukça dayanıklıdır.

### 2.3 İsim plakası ve kart dekorasyonu

Bunlar sadece **kullanıcı kartı** ve **profil sayfası** içinde göründüğü için, Discourse'un o şablonlardaki genişletme noktalarına (`user-card-post-names`, `user-card-metadata`, `user-profile-primary`) `api.renderInOutlet(...)` ile bileşen yerleştiriyoruz (`assets/javascripts/discourse/components/*.gjs`).

### 2.4 Önbellekleme

Her istekte veritabanına gitmemek için, bir kullanıcının "şu an ne giydiği" bilgisi `Discourse.cache` üzerinde saklanır (`lib/discourse_user_cosmetics/presenter.rb`). Bir yönetici bir öğeyi düzenlediğinde ya da bir kullanıcı seçim değiştirdiğinde, tek bir "versiyon" sayacı artırılır ve bütün önbellek anında geçersiz sayılır — tek tek kullanıcıları bulup temizlemeye gerek kalmaz.

### 2.5 Dosya haritası

```
plugin.rb                                   → giriş noktası, ayarlar, route'lar, serializer ekleri
config/settings.yml                          → site ayarları
config/locales/{client,server}.{en,tr}.yml   → arayüz metinleri
db/migrate/                                  → 4 tablo
app/models/discourse_user_cosmetics/         → Item, ItemGroup, UserItem, UserSelection
app/controllers/discourse_user_cosmetics/    → kullanıcı ve admin API'leri + CSS controller
lib/discourse_user_cosmetics/                → önbellek/özet mantığı, CSS üretici, örnek veri
assets/stylesheets/common/                   → tüm arayüz CSS'i
assets/javascripts/discourse/
  ├─ api-initializers/user-cosmetics.js      → CSS linkini enjekte eder, outlet'lere bağlanır
  ├─ lib/duc-i18n.js                         → çeviri yardımccısı
  ├─ components/*.gjs                        → plaket, kart afişi, seçim ekranı (picker)
  ├─ discourse-user-cosmetics-route-map.js   → admin sayfasının rotası
  └─ admin/                                  → admin ekranı (liste + form)
public/default-cosmetics/                    → hazır örnek görseller
```

---

## 3. Kurulum

Bu bir Discourse **plugin**'idir (tema bileşeni değil), bu yüzden sunucu erişiminiz olmalı.

1. Sunucunuzda `containers/app.yml` dosyasını açın ve `after_code` altına ekleyin:
   ```yaml
   hooks:
     after_code:
       - exec:
           cd: $home/plugins
           cmd:
             - git clone https://github.com/dupless54/discourse-user-cosmetics.git
   ```
2. Yeniden derleyin:
   ```bash
   cd /var/discourse
   ./launcher rebuild app
   ```
3. **Admin → Ayarlar → Eklentiler**'de `discourse_user_cosmetics_enabled` açık olduğunu doğrulayın (varsayılan olarak açık gelir).

Yerel/geliştirme kurulumunuz varsa (kaynak koddan çalışan Discourse), klasörü doğrudan Discourse'un `plugins/` klasörüne kopyalayıp sunucuyu yeniden başlatmanız yeterlidir.

---

## 4. Görsel ve özellik nasıl eklenir?

### 4.1 Admin panelinden yeni bir çerçeve/plaket/dekorasyon eklemek

1. **Admin → Plugins → User Cosmetics**'e gidin.
2. Üstteki sekmelerden türü seçin: *Avatar Çerçeveleri*, *İsim Plakaları* veya *Kart Dekorasyonları*.
3. **Yeni öğe**'ye tıklayın.
4. **Ad** girin, isterseniz kısa bir **açıklama** yazın (seçim ekranında ipucu olarak görünür).
5. Görsel için iki yol var:
   - **Görsel yükle** butonuyla bilgisayarınızdan bir dosya seçin (PNG/JPG/GIF/WEBP), *veya*
   - Zaten barındırdığınız bir görselin adresini "...veya bir görsel URL'si yapıştırın" kutusuna yapıştırın.
   - Görsel yerine (veya görselle birlikte) **başlangıç/bitiş rengi** seçerek düz bir gradyan da kullanabilirsiniz — özellikle isim plakaları için pratik bir yoldur, tasarım programına ihtiyaç duymazsınız.
6. İsterseniz bir **nadirlik etiketi** (ör. "Efsanevi") ve rengini girin.
7. **Kimler kullanabilir?** bölümünden bu öğeyi hangi grupların açacağını seçin. Hiçbir grup seçmezseniz öğe **herkese açık** olur. Güven seviyeleri (`trust_level_0`…`trust_level_4`), rozet grupları ve `staff` de birer gruptur, listede onları da göreceksiniz.
8. Mevcut bir öğeyi düzenlerken, formun altındaki **"Ayrıca elle verildiği kişiler"** kutusundan tek tek kullanıcı adı yazıp o kişiye özel hediye edebilirsiniz (grup şartı olmasa da).
9. **Kaydet**'e basın — öğe anında listeye ve kullanıcıların seçim ekranına düşer.

### 4.2 Görsel önerileri

| Tür | Önerilen boyut/oran | Notlar |
|---|---|---|
| Avatar çerçevesi | Kare, en az 400×400, tercihen 512×512 | Ortası **şeffaf** PNG olmalı (avatar oradan görünecek). Halka kalınlığı toplam genişliğin ~%12-15'i civarında iyi görünür. |
| İsim plakası | Geniş, ör. 400×120 | Görsel de kullanılabilir, ama çoğu zaman iki renkli gradyan daha sade ve hızlı bir çözümdür. |
| Kart dekorasyonu | Geniş, ör. 900×320 | Kartın içinde bir şerit/afiş olarak kırpılıp gösterilir; koyu tonlar üstündeki beyaz yazıyla daha iyi kontrast verir. |

Animasyonlu **GIF/WEBP** dosyaları da yükleyebilirsiniz; tarayıcı bunları `background-image` olarak otomatik oynatır, ek bir ayar gerekmez. Maksimum dosya boyutu `discourse_user_cosmetics_max_image_kb` ayarıyla sınırlıdır (varsayılan 2048 KB).

### 4.3 Hazır örnekleri değiştirmek / kendi "başlangıç paketinizi" yapmak

`public/default-cosmetics/` klasöründeki PNG'ler yalnızca ilk kurulumda, tablo boşsa otomatik eklenir (bkz. `lib/discourse_user_cosmetics/seeder.rb`). Bu dosyaları kendi görsellerinizle değiştirip yeniden `./launcher rebuild app` çalıştırırsanız (veritabanı zaten dolu olduğu için) mevcut kayıtlar etkilenmez; onları admin panelinden düzenlemeniz gerekir. Sıfırdan denemek isterseniz ilgili satırları veritabanından silip eklentiyi yeniden başlatmanız yeterlidir.

### 4.4 Yeni bir kozmetik *türü* eklemek (ör. "profil arka planı")

Kod tarafında üç yer birbirine paralel çalışır; dördüncü bir tür eklemek isterseniz:

1. `app/models/discourse_user_cosmetics/item.rb` → `KINDS` dizisine yeni türün adını ekleyin.
2. `db/migrate/...user_selections.rb` mantığına paralel yeni bir migration ile `user_selections` tablosuna yeni bir `..._item_id` kolonu ekleyin ve `UserSelection::FIELD_FOR_KIND` eşlemesine ekleyin.
3. `config/locales/client.*.yml` içine `discourse_user_cosmetics.kinds.<yeni_tur>` çevirisini ekleyin.
4. Yeni türü nerede göstermek istiyorsanız (yeni bir `.gjs` bileşeni + `api.renderInOutlet(...)` çağrısı) `api-initializers/user-cosmetics.js` içine ekleyin.

Admin ekranı ve kullanıcı seçim ekranı (`picker`) zaten `KINDS` listesini okuyarak sekmelerini otomatik oluşturduğu için başka bir değişiklik gerekmez.

---

## 5. Site ayarları

**Admin → Ayarlar → "user cosmetics"** araması:

- `discourse_user_cosmetics_enabled` — eklentiyi tamamen aç/kapat.
- `discourse_user_cosmetics_avatar_frames_enabled` / `..._nameplates_enabled` / `..._card_decorations_enabled` — kategorileri ayrı ayrı aç/kapat.
- `discourse_user_cosmetics_frame_overhang_percent` — çerçevenin avatarın kenarından ne kadar taştığı (varsayılan %14).
- `discourse_user_cosmetics_max_image_kb` — yüklenebilecek en büyük görsel boyutu.

---

## 6. Teknik notlar ve olası sorun giderme

Bu paket, Discourse'un güncel (2026) `.gjs` bileşen mimarisine ve `api.renderInOutlet()` API'sine göre yazıldı. Yine de Discourse sık güncellenen bir platform olduğğu için, sunucunuza kurduktan sonra tarayıcı konsolunda (F12) şunlara bakmakta fayda var:

- **Avatar çerçeveleri hiç görünmüyorsa:** `/user-cosmetics/frames.css` adresini tarayıcıda doğrudan açıp bir çıktı gelip gelmediğine bakın. Boşsa, ilgili site ayarının açık olduğundan ve en az bir kullanıcının bir çerçeve seçtiğinden emin olun.
- **İsim plakası / kart dekorasyonu görünmüyor ama çerçeveler çalışıyorsa:** Discourse'un o sürümünde `user-card-post-names`, `user-card-metadata` veya `user-profile-primary` genişletme noktalarının adı değişmiş olabilir. `assets/javascripts/discourse/api-initializers/user-cosmetics.js` içindeki `api.renderInOutlet("...", ...)` satırlarındaki isimleri, tarayıcı konsolunda `enableDevTools()` yazıp beliren fiş simgesiyle (Discourse Geliştirici Araç Çubuğu) o sayfadaki güncel genişletme noktası adlarıyla karşılaştırıp güncelleyebilirsiniz. Bu, tek bir dosyada birkaç satırlık bir düzeltmedir; geri kalan her şeyi etkilemez.
- **Çeviri metinleri yerine `discourse_user_cosmetics.xxx` gibi ham anahtarlar görünüyorsa:** `assets/javascripts/discourse/lib/duc-i18n.js` içindeki yardımcı, çeviri için tarayıcıdaki uzun süredir var olan `I18n` nesnesini kullanır; bu son derece köklü bir API olduğu için kırılması beklenmez, ama kırılırsa yine de sayfa çökmez, sadece ham anahtar metni görünür.

Bu üç senaryo dışında bir hata görürseniz (örn. admin sayfası hiç açılmıyorsa), önce `./launcher logs app` ile sunucu loglarına, sonra tarayıcı konsoluna bakmanızı öneririm; genelde net bir hata satırı verir.

---

## 7. Güvenlik / izin modeli

- Admin ekranına yalnızca **tam admin** yetkisi olan kullanıcılar erişebilir (moderatörler değil).
- Bir kullanıcı, sunucu tarafında `usable_by?` kontrolünden geçmeyen bir öğeyi asla "giyemez" — arayüzdeki kilit rozetleri sadece görsel geri bildirimdir, gerçek yetki kontrolü her zaman `app/controllers/discourse_user_cosmetics/items_controller.rb#select` içinde sunucu tarafında yapılır.
- Görsel yüklemeleri Discourse'un kendi `/uploads.json` altyapısını kullanır; ayrı bir dosya deposu icat edilmemiştir.

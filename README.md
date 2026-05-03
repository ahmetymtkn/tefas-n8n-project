# 📈 TEFAS Otomatik Veri Toplama Sistemi

n8n üzerinde kurulu, TEFAS (Türkiye Elektronik Fon Alım Satım Platformu) verilerini otomatik olarak çekip MySQL veritabanına kaydeden bir otomasyon sistemi. Her gün öğlen 12:00'de çalışarak tüm yatırım fonu verilerini, tarihsel fiyat geçmişlerini ve trend analizlerini güncel tutar.

---

## 📋 İçindekiler

- [Genel Bakış](#genel-bakış)
- [Sistem Mimarisi](#sistem-mimarisi)
- [Veritabanı Şeması](#veritabanı-şeması)
- [Workflow'lar](#workflowlar)
  - [yenitefas (Ana Workflow)](#1-yenitefas---ana-workflow)
  - [tefasEnCokKazandiranlar](#2-tefasencokkazandiranlar)
  - [tefasfongetiri](#3-tefasfongetiri)
  - [tefasFonBilgi](#4-tefasfonbilgi)
  - [tarihselveri](#5-tarihselveri)
- [Kurulum](#kurulum)
- [Gereksinimler](#gereksinimler)

---

## Genel Bakış

Bu sistem, TEFAS'taki tüm yatırım fonlarına (YAT tipi) ait verileri otomatik olarak toplar ve analiz eder. Toplanan veriler şunlardır:

- Tüm fonların listesi, kategorileri ve detay bilgileri
- Her fon için 8 farklı dönemde (haftalık, aylık, yıllık vb.) getiri karşılaştırmaları
- Kategori ve fon bazında en çok kazandıran sıralamalar
- Son 5 yıla ait günlük fiyat ve portföy dağılım geçmişi
- 40 günlük fiyat hareketlerine dayalı yükseliş/düşüş trend analizi

Sistem, n8n'de 5 ayrı workflow'dan oluşur: 1 ana orkestratör ve 4 alt (sub) workflow. Ana workflow sırayla alt workflow'ları çağırarak veriyi katmanlı biçimde toplar.

---

## Sistem Mimarisi

```
yenitefas (Ana Workflow - Her gün 12:00)
│
├─► Fon & Kategori Çekme
│     └─► TEFAS API → tefas_funds + tefas_category tabloları
│
├─► [Sub] tefasEnCokKazandiranlar  (8 dönem × her çalışmada)
│     └─► TEFAS API → tefas_best_fund_rates + tefas_best_category_rates
│
├─► [Sub] tefasfongetiri           (her fon için)
│     └─► TEFAS API → tefas_comparison_history
│
├─► [Sub] tefasFonBilgi            (her fon için)
│     └─► TEFAS HTML Scraping → tefas_funds + fund_stats_history
│
└─► [Sub] tarihselveri             (eksik günler için)
      └─► TEFAS API → tefas_fund_details (5 yıllık geçmiş)
          + Trend Analizi → tefas_trend_analysis + tefas_trend_checking
```

---

## Veritabanı Şeması

Sistem toplam 10 MySQL tablosu kullanır.

### `tefas_category`
Fon kategorilerini (örn. "Hisse Senedi Fonu", "Borçlanma Araçları Fonu") saklar.

| Sütun | Tip | Açıklama |
|-------|-----|----------|
| `id` | INT AUTO_INCREMENT | Birincil anahtar |
| `name` | VARCHAR(255) UNIQUE | Kategori adı |
| `created_at` | TIMESTAMP | Oluşturulma zamanı |

---

### `tefas_periods`
Getiri hesaplamasında kullanılan dönemleri tanımlar. Statik referans tablosudur, sistem başlangıcında sabit değerlerle doldurulur.

| id | period_name |
|----|-------------|
| 0  | YTD |
| 1  | 1 Aylık |
| 3  | 3 Aylık |
| 6  | 6 Aylık |
| 12 | 1 Yıllık |
| 13 | Haftalık |
| 36 | 3 Yıllık |
| 60 | 5 Yıllık |

---

### `tefas_funds`
Her yatırım fonunun kimlik ve işlem bilgilerini saklar. Fon kodu (`code`) birincil tanımlayıcıdır.

| Sütun | Tip | Açıklama |
|-------|-----|----------|
| `code` | VARCHAR(20) UNIQUE | Fon kodu (örn. "GJD") |
| `name` | VARCHAR(255) | Fon tam adı |
| `category_id` | INT FK | Bağlı kategori |
| `isin_code` | VARCHAR(20) | ISIN kodu |
| `platform_status` | VARCHAR(100) | Platform durumu (Aktif/Pasif) |
| `start_time` / `end_time` | VARCHAR(10) | İşlem saatleri |
| `buy_valor` / `sell_valor` | INT | Alış/satış valörü (gün) |
| `min/max_buy/sell_amount` | DECIMAL | Min/max işlem tutarları |
| `entry_commission` / `exit_commission` | DECIMAL | Giriş/çıkış komisyonları |
| `interest_content` | VARCHAR(255) | Faiz içeriği |
| `risk_value` | INT | Risk değeri (1-7) |
| `fon_varlık_dagılım_list` | TEXT | Varlık türleri (JSON array) |
| `fon_varlık_dagılım_degerler` | TEXT | Varlık oranları (JSON array) |
| `updated_at` | TIMESTAMP | Son güncelleme zamanı |

---

### `fund_stats_history`
Her fona ait günlük istatistiklerin tarihsel kaydı. Birincil anahtar `(code, created_at)` çiftidir.

| Sütun | Açıklama |
|-------|----------|
| `last_price` | Son fiyat (TL) |
| `daily_return` | Günlük getiri (%) |
| `shares_outstanding` | Tedavüldeki pay sayısı |
| `total_value` | Fon toplam değeri (TL) |
| `category_rank` | Kategori derecesi |
| `investor_count` | Yatırımcı sayısı |
| `market_share` | Pazar payı |
| `return_1m/3m/6m/1y` | 1/3/6 ay ve 1 yıllık getiri |

---

### `tefas_fund_details`
Her fon için günlük fiyat ve portföy bileşen yüzdelerinin tarihsel kaydı. Birincil anahtar `(code, tarih)` çiftidir. 5 yıla kadar geriye gider.

Tablo, TEFAS'ın varlık dağılım kodlarını sütun olarak içerir (BB, BPP, BYF, HB, HS, KH, KM, vb. — bunlar hisse, borçlanma aracı, altın gibi varlık türü kodlarıdır). Ek olarak şu operasyonel sütunlar tutulur:

| Sütun | Açıklama |
|-------|----------|
| `FIYAT` | O günkü fon fiyatı |
| `TEDPAYSAYISI` | Tedavüldeki pay sayısı |
| `KISISAYISI` | Yatırımcı sayısı |
| `PORTFOYBUYUKLUK` | Portföy büyüklüğü (TL) |
| `BORSABULTENFIYAT` | Borsa bülten fiyatı |
| `BilFiyat` | Birim pay değeri |

---

### `tefas_best_category_rates`
Kategori bazında dönemsel en iyi getiri oranlarını saklar. Her kategori + dönem + tarih kombinasyonu benzersizdir.

| Sütun | Açıklama |
|-------|----------|
| `category_id` | Bağlı kategori |
| `period_id` | Bağlı dönem |
| `getiri` | O dönemdeki getiri oranı |
| `pazarbuyukluk` | Kategorinin pazar büyüklüğü |
| `fetched_at` | Verinin çekildiği tarih |

---

### `tefas_best_fund_rates`
Fon bazında dönemsel en iyi getiri oranlarını saklar. Her fon + dönem + tarih kombinasyonu benzersizdir.

| Sütun | Açıklama |
|-------|----------|
| `fund_id` | Bağlı fon |
| `category_id` | Fonun kategorisi |
| `period_id` | Bağlı dönem |
| `rate` | O dönemdeki getiri oranı |
| `fetched_at` | Verinin çekildiği tarih |

---

### `tefas_comparison_history`
Her fonun, kendi kategorisindeki diğer fonlarla getiri karşılaştırmasını saklar. Karşılaştırma isimleri ve değerleri JSON array olarak tutulur.

| Sütun | Açıklama |
|-------|----------|
| `fund_code` | Fon kodu |
| `period_id` | Karşılaştırma dönemi |
| `comparison_names` | Karşılaştırılan fon kodları (JSON) |
| `comparison_values` | Karşılaştırma getiri değerleri (JSON) |
| `fetched_at` | Verinin çekildiği tarih |

---

### `tefas_trend_checking`
Son 40 günlük veriye dayalı olarak her fonun kaç gün yükseldiğini/düştüğünü ve 40 günlük toplam getirisini saklar.

| Sütun | Açıklama |
|-------|----------|
| `fund_code` | Fon kodu |
| `analysis_date` | Analiz tarihi |
| `up_days_count` | Yükseliş gün sayısı |
| `down_days_count` | Düşüş gün sayısı |
| `total_return` | 40 günlük toplam getiri (%) |

---

### `tefas_trend_analysis`
Her fonun güncel yükseliş/düşüş serisini (streak) ve seri boyunca gerçekleşen fiyat değişimini saklar.

| Sütun | Açıklama |
|-------|----------|
| `fund_code` | Fon kodu |
| `up_streak` | Kaç gün üst üste yükseldi |
| `down_streak` | Kaç gün üst üste düştü |
| `change_percent` | Seri başından bu yana değişim (%) |
| `last_price` | Son fiyat |
| `analysis_date` | Analiz tarihi |

---

## Workflow'lar

### 1. `yenitefas` — Ana Workflow

Her gün saat **12:00**'de otomatik başlayan orkestratör workflow. Diğer tüm alt workflow'ları sırayla çağırır.

#### Node'lar

| Node | Tipi | Görevi |
|------|------|--------|
| **Schedule Trigger** | Zamanlayıcı | Her gün 12:00'de workflow'u başlatır. |
| **fon bilgi** | HTTP Request (POST) | TEFAS API'nin `fonGetiriBazliBilgiGetir` endpoint'ine istek atar. Tüm YAT (yatırım) tipi fonların listesini, adlarını ve kategorilerini çeker. |
| **fon liste** | Code | API yanıtındaki `resultList` dizisini düzenler; her eleman için `fund_code`, `fund_name` ve `category_name` alanlarını çıkarır. |
| **category isimleri ayrıştırma** | Remove Duplicates | Fon listesinden benzersiz kategori adlarını ayıklar. Aynı kategorinin birden fazla kaydedilmesini önler. |
| **kategori kayıt** | MySQL | Her benzersiz kategori adını `tefas_category` tablosuna ekler. Zaten varsa atlar (`WHERE NOT EXISTS`). |
| **Wait** | Bekleme | 1 saniye bekler. Veritabanı işlemleri tamamlanmadan fon kayıt adımına geçilmemesi için senkronizasyon sağlar. |
| **fon kayıt** | MySQL | Her fonun adını ve kategori ID'sini `tefas_funds` tablosuna yazar. Varsa günceller, yoksa ekler (upsert). |
| **periyods** | Code | 8 farklı dönem tanımını (YTD, 1A, 3A, 6A, 1Y, 3Y, 5Y, haftalık) bir liste olarak üretir. |
| **Loop Over Items** | Split in Batches | 8 dönem için döngü kurar. Her iterasyonda bir sonraki dönem `tefasEnCokKazandiranlar` sub-workflow'una gönderilir. |
| **Call 'tefasEnCokKazandiranlar'** | Execute Workflow | Her dönem için `tefasEnCokKazandiranlar` sub-workflow'unu çağırır. Sonucu bekleme**z** (fire-and-forget), paralel çalışmaya devam eder. |
| **temizle** | Code | Döngü bitişinde birden fazla gelen item'i tek bir `{done: true}` nesnesine indirger. Sonraki adımın temiz veri alması için yapılır. |
| **fonları getir1** | MySQL | `tefas_funds` tablosundan tüm fon kodlarını çeker. Sonraki aşamada her fon için detay çekimi yapılacak. |
| **Loop Over Items3** | Split in Batches | Her fon kodu için döngü kurar. |
| **Call 'tefasfongetiri'1** | Execute Workflow | Her fon için `tefasfongetiri` sub-workflow'unu çağırır (getiri karşılaştırma verisini çeker). |
| **Edit Fields** | Set | Döngüdeki fon kodunu (`code`) bir sonraki adım için temizlenmiş biçimde iletir. |
| **Wait2** | Bekleme | 1 saniye bekler. TEFAS API'ye art arda istek göndermemek için rate-limiting önlemi. |
| **Call 'tefasFonBilgi'1** | Execute Workflow | Her fon için `tefasFonBilgi` sub-workflow'unu çağırır (HTML scraping ile detaylı bilgi çeker). |
| **temizle1** | Code | Fon döngüsü bitişinde item'ları tek nesneye indirger. |
| **kayitli tarihler** | MySQL | `tefas_fund_details` tablosundaki mevcut tarihleri çeker (`SELECT DISTINCT tarih`). |
| **olmayan tarihler** | Code | Bugünden 5 yıl geriye giderek hafta sonlarını atlayarak tüm iş günlerini hesaplar, veritabanında olmayan günleri tespit eder. |
| **format dönüşümü** | Code | Tespit edilen eksik tarihleri `YYYYMMDD` formatına çevirir (TEFAS API'nin beklediği format). |
| **Loop Over Items2** | Split in Batches | Her eksik tarih için döngü kurar. |
| **Call 'tarihselveri'1** | Execute Workflow | Her eksik tarih için `tarihselveri` sub-workflow'unu çağırır (o günün tüm fon verilerini çeker). |
| **Wait1** | Bekleme | API istekleri arasında bekleme sağlar. |
| **tarih bilgisi1** | Code | Bugünden 5 yıl geriye giderek tarihleri 10'ar günlük batch'lere böler (5., 15., 25. günler). Bu batch'ler `tarihselveri` sub-workflow'una toplu gönderilir. |
| **Loop Over Items5** | Split in Batches | 5 yıllık tarih batch'leri için döngü kurar. |
| **Call 'tarihselveri'** | Execute Workflow | Her tarih aralığı için `tarihselveri` sub-workflow'unu çağırır. Sonucu **bekler** (`waitForSubWorkflow: true`). |
| **40 günlük veri** | MySQL | `tefas_fund_details` tablosundan son 40 günlük fiyat verilerini çeker. Trend analizi için girdi oluşturur. |
| **yükseliş analizi** | Code | Her fon için ardışık yükseliş veya düşüş serisini (streak) hesaplar. Seri başından bu yana olan yüzde değişimi de bulur. |
| **yükseliş ve düşüş analiz** | Code | Her fon için 40 gün içinde kaç gün yükseldiğini, kaç gün düştüğünü ve 40 günlük toplam getirisini hesaplar. |
| **sql kayıt** | MySQL | `yükseliş analizi` sonuçlarını `tefas_trend_analysis` tablosuna yazar (upsert). |
| **sql kayıt1** | MySQL | `yükseliş ve düşüş analiz` sonuçlarını `tefas_trend_checking` tablosuna yazar (upsert). |
| **temizle2** | Code | Trend döngüsü bitişinde item'ları tek nesneye indirger. |

---

### 2. `tefasEnCokKazandiranlar`

Ana workflow tarafından her dönem için ayrı ayrı çağrılır. Belirli bir dönemdeki en çok kazandıran kategori ve fonları çekip veritabanına kaydeder.

#### Node'lar

| Node | Tipi | Görevi |
|------|------|--------|
| **When Executed by Another Workflow** | Trigger | Ana workflow'dan gelen `period` değerini alır. |
| **best category and funds** | HTTP Request (POST) | TEFAS API'nin `fonTurDnmGetiriGetir` endpoint'ine istekte bulunur. Gelen `period` değerini request body'de kullanarak o dönemdeki en iyi kategori ve fon sıralamalarını çeker. Yanıt; kategori bilgilerini, her kategorideki en iyi fonları ve getirilerini içerir. |
| **sql code creater** | Code | API yanıtını işler ve her kayıt için SQL sorguları üretir. Önce kategori yoksa ekle (`INSERT ... WHERE NOT EXISTS`), ardından kategori getirisini `tefas_best_category_rates`'e, fon getirisini `tefas_best_fund_rates`'e yazan upsert sorguları oluşturur. Fonksiyon içinde NULL güvenliği ve SQL injection koruması (`esc()` fonksiyonu) uygulanır. |
| **best save** | MySQL | Üretilen SQL sorgularını tek tek çalıştırır. Hata alsa bile devam eder (`onError: continueRegularOutput`), ayrıca hata sonrası yeniden dener (`retryOnFail: true`). |

---

### 3. `tefasfongetiri`

Her fon için ana workflow tarafından çağrılır. Fonun, kendi kategorisindeki diğer fonlarla getiri karşılaştırmasını 8 dönem için çekip kaydeder.

#### Node'lar

| Node | Tipi | Görevi |
|------|------|--------|
| **When Executed by Another Workflow** | Trigger | Ana workflow'dan gelen fon `code` değerini alır. |
| **periyods** | Code | 8 dönem listesini üretir (YTD, 1A, 3A, 6A, 1Y, 3Y, 5Y, haftalık). Her dönem için ayrı API çağrısı yapılacak. |
| **Loop Over Items** | Split in Batches | 8 dönem için döngü kurar; her iterasyonda bir dönem işlenir. |
| **fon getiri karşılaştır** | HTTP Request (POST) | TEFAS API'nin `fonProfilDtyGetir` endpoint'ine istek atar. Fon kodu ve dönem bilgisini göndererek o fonun kendi kategorisiyle kıyaslama verisini çeker. Hata alsa devam eder. |
| **veri düzenleme** | Code | API yanıtındaki `resultList` dizisini işler. Her fonun kodunu (`fonKodu`) ve getiri değerini (`fonTurGetiri`) çıkarır; bunları iki ayrı JSON array'e (`comparison_names`, `comparison_values`) dönüştürür. |
| **database kayıt** | MySQL | Düzenlenen veriyi `tefas_comparison_history` tablosuna yazar (upsert). Aynı fon + dönem + tarih için kayıt varsa günceller. |
| **temizlik** | Code | Her döngü iterasyonu sonunda item'ları tek `{done: true}` nesnesine indirger. |
| **Replace Me** | No-Op | Döngüyü tekrar başlatmak için `Loop Over Items` node'una geri bağlanır. 8 dönem bitince akış durur. |
| **temizle2** | Code | Döngü tamamen bittiğinde nihai temizliği yapar. |

---

### 4. `tefasFonBilgi`

Her fon için HTML scraping yöntemiyle TEFAS detay sayfasından kapsamlı fon bilgisi çeker.

#### Node'lar

| Node | Tipi | Görevi |
|------|------|--------|
| **When Executed by Another Workflow** | Trigger | Ana workflow'dan gelen fon `code` değerini alır. |
| **fon analiz** | HTTP Request (GET) | `https://www.tefas.gov.tr/tr/fon-detayli-analiz/{code}` adresine GET isteği atar. Fonun tam HTML detay sayfasını indirir. Hata alsa devam eder. |
| **veri parser** | HTML | HTML sayfasının `.fund-detail-content` CSS seçicisiyle içeriğini çıkarır. Fon bilgisi, varlık dağılımı ve getiri bilgisi bölümlerini ham metin olarak alır. |
| **veri kontrol** | If | Çıkarılan verinin boş olup olmadığını kontrol eder. Boşsa, veri gelene kadar `Wait1` node'una yönlendirir (60 saniye bekleyip sayfayı yeniden yükler). |
| **Wait1** | Bekleme | 60 saniye bekler. Sayfa yüklenemediğinde yeniden deneme mekanizması olarak kullanılır. |
| **sql üretici** | Code | Ham metni ayrıştırır. `parseTefasLikeText()` fonksiyonu; fon kodu, ISIN, platform durumu, faiz içeriği, risk değeri, fiyat, günlük getiri, yatırımcı sayısı ve varlık dağılımı gibi tüm alanları satır satır okur. `buildDbRow()` fonksiyonu ile veritabanı alanlarına map eder. Son olarak `tefas_funds` için UPDATE ve `fund_stats_history` için INSERT sorguları üretir. |
| **Execute a SQL query** | MySQL | Üretilen iki SQL sorgusunu çalıştırır. `tefas_funds`'ı günceller, `fund_stats_history`'e günlük kayıt ekler. |
| **temizle2** | Code | İşlem bitişinde item'ları tek nesneye indirger. |

---

### 5. `tarihselveri`

Belirli bir tarih aralığı için tüm fonların günlük fiyat ve portföy dağılım verilerini çekip `tefas_fund_details` tablosuna kaydeder. Ana workflow tarafından hem 5 yıllık ilk yükleme hem de eksik günlerin tamamlanması için çağrılır.

#### Node'lar

| Node | Tipi | Görevi |
|------|------|--------|
| **When Executed by Another Workflow** | Trigger | Ana workflow'dan `startDate` ve `endDate` (YYYYMMDD formatında) değerlerini alır. |
| **genel bilgiler1** | HTTP Request (POST) | TEFAS API'nin `fonGnlBlgSiraliGetir` endpoint'ine istek atar. Verilen tarih aralığındaki tüm YAT fonları için fiyat, pay sayısı, kişi sayısı ve portföy büyüklüğü bilgilerini çeker (1'den 10.000'e kadar sıralı). |
| **If1** | If | API yanıtında `resultList` boş mu diye kontrol eder. Boşsa akış `temizle1`'e yönlenir ve o tarih aralığı atlanır. |
| **portföy dağılımı1** | HTTP Request (POST) | TEFAS API'nin `dagilimSiraliGetirT` endpoint'ine istek atar. Aynı tarih aralığı için tüm fonların varlık dağılım yüzdelerini (BB, HB, KH gibi 50'yi aşkın kod) çeker. |
| **If** | If | Portföy dağılımı yanıtında hata var mı kontrol eder. Hata varsa veri düzenleme adımını atlar. |
| **veri düzenleme1** | Code | İki API yanıtını birleştirir. Her fon kodu için genel bilgi ile portföy dağılımını eşleştirir. Map yapısı kullanılarak performans optimize edilmiştir (`O(n)` yerine `O(1)` arama). Tarihi `DD.MM.YYYY` formatına çevirir. |
| **sql üretici1** | Code | Birleştirilen veriden her fon için SQL INSERT değerlerini üretir. Tüm 50+ alan için alan adı normalizasyonu yapar (büyük/küçük harf ve Türkçe karakter farklılıklarını giderir). |
| **Loop Over Items** | Split in Batches | Üretilen kayıtları **200'lük gruplar** halinde işler. Büyük tarih aralıklarında binlerce fon kaydının toplu yüklenmesi sırasında bellek ve bağlantı yönetimini sağlar. |
| **EXECUTE SQL** | MySQL | Her kayıt için `tefas_fund_details` tablosuna `INSERT ... ON DUPLICATE KEY UPDATE` yapar. Fon `tefas_funds`'ta yoksa atlar (`WHERE EXISTS` koşulu). Zaten kayıtlıysa temel fiyat sütunlarını günceller. |
| **temizle1** | Code | Döngü bitişinde item'ları tek nesneye indirger. |
| **Replace Me** | No-Op | Döngüyü tekrar `Loop Over Items`'a bağlar; batch bitene kadar devam eder. |

---

## Kurulum

### 1. Veritabanını Oluşturun

```bash
mysql -u kullanici -p veritabani_adi < tefas.sql
```

### 2. Workflow'ları n8n'e Aktarın

n8n arayüzünde sırayla şu dosyaları import edin:

1. `tarihselveri.json`
2. `tefasEnCokKazandiranlar.json`
3. `tefasfongetiri.json`
4. `tefasFonBilgi.json`
5. `yenitefas.json`

> **Önemli:** Alt workflow'lar önce import edilmelidir. Ana workflow (`yenitefas`) onların ID'lerine referans verir.

### 3. MySQL Bağlantısını Tanımlayın

n8n'de tüm MySQL node'ları için aynı credential'ı kullanın. Credential adının tüm workflow'larda tutarlı olmasına dikkat edin.

### 4. Sub-workflow ID'lerini Güncelleyin

Import sonrasında `yenitefas` workflow'undaki `Call 'tefasEnCokKazandiranlar'`, `Call 'tarihselveri'`, `Call 'tefasfongetiri'1` ve `Call 'tefasFonBilgi'1` node'larında referans verilen workflow ID'lerini, import sonrasında oluşan gerçek ID'lerle güncelleyin.

### 5. İlk Çalıştırma

İlk çalıştırmada sistem 5 yıllık geçmiş veriyi doldurmaya çalışır. Bu işlem, fon sayısına ve internet bağlantısına bağlı olarak uzun sürebilir. n8n'in execution timeout değerini buna göre ayarlayın.

---

## Gereksinimler

- **n8n** (v1.0 ve üzeri)
- **MySQL** 5.7+ veya **MariaDB** 10.3+
- TEFAS API'ye erişim (kamuya açık, kimlik doğrulama gerekmez)
- n8n sunucusunun internet erişimi olması

---

## Notlar

- Tüm TEFAS API istekleri `X-Requested-With: XMLHttpRequest` başlığı ile yapılır.
- Rate limiting için node'lar arasına 1 saniyelik bekleme eklenmiştir.
- `tefasFonBilgi` workflow'u HTML scraping yaptığından TEFAS web sitesinin sayfa yapısı değişirse `veri parser` node'unun CSS seçicisi güncellenmesi gerekebilir.
- Tüm upsert işlemleri idempotent yapıdadır; workflow aynı gün birden fazla çalıştırılsa da veri bütünlüğü korunur.
# Flutter CI/CD için Gerekli Tüm Şeyler - Komple Checklist

## 📑 İçindekiler
1. [Hesaplar ve Üyelikler](#1-hesaplar-ve-üyelikler)
2. [Android Gereksinimleri](#2-android-gereksinimleri)
3. [iOS Gereksinimleri](#3-ios-gereksinimleri)
4. [Firebase Gereksinimleri](#4-firebase-gereksinimleri)
5. [GitHub Gereksinimleri](#5-github-gereksinimleri)
6. [Kod Tarafı Düzenlemeler](#6-kod-tarafı-düzenlemeler)
7. [İsteğe Bağlı Ama Önerilen](#7-isteğe-bağlı-ama-önerilen)
8. [Toplam Maliyet Hesabı](#8-toplam-maliyet-hesabı)

---

## 1. Hesaplar ve Üyelikler

### ✅ Google Play Console Hesabı
**Ne:** Android uygulamaları yayınlamak için Google'ın platformu  
**Neden Gerekli:** Play Store'da uygulama yayınlamak zorunlu  
**Maliyet:** $25 (bir kerelik, ömür boyu)  
**Nasıl Alınır:**
1. https://play.google.com/console adresine gidin
2. Google hesabınızla giriş yapın
3. $25 developer kayıt ücreti ödeyin
4. Geliştirici profili bilgilerini doldurun
5. Onay 1-2 gün sürebilir

**Gerekli Erişim Seviyeleri:**
- Admin erişimi (uygulama yayınlamak için)
- Release management
- Service account oluşturma izni

---

### ✅ Apple Developer Program Üyeliği
**Ne:** iOS uygulamaları yayınlamak için Apple'ın developer programı  
**Neden Gerekli:** App Store'da uygulama yayınlamak ve sertifika oluşturmak zorunlu  
**Maliyet:** $99/yıl (yıllık abonelik)  
**Nasıl Alınır:**
1. https://developer.apple.com/programs/ adresine gidin
2. Apple ID ile kayıt olun
3. Kişisel veya şirket hesabı seçin (Şirket için D-U-N-S number gerekli)
4. $99 yıllık ücret ödeyin
5. Onay 24-48 saat sürebilir

**Gerekli Roller:**
- Account Holder veya Admin
- Certificates, Identifiers & Profiles erişimi
- App Store Connect erişimi

---

### ✅ Firebase Hesabı
**Ne:** Google'ın mobil app geliştirme platformu  
**Neden Gerekli:** Test dağıtımı (Firebase App Distribution) için  
**Maliyet:** Ücretsiz (Spark Plan) - App Distribution için yeterli  
**Nasıl Alınır:**
1. https://firebase.google.com/ adresine gidin
2. Google hesabınızla giriş yapın
3. "Go to console" tıklayın
4. Yeni proje oluşturun

**Not:** App Distribution, Analytics gibi özellikler ücretsiz planda mevcut

---

### ✅ GitHub Hesabı
**Ne:** Kod repository ve CI/CD için  
**Neden Gerekli:** Kod yönetimi ve GitHub Actions için  
**Maliyet:** 
- Ücretsiz (public repo için yeterli)
- Veya $4/ay (private repo + daha fazla Actions minutes)
**Nasıl Alınır:**
1. https://github.com/ adresine gidin
2. Ücretsiz hesap oluşturun

**GitHub Actions Ücretsiz Limit:**
- Public repo: Sınırsız dakika
- Private repo: 2,000 dakika/ay (yeterli)

---

### ⭐ Codecov Hesabı (Opsiyonel)
**Ne:** Test coverage raporlama  
**Neden Gerekli:** Code coverage takibi için (opsiyonel ama önerilen)  
**Maliyet:** Ücretsiz (public repo için)  
**Nasıl Alınır:**
1. https://codecov.io/ adresine gidin
2. GitHub hesabınızla giriş yapın
3. Repository'nizi bağlayın

---

## 2. Android Gereksinimleri

### ✅ Keystore Dosyası (.jks)
**Ne:** Android uygulamanızı imzalamak için dijital sertifika  
**Neden Gerekli:** Play Store'a yüklemek için APK/AAB imzalanmalı  
**Nasıl Oluşturulur:**

```bash
keytool -genkey -v -keystore ~/upload-keystore.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias upload \
  -storetype JKS
```

**Sorulacak Bilgiler:**
- Keystore password: Güçlü bir şifre seçin
- Key password: Güçlü bir şifre seçin (farklı olabilir)
- First and Last Name: Ad soyad veya şirket adı
- Organizational Unit: Bölüm adı (ör: Development)
- Organization: Şirket adı
- City/Locality: Şehir
- State/Province: İl
- Country Code: TR

**UYARI:**
- ⚠️ Bu dosyayı ve şifreleri KESİNLİKLE kaybetmeyin!
- ⚠️ Kaybederseniz uygulamanızı güncelleyemezsiniz
- ⚠️ Güvenli bir yerde yedekleyin (password manager + cloud)
- ⚠️ Git'e KESİNLİKLE commit etmeyin

**Saklayın:**
```
keystore.jks
Keystore password: [şifre]
Key alias: upload
Key password: [şifre]
```

---

### ✅ Google Play Service Account
**Ne:** Play Store API'sine erişim için service account  
**Neden Gerekli:** CI/CD'den otomatik upload için  
**Nasıl Oluşturulur:**

#### Adım 1: Google Cloud Console'da Service Account Oluşturma
1. Google Cloud Console'a gidin: https://console.cloud.google.com/
2. Play Console ile ilişkili projeyi seçin (yoksa oluşturun)
3. IAM & Admin > Service Accounts
4. "Create Service Account" tıklayın
5. İsim verin (ör: "github-actions-deployer")
6. "Create and Continue" tıklayın
7. Role seçin: "Service Account User"
8. "Done" tıklayın
9. Oluşturulan service account'a tıklayın
10. Keys sekmesi > Add Key > Create new key
11. JSON formatını seçin
12. İndirilen JSON dosyasını güvenli yerde saklayın

#### Adım 2: Play Console'da Service Account'u Bağlama
1. Play Console'a gidin: https://play.google.com/console
2. Setup > API access
3. "Link" butonuna tıklayın (yeni service account için)
4. Service account'u seçin ve bağlayın
5. Grant Access tıklayın
6. İzinleri ayarlayın:
   - Admin (Releases): View, Create, Edit
   - Release Manager: All permissions

**Saklayın:**
```json
{
  "type": "service_account",
  "project_id": "...",
  "private_key_id": "...",
  "private_key": "...",
  ...
}
```

---

### ✅ Android App Bundle ID
**Ne:** Uygulamanızın benzersiz tanımlayıcısı  
**Neden Gerekli:** Play Store'da uygulamayı tanımlamak için  
**Format:** com.sirketadi.uygulamaadi (ör: com.onmuhasebe.mobile)  
**Nereden:** `android/app/build.gradle` dosyasında:
```gradle
defaultConfig {
    applicationId "com.onmuhasebe.mobile"
    ...
}
```

---

### ✅ key.properties Dosyası (Template)
**Ne:** Keystore bilgilerini tutan konfigürasyon  
**Neden Gerekli:** Android build sırasında imzalama için  
**Konum:** `android/key.properties`  
**İçerik:**
```properties
storePassword=your-keystore-password
keyPassword=your-key-password
keyAlias=upload
storeFile=../upload-keystore.jks
```

**UYARI:** Bu dosyayı .gitignore'a ekleyin!

---

### ✅ android/app/build.gradle Düzenlemesi
**Ne:** Build konfigürasyonu  
**Neden Gerekli:** Release build'lerde imzalama için  
**Yapılması Gereken:**

```gradle
// Dosyanın başına ekleyin
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    ...
    
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
```

---

### ✅ ProGuard Rules (Opsiyonel ama Önerilen)
**Ne:** Kod obfuscation kuralları  
**Neden Gerekli:** Güvenlik ve APK boyutu optimizasyonu  
**Konum:** `android/app/proguard-rules.pro`  
**Temel İçerik:**
```proguard
# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
```

---

## 3. iOS Gereksinimleri

### ✅ App Store Connect Hesap Erişimi
**Ne:** iOS uygulamalarını yönetmek için Apple'ın platformu  
**Neden Gerekli:** App Store'a upload ve metadata yönetimi  
**Nasıl Erişilir:**
1. https://appstoreconnect.apple.com/ adresine gidin
2. Apple Developer hesabınızla giriş yapın
3. "My Apps" bölümünde uygulamanızı oluşturun

---

### ✅ iOS Distribution Certificate (.p12)
**Ne:** iOS uygulamanızı imzalamak için sertifika  
**Neden Gerekli:** App Store'a yüklemek için IPA imzalanmalı  
**Nasıl Oluşturulur:**

#### Adım 1: Certificate Signing Request (CSR) Oluşturma
1. Mac'te "Keychain Access" uygulamasını açın
2. Keychain Access > Certificate Assistant > Request a Certificate From a Certificate Authority
3. Email adresinizi girin
4. "Saved to disk" seçin
5. "Continue" ve dosyayı kaydedin

#### Adım 2: Developer Portal'da Certificate Oluşturma
1. https://developer.apple.com/account/resources/certificates adresine gidin
2. "+" butonuna tıklayın
3. "Apple Distribution" seçin
4. Continue
5. CSR dosyasını yükleyin
6. Download tıklayın (.cer dosyası inecek)

#### Adım 3: P12 Export
1. İndirilen .cer dosyasına çift tıklayın (Keychain'e eklenecek)
2. Keychain Access'te "Certificates" kategorisinde bulun
3. Certificate'e sağ tık > Export
4. .p12 formatını seçin
5. Güçlü bir şifre belirleyin (bunu saklayın!)
6. Export edin

**Saklayın:**
```
distribution_certificate.p12
Certificate password: [şifre]
```

---

### ✅ Provisioning Profile (.mobileprovision)
**Ne:** Uygulamanızın hangi cihazlarda çalışabileceğini belirler  
**Neden Gerekli:** iOS build ve distribution için zorunlu  
**Nasıl Oluşturulur:**

#### Adım 1: App ID Oluşturma (Eğer yoksa)
1. https://developer.apple.com/account/resources/identifiers adresine gidin
2. "+" butonuna tıklayın
3. "App IDs" seçin, Continue
4. "App" seçin, Continue
5. Description girin
6. Bundle ID girin (ör: com.onmuhasebe.mobile)
7. Capabilities seçin (Push Notifications, In-App Purchase vb.)
8. Continue ve Register

#### Adım 2: Provisioning Profile Oluşturma
1. https://developer.apple.com/account/resources/profiles adresine gidin
2. "+" butonuna tıklayın
3. "App Store" seçin (production için), Continue
4. App ID'nizi seçin, Continue
5. Certificate'ınızı seçin, Continue
6. Profile name girin (ör: "AppStore Distribution Profile")
7. Generate
8. Download (.mobileprovision dosyası inecek)

**Saklayın:**
```
distribution_profile.mobileprovision
```

---

### ✅ App Store Connect API Key
**Ne:** App Store Connect API'sine erişim için key  
**Neden Gerekli:** CI/CD'den otomatik upload için  
**Nasıl Oluşturulur:**

1. App Store Connect'e gidin: https://appstoreconnect.apple.com/
2. Users and Access > Keys sekmesi
3. "App Store Connect API" altında "+" tıklayın
4. Name girin (ör: "GitHub Actions")
5. Access: "Admin" veya "App Manager" seçin
6. Generate tıklayın
7. Download API Key (.p8 dosyası - sadece bir kez indirebilirsiniz!)
8. Key ID ve Issuer ID'yi not edin

**Saklayın:**
```
AuthKey_XXXXXXXXXX.p8
Key ID: XXXXXXXXXX
Issuer ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

---

### ✅ Team ID
**Ne:** Apple Developer hesabınızın benzersiz ID'si  
**Neden Gerekli:** iOS build ve provisioning için  
**Nasıl Bulunur:**
1. https://developer.apple.com/account adresine gidin
2. "Membership" sekmesine tıklayın
3. "Team ID" göreceksiniz (10 karakterlik kod)

**Saklayın:**
```
Team ID: XXXXXXXXXX
```

---

### ✅ Bundle Identifier
**Ne:** iOS uygulamanızın benzersiz tanımlayıcısı  
**Neden Gerekli:** App Store'da uygulamayı tanımlamak için  
**Format:** com.sirketadi.uygulamaadi  
**Nereden:** `ios/Runner/Info.plist` veya Xcode'da:
```xml
<key>CFBundleIdentifier</key>
<string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
```

Xcode'da: Runner target > Signing & Capabilities > Bundle Identifier

---

### ✅ ExportOptions.plist
**Ne:** IPA export konfigürasyonu  
**Neden Gerekli:** xcodebuild ile IPA oluştururken gerekli  
**Konum:** `ios/Runner/ExportOptions.plist`  
**İçerik:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
    <key>uploadBitcode</key>
    <false/>
    <key>compileBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>signingStyle</key>
    <string>manual</string>
    <key>provisioningProfiles</key>
    <dict>
        <key>com.onmuhasebe.mobile</key>
        <string>Your Profile Name</string>
    </dict>
</dict>
</plist>
```

**Değiştirin:**
- `YOUR_TEAM_ID`: Team ID'nizi girin
- `com.onmuhasebe.mobile`: Bundle ID'nizi girin
- `Your Profile Name`: Provisioning profile adınızı girin

---

## 4. Firebase Gereksinimleri

### ✅ Firebase Projesi
**Ne:** Firebase'de oluşturulmuş bir proje  
**Neden Gerekli:** App Distribution ve diğer Firebase servisleri için  
**Nasıl Oluşturulur:**
1. Firebase Console: https://console.firebase.google.com/
2. "Add project" tıklayın
3. Proje adı girin
4. Google Analytics'i etkinleştirin (opsiyonel)
5. Create project

---

### ✅ Firebase Android App
**Ne:** Firebase projesine eklenmiş Android uygulaması  
**Neden Gerekli:** Firebase servislerini kullanmak için  
**Nasıl Eklenir:**
1. Firebase Console'da projenizi açın
2. Android simgesine tıklayın
3. Android package name girin (Bundle ID)
4. App nickname (opsiyonel)
5. Register app
6. `google-services.json` dosyasını indirin
7. `android/app/` klasörüne kopyalayın

**Saklayın:**
```
Firebase Android App ID: 1:xxxxx:android:xxxxx
```

---

### ✅ Firebase iOS App
**Ne:** Firebase projesine eklenmiş iOS uygulaması  
**Neden Gerekli:** Firebase servislerini kullanmak için  
**Nasıl Eklenir:**
1. Firebase Console'da projenizi açın
2. iOS simgesine tıklayın
3. iOS bundle ID girin
4. App nickname (opsiyonel)
5. Register app
6. `GoogleService-Info.plist` dosyasını indirin
7. Xcode'da Runner hedefine ekleyin (drag & drop, "Copy items if needed" seçili)

**Saklayın:**
```
Firebase iOS App ID: 1:xxxxx:ios:xxxxx
```

---

### ✅ Firebase Service Account
**Ne:** Firebase Admin SDK için service account  
**Neden Gerekli:** CI/CD'den Firebase'e erişim için  
**Nasıl Oluşturulur:**

1. Firebase Console > Project Settings (⚙️ ikonu)
2. Service Accounts sekmesi
3. "Generate new private key" tıklayın
4. JSON dosyasını indirin ve güvenli yerde saklayın

**UYARI:** Bu dosya tam erişim sağlar, güvenli tutun!

**Saklayın:**
```json
{
  "type": "service_account",
  "project_id": "your-project",
  "private_key_id": "...",
  "private_key": "...",
  ...
}
```

---

### ✅ Firebase App Distribution Tester Groups
**Ne:** Test kullanıcılarınızın grupları  
**Neden Gerekli:** Build'leri dağıtmak için  
**Nasıl Oluşturulur:**

1. Firebase Console > App Distribution
2. "Testers & Groups" sekmesi
3. "Add Group" tıklayın
4. Grup adı verin (ör: "testers", "qa-team", "beta-users")
5. Tester email'leri ekleyin
6. Create group

**Not:** CI/CD workflow'da bu grup adını kullanacaksınız

---

## 5. GitHub Gereksinimleri

### ✅ GitHub Repository
**Ne:** Kodunuzun tutulduğu repository  
**Neden Gerekli:** Version control ve GitHub Actions için  
**Nasıl Oluşturulur:**
1. GitHub'da "New repository" tıklayın
2. İsim verin
3. Public veya Private seçin
4. Initialize with README (opsiyonel)
5. Create repository

---

### ✅ GitHub Actions Etkinleştirme
**Ne:** CI/CD pipeline'ınızın çalıştığı yer  
**Neden Gerekli:** Otomatik build ve deploy için  
**Nasıl Etkinleştirilir:**

Repository'de otomatik aktiftir, sadece workflow dosyası eklemeniz yeterli:
- `.github/workflows/ci-cd.yml` dosyası oluşturun

---

### ✅ GitHub Secrets
**Ne:** Hassas bilgilerin güvenli saklanması  
**Neden Gerekli:** Şifreler, key'ler vb. için  
**Nasıl Eklenir:**

1. GitHub repository > Settings
2. Secrets and variables > Actions
3. "New repository secret" tıklayın
4. Name ve Value girin
5. Add secret

**Tüm Secret'lar Listesi:**

#### Android Secrets:
```
ANDROID_KEYSTORE_BASE64
ANDROID_KEYSTORE_PASSWORD
ANDROID_KEY_PASSWORD
ANDROID_KEY_ALIAS
GOOGLE_PLAY_SERVICE_ACCOUNT
```

#### iOS Secrets:
```
IOS_CERTIFICATE_BASE64
IOS_CERTIFICATE_PASSWORD
IOS_PROVISION_PROFILE_BASE64
APP_STORE_CONNECT_API_KEY
APP_STORE_CONNECT_ISSUER_ID
APP_STORE_CONNECT_KEY_ID
IOS_TEAM_ID
```

#### Firebase Secrets:
```
FIREBASE_SERVICE_ACCOUNT
FIREBASE_ANDROID_APP_ID
FIREBASE_IOS_APP_ID
```

#### Opsiyonel Secrets:
```
CODECOV_TOKEN
SLACK_WEBHOOK
KEYCHAIN_PASSWORD
```

---

### ✅ Base64 Encoding Komutları
**Ne:** Binary dosyaları GitHub Secret'a dönüştürme  
**Neden Gerekli:** GitHub Secrets sadece text kabul eder  
**Nasıl Yapılır:**

#### Mac/Linux:
```bash
# Android Keystore
base64 -i upload-keystore.jks | pbcopy

# iOS Certificate
base64 -i distribution_certificate.p12 | pbcopy

# iOS Provisioning Profile
base64 -i distribution_profile.mobileprovision | pbcopy
```

#### Windows PowerShell:
```powershell
# Android Keystore
[Convert]::ToBase64String([IO.File]::ReadAllBytes("upload-keystore.jks")) | Set-Clipboard

# iOS Certificate
[Convert]::ToBase64String([IO.File]::ReadAllBytes("distribution_certificate.p12")) | Set-Clipboard

# iOS Provisioning Profile
[Convert]::ToBase64String([IO.File]::ReadAllBytes("distribution_profile.mobileprovision")) | Set-Clipboard
```

---

## 6. Kod Tarafı Düzenlemeler

### ✅ .gitignore Güncellemesi
**Ne:** Git'e commit edilmemesi gereken dosyalar  
**Neden Gerekli:** Güvenlik - hassas bilgilerin Git'e gitmesini engellemek  
**Eklenecekler:**

```gitignore
# Android
android/key.properties
android/app/keystore.jks
android/app/upload-keystore.jks

# iOS
ios/Runner/GoogleService-Info.plist
ios/Runner/ExportOptions.plist
*.mobileprovision
*.p12
*.cer

# Firebase
google-services.json

# Secrets
.env
.env.local
*.key
*.pem
```

---

### ✅ pubspec.yaml Version Management
**Ne:** Uygulama versiyonu  
**Neden Gerekli:** Her release için versiyon artırılmalı  
**Format:**
```yaml
version: 1.0.0+1
#        └─┬─┘ └┬┘
#          │    └── Build number (integer)
#          └─────── Version name (semantic versioning)
```

**CI/CD ile Otomatik:**
Workflow'da `--build-number=${{ github.run_number }}` kullanarak otomatik artırabilirsiniz

---

### ✅ Flutter Build Configuration
**Ne:** Build ayarları  
**Neden Gerekli:** Optimum build için  
**Yapılacaklar:**

#### android/app/build.gradle:
```gradle
android {
    defaultConfig {
        minSdkVersion 21  // Modern Android için
        targetSdkVersion 34  // En güncel API level
        versionCode flutterVersionCode.toInteger()
        versionName flutterVersionName
        multiDexEnabled true
    }
    
    buildTypes {
        release {
            minifyEnabled true
            shrinkResources true
            signingConfig signingConfigs.release
        }
    }
}
```

#### ios/Runner.xcodeproj:
Xcode'da Runner > Build Settings:
- Enable Bitcode: NO
- Optimize for Speed: YES
- Strip Debug Symbols: YES (Release için)

---

### ✅ Platform-Specific Configurations
**Ne:** Her platform için özel ayarlar  
**Neden Gerekli:** Store gereksinimleri  

#### Android:
- `android/app/src/main/AndroidManifest.xml`: Permissions
- `android/app/src/main/res`: Icons, launcher

#### iOS:
- `ios/Runner/Info.plist`: Permissions, configurations
- `ios/Runner/Assets.xcassets`: Icons, launch screens

---

## 7. İsteğe Bağlı Ama Önerilen

### ⭐ Crashlytics/Sentry
**Ne:** Crash reporting  
**Neden Önerilen:** Production'daki hataları takip etmek için  
**Alternatifler:**
- Firebase Crashlytics (ücretsiz)
- Sentry (ücretsiz tier var)

---

### ⭐ Analytics
**Ne:** Kullanıcı davranışlarını takip  
**Neden Önerilen:** Ürün geliştirme kararları için  
**Alternatifler:**
- Firebase Analytics (ücretsiz)
- Mixpanel (ücretsiz tier)
- Amplitude (ücretsiz tier)

---

### ⭐ Slack/Discord Webhook
**Ne:** Build notification'ları  
**Neden Önerilen:** Build durumunu takip etmek için  
**Nasıl Kurulur:**

Slack:
1. Slack workspace > Apps > Incoming Webhooks
2. Add to Slack
3. Channel seç
4. Webhook URL'i kopyala
5. GitHub Secret'a ekle: `SLACK_WEBHOOK`

---

### ⭐ Status Badge
**Ne:** README'de build status göstergesi  
**Neden Önerilen:** Profesyonel görünüm  
**Nasıl Eklenir:**

README.md'ye:
```markdown
![CI/CD](https://github.com/username/repo/workflows/Flutter%20CI%2FCD%20Pipeline/badge.svg)
```

---

## 8. Toplam Maliyet Hesabı

### Zorunlu Maliyetler:
| İtem | Maliyet | Periyot |
|------|---------|---------|
| Google Play Console | $25 | Bir kerelik |
| Apple Developer Program | $99 | Yıllık |
| **TOPLAM** | **$124** | **İlk Yıl** |
| **TOPLAM** | **$99** | **Sonraki Yıllar** |

### İsteğe Bağlı (Önerilen):
| İtem | Maliyet | Notlar |
|------|---------|--------|
| Firebase (Spark Plan) | Ücretsiz | App Distribution için yeterli |
| GitHub (Public Repo) | Ücretsiz | Sınırsız Actions |
| GitHub (Private Repo) | $4/ay | 2000 dakika/ay Actions |
| Codecov | Ücretsiz | Public repo için |
| Domain (isteğe bağlı) | ~$10/yıl | Website için |

### GitHub Actions Kullanım Tahmini:
**Ortalama build süreleri:**
- Test job: ~5 dakika
- Android build: ~15 dakika
- iOS build: ~25 dakika
- **Toplam:** ~45 dakika per build

**Aylık tahmin:**
- Günde 2 build × 30 gün = 60 build
- 60 × 45 dakika = 2,700 dakika
- Private repo limit: 2,000 dakika (ücretsiz)
- **Sonuç:** Team plan gerekebilir ($4/ay)

---

## 📋 Hızlı Başlangıç Checklist

### 📅 Bugün Yapılacaklar (2-3 saat):
- [ ] Google Play Console hesabı aç ($25)
- [ ] Apple Developer hesabı aç ($99/yıl)
- [ ] Firebase projesi oluştur
- [ ] GitHub repository oluştur
- [ ] Android keystore oluştur
- [ ] Keystore bilgilerini güvenli yerde sakla

### 📅 Yarın Yapılacaklar (3-4 saat):
- [ ] iOS Certificate ve Provisioning Profile oluştur
- [ ] App Store Connect API key al
- [ ] Firebase'e Android ve iOS app ekle
- [ ] google-services.json ve GoogleService-Info.plist indir
- [ ] Tüm dosyaları güvenli yerde yedekle

### 📅 Bu Hafta Yapılacaklar (4-6 saat):
- [ ] GitHub Secrets'ları ekle (tüm base64'ler)
- [ ] Workflow dosyasını ekle
- [ ] İlk test build'i çalıştır
- [ ] Android build'i test et
- [ ] iOS build'i test et

### 📅 Gelecek Hafta Yapılacaklar (2-3 saat):
- [ ] Firebase Distribution test et
- [ ] Play Store internal track'e upload test et
- [ ] TestFlight'a upload test et
- [ ] Production deployment prosedürü belirle

---

## 🚨 Kritik Uyarılar

### ⚠️ KESİNLİKLE YAPMAYIN:
1. ❌ Keystore dosyasını Git'e commit etmeyin
2. ❌ key.properties dosyasını Git'e commit etmeyin
3. ❌ Şifreleri kod içinde yazmayın
4. ❌ .p12 ve .mobileprovision dosyalarını Git'e eklemeyin
5. ❌ Service account JSON'larını public yapmayin
6. ❌ API key'leri loglara yazdırmayın

### ✅ MUTLAKA YAPIN:
1. ✅ Tüm hassas dosyaları .gitignore'a ekleyin
2. ✅ Keystore ve şifreleri en az 3 yerde yedekleyin
3. ✅ Password manager kullanın (1Password, LastPass vb.)
4. ✅ İlk test'leri dev/develop branch'inde yapın
5. ✅ Production deploy'dan önce internal test yapın
6. ✅ Sertifikaların expiry date'lerini takip edin

---

## 🎯 Özet: En Önemli 10 Şey

1. **Google Play Console hesabı** ($25) ✅
2. **Apple Developer hesabı** ($99/yıl) ✅
3. **Android Keystore** + şifreleri ✅
4. **iOS Certificate (.p12)** + şifre ✅
5. **iOS Provisioning Profile** (.mobileprovision) ✅
6. **App Store Connect API Key** (.p8) ✅
7. **Firebase Service Account** (JSON) ✅
8. **Google Play Service Account** (JSON) ✅
9. **GitHub Secrets** (tüm yukarıdakiler base64) ✅
10. **.gitignore** (hassas dosyalar için) ✅

---

## 📞 Yardım Kaynakları

### Dokümantasyon:
- Flutter: https://docs.flutter.dev/
- GitHub Actions: https://docs.github.com/en/actions
- Firebase: https://firebase.google.com/docs
- Play Console: https://support.google.com/googleplay/android-developer
- App Store Connect: https://developer.apple.com/app-store-connect/

### Topluluk:
- Flutter Discord: https://discord.gg/flutter
- Stack Overflow: `[flutter]` tag
- GitHub Discussions: flutter/flutter

### Hatalar için:
- Flutter Issues: https://github.com/flutter/flutter/issues
- GitHub Actions Community: https://github.community/

---


Bu checklist'i takip ederek eksiksiz bir CI/CD altyapısı kurabilirsiniz! Her maddeyi tamamladıkça işaretleyin. 🚀

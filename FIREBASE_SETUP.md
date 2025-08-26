# Firebase Setup Instructions for Flutter Task Manager

Bu dosya Firebase'i Flutter Task Manager uygulamanızda kurmanız için gerekli adımları içerir.

## Adım 1: Firebase Projesi Oluşturma

1. [Firebase Console](https://console.firebase.google.com/) adresine gidin
2. "Create a project" butonuna tıklayın
3. Proje adını girin (örneğin: "task-manager-app")
4. Google Analytics'i etkinleştirin (isteğe bağlı)
5. Projeyi oluşturun

## Adım 2: Firestore Database Kurulumu

1. Firebase Console'da sol menüden "Firestore Database" seçin
2. "Create database" butonuna tıklayın
3. "Start in test mode" seçin (geliştirme için)
4. Location seçin (Europe-west3 önerilir)

## Adım 3: Flutter Uygulamasını Firebase'e Bağlama

### Windows için:
1. Terminalde şu komutu çalıştırın:
   ```
   flutterfire configure
   ```
2. Google hesabınızla giriş yapın
3. Oluşturduğunuz Firebase projesini seçin
4. Platform seçimi yapın (Android, iOS, Web, Windows)

### Manuel kurulum (flutterfire CLI çalışmazsa):

1. Firebase Console'da "Project Settings" > "General" sekmesine gidin
2. Her platform için uygulamanızı ekleyin:

#### Android için:
- "Add app" > Android simgesini tıklayın
- Package name: `com.example.flutter_application_1`
- google-services.json dosyasını indirin
- Bu dosyayı `android/app/` klasörüne koyun

#### iOS için:
- "Add app" > iOS simgesini tıklayın
- Bundle ID: `com.example.flutterApplication1`
- GoogleService-Info.plist dosyasını indirin
- Bu dosyayı `ios/Runner/` klasörüne koyun

#### Web için:
- "Add app" > Web simgesini tıklayın
- App nickname: "Task Manager Web"
- Config bilgilerini kopyalayın ve `lib/firebase_options.dart` dosyasındaki web bölümünü güncelleyin

## Adım 4: firebase_options.dart Güncelleme

`lib/firebase_options.dart` dosyasındaki placeholder değerleri gerçek Firebase config değerleriyle değiştirin:

- YOUR_PROJECT_ID: Firebase proje ID'niz
- YOUR_API_KEY: Her platform için API key
- YOUR_APP_ID: Her platform için App ID
- YOUR_MESSAGING_SENDER_ID: Messaging Sender ID

## Adım 5: Test Etme

1. Uygulamayı çalıştırın:
   ```
   flutter run
   ```

2. Görev eklemeyi deneyin
3. Firebase Console > Firestore Database'de verileri kontrol edin

## Güvenlik Kuralları (Üretim için)

Firestore Database > Rules sekmesinde şu kuralları kullanabilirsiniz:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Herkes okuyabilir ve yazabilir (demo için)
    match /{document=**} {
      allow read, write: if true;
    }
    
    // Güvenli versiyon (kimlik doğrulama gerekli)
    // match /tasks/{taskId} {
    //   allow read, write: if request.auth != null && request.auth.uid == resource.data.userId;
    // }
  }
}
```

## Sorun Giderme

### FlutterFire CLI kurulumu:
```bash
dart pub global activate flutterfire_cli
```

### Bağımlılıkları yükleme:
```bash
flutter pub get
```

### Clean build:
```bash
flutter clean
flutter pub get
```

## Ek Özellikler

- **Authentication**: Kullanıcı girişi için firebase_auth kullanılabilir
- **Storage**: Dosya yükleme için firebase_storage eklenebilir
- **Push Notifications**: firebase_messaging ile bildirimler gönderilebilir

Firebase kurulumu tamamlandığında uygulamanız bulut veritabanı ile çalışmaya başlayacaktır!

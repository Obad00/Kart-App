# Guide de Configuration - KART App

Ce document décrit les étapes de configuration nécessaires pour les fonctionnalités Google OAuth, Paiement Bictorys et Scanner OCR.

---

## 1. Google OAuth - Configuration

### Prérequis

1. Créer un projet dans la [Google Cloud Console](https://console.cloud.google.com/)
2. Activer l'API "Google Sign-In"
3. Configurer l'écran de consentement OAuth

### Configuration iOS

#### 1.1 Obtenir le Client ID iOS

1. Dans Google Cloud Console, aller dans **APIs & Services > Credentials**
2. Créer un **OAuth 2.0 Client ID** de type **iOS**
3. Renseigner le **Bundle ID** (ex: `com.kartapp.app`)
4. Copier le **Client ID** généré

#### 1.2 Configurer Info.plist

Ouvrir `ios/Runner/Info.plist` et ajouter :

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- ... autres configurations ... -->

    <!-- Google Sign-In -->
    <key>CFBundleURLTypes</key>
    <array>
        <dict>
            <key>CFBundleTypeRole</key>
            <string>Editor</string>
            <key>CFBundleURLSchemes</key>
            <array>
                <!-- Remplacer par votre Client ID inversé -->
                <string>com.googleusercontent.apps.XXXXX-YYYYY</string>
            </array>
        </dict>
    </array>

    <key>GIDClientID</key>
    <string>XXXXX-YYYYY.apps.googleusercontent.com</string>

    <!-- Permissions caméra pour le scanner -->
    <key>NSCameraUsageDescription</key>
    <string>KART a besoin d'accéder à la caméra pour scanner les cartes de visite</string>

    <key>NSPhotoLibraryUsageDescription</key>
    <string>KART a besoin d'accéder à vos photos pour importer des cartes de visite</string>

</dict>
</plist>
```

#### 1.3 Configurer le URL Scheme

Le format du URL Scheme est l'inverse du Client ID :
- Client ID : `123456789-abcdef.apps.googleusercontent.com`
- URL Scheme : `com.googleusercontent.apps.123456789-abcdef`

---

### Configuration Android

#### 2.1 Obtenir le SHA-1 de l'application

```bash
# Debug SHA-1
cd android
./gradlew signingReport

# Ou avec keytool
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

#### 2.2 Créer le Client ID Android

1. Dans Google Cloud Console, aller dans **APIs & Services > Credentials**
2. Créer un **OAuth 2.0 Client ID** de type **Android**
3. Renseigner :
   - **Package name** : `com.kartapp.kart_app` (voir `android/app/build.gradle`)
   - **SHA-1 certificate fingerprint** : Le SHA-1 obtenu à l'étape précédente
4. Sauvegarder

#### 2.3 Configurer build.gradle

Ouvrir `android/app/build.gradle` et vérifier :

```gradle
android {
    namespace "com.kartapp.kart_app"

    defaultConfig {
        applicationId "com.kartapp.kart_app"
        minSdkVersion 21
        targetSdkVersion 34
        // ...
    }
}
```

#### 2.4 Permissions AndroidManifest.xml

Ouvrir `android/app/src/main/AndroidManifest.xml` :

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <!-- Permissions Internet -->
    <uses-permission android:name="android.permission.INTERNET"/>

    <!-- Permissions Caméra pour le scanner -->
    <uses-permission android:name="android.permission.CAMERA"/>
    <uses-feature android:name="android.hardware.camera" android:required="false"/>

    <!-- Permissions Stockage pour la galerie -->
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>

    <application
        android:label="KART"
        android:icon="@mipmap/ic_launcher"
        android:usesCleartextTraffic="true">

        <!-- ... activities ... -->

    </application>
</manifest>
```

---

## 2. Configuration de l'API Backend

### 2.1 Variables d'environnement

Modifier `lib/core/network/api_endpoints.dart` :

```dart
class ApiEndpoints {
  // Développement
  static const baseUrl = 'http://127.0.0.1:8000/api';

  // Production (décommenter pour la production)
  // static const baseUrl = 'https://api.kart.com/api';

  static const storageUrl = 'http://127.0.0.1:8000/storage';

  // ... endpoints
}
```

### 2.2 Configuration pour Android Emulator

Si vous utilisez un émulateur Android, remplacer `127.0.0.1` par `10.0.2.2` :

```dart
static const baseUrl = 'http://10.0.2.2:8000/api';
```

---

## 3. WebView pour Paiement Bictorys

### Configuration iOS

Ajouter dans `ios/Runner/Info.plist` :

```xml
<!-- Autoriser les connexions HTTP pour le développement -->
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

### Configuration Android

Dans `android/app/src/main/AndroidManifest.xml`, s'assurer que `usesCleartextTraffic` est activé pour le développement :

```xml
<application
    android:usesCleartextTraffic="true">
```

---

## 4. Récapitulatif des Routes

| Route | Description |
|-------|-------------|
| `/login` | Page de connexion (email + Google) |
| `/complete-profile` | Compléter le profil (nouveaux utilisateurs Google) |
| `/payment/plans` | Liste des plans d'abonnement |
| `/payment/methods` | Choix de la méthode de paiement |
| `/payment/processing` | WebView Bictorys |
| `/payment/result` | Résultat du paiement |
| `/card-scanner` | Scanner de cartes de visite |
| `/card-scanner/preview` | Aperçu de l'image |
| `/card-scanner/result` | Résultat du scan (formulaire éditable) |

---

## 5. Dépendances Installées

```yaml
dependencies:
  # Google Sign-In
  google_sign_in: ^6.2.1

  # WebView pour paiement
  webview_flutter: ^4.7.0

  # Image cropper pour le scanner
  image_cropper: ^5.0.1

  # Animations
  lottie: ^3.1.0

  # Déjà présents
  dio: ^5.4.0
  flutter_secure_storage: ^9.0.0
  image_picker: ^1.0.7
  url_launcher: ^6.2.5
  provider: ^6.1.2
```

---

## 6. Endpoints API Backend

### Authentification

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| POST | `/auth/login` | Connexion email/password |
| POST | `/auth/register` | Inscription |
| POST | `/auth/google/token` | Connexion Google OAuth |
| GET | `/me` | Profil utilisateur |
| POST | `/auth/logout` | Déconnexion |

### Paiements

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/plans` | Liste des plans |
| GET | `/payments/methods` | Méthodes de paiement |
| POST | `/payments/initialize` | Initialiser un paiement |
| GET | `/payments/{reference}/status` | Statut d'un paiement |
| GET | `/payments/history` | Historique des paiements |

### Scanner OCR

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| POST | `/scan-card` | Scanner une carte (multipart/form-data) |
| POST | `/contacts` | Enregistrer un contact |

---

## 7. Troubleshooting

### Google Sign-In ne fonctionne pas

1. Vérifier que le SHA-1 est correct dans Google Cloud Console
2. Vérifier que le package name correspond exactement
3. Régénérer les credentials si nécessaire

### WebView affiche une page blanche

1. Vérifier les permissions réseau
2. Activer `usesCleartextTraffic` pour le développement
3. Vérifier l'URL de paiement retournée par l'API

### Scanner ne détecte pas de texte

1. Vérifier la qualité de l'image
2. S'assurer que la carte est bien éclairée
3. Tester avec différentes cartes

---

### Configuration Web

#### 3.1 Créer le Client ID Web

1. Dans Google Cloud Console, aller dans **APIs & Services > Credentials**
2. Créer un **OAuth 2.0 Client ID** de type **Web application**
3. Ajouter les URI autorisés :
   - `http://localhost:3000` (développement)
   - `http://localhost:5000` (Flutter web dev)
   - `https://yourdomain.com` (production)
4. Copier le Client ID

#### 3.2 Configurer dans l'app

Dans `lib/features/auth/providers/auth_provider.dart` :

```dart
const String _kGoogleSignInClientId =
    String.fromEnvironment('GOOGLE_SIGN_IN_CLIENT_ID', defaultValue: '');

final GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: ['email', 'profile'],
  clientId: kIsWeb && _kGoogleSignInClientId.isNotEmpty
      ? _kGoogleSignInClientId
      : null,
);
```

#### 3.3 Lancer sur web avec la variable

```bash
# Flutter web avec client ID
flutter run -d chrome \
  --define GOOGLE_SIGN_IN_CLIENT_ID="YOUR_CLIENT_ID.apps.googleusercontent.com"
```

---

## 3. Configuration des Paiements

### 3.1 Stripe (Recommandé)

#### A. Créer un compte Stripe

1. S'inscrire sur [stripe.com](https://stripe.com)
2. Aller dans Dashboard → Developers → API Keys
3. Copier la **Publishable Key** et **Secret Key**

#### B. Configuration Backend (Laravel)

Dans `.env` du backend :

```env
STRIPE_PUBLIC_KEY=pk_test_xxxxx
STRIPE_SECRET_KEY=sk_test_xxxxx
```

#### C. Configuration Frontend

Dans `lib/core/network/api_endpoints.dart` :

```dart
class ApiEndpoints {
  static const paymentInitialize = '/payments/initialize';
  static const paymentStatus(String reference) => '/payments/$reference/status';
}
```

#### D. WebView pour paiement

Dans `lib/features/payment/ui/payment_processing_screen.dart` :

```dart
class PaymentProcessingScreen extends StatefulWidget {
  final String paymentUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Payment Processing')),
      body: WebViewWidget(
        controller: WebViewController()
          ..loadRequest(Uri.parse(paymentUrl)),
      ),
    );
  }
}
```

### 3.2 PayPal (Alternatif)

#### A. Créer un compte PayPal

1. S'inscrire sur [developer.paypal.com](https://developer.paypal.com)
2. Créer une application
3. Copier les credentials

#### B. Configuration Backend

```env
PAYPAL_CLIENT_ID=xxxxx
PAYPAL_SECRET=xxxxx
```

---

## 4. Configuration du Scanner de Cartes

### 4.1 Mobile Scanner (QR Code)

#### A. Installation

```bash
flutter pub add mobile_scanner
```

#### B. Configuration iOS

Dans `ios/Podfile` :

```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
        '$(inherited)',
        'PERMISSION_CAMERA=1',
      ]
    end
  end
end
```

#### C. Configuration Android

Dans `android/app/build.gradle` :

```gradle
dependencies {
  implementation 'androidx.core:core:1.6.0'
}
```

### 4.2 Camera + OCR (Business Card Scan)

#### A. Dépendances

```bash
flutter pub add camera
flutter pub add image_picker
flutter pub add image_cropper
```

#### B. Configuration iOS

Dans `ios/Runner/Info.plist` :

```xml
<key>NSCameraUsageDescription</key>
<string>KART a besoin d'accéder à la caméra pour scanner les cartes</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>KART a besoin d'accéder à vos photos pour importer une carte</string>
```

#### C. Configuration Android

Dans `android/app/src/main/AndroidManifest.xml` :

```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>

<uses-feature android:name="android.hardware.camera" android:required="false"/>
```

### 4.3 API Backend pour OCR

L'endpoint `/card-scan` doit accepter une image et retourner les données extraites :

```
POST /card-scan
Content-Type: multipart/form-data

Form data:
- image: <file>
- auto_extract: true

Response:
{
  "success": true,
  "extracted_data": {
    "fullname": "Marie Martin",
    "email": "marie@example.com",
    "phone": "+33612345678",
    "company": "Tech Corp",
    "job": "Manager"
  },
  "confidence_score": 0.85
}
```

---

## 5. Configuration Firebase (Optionnel)

### 5.1 Authentication avec Firebase

#### A. Créer un projet Firebase

1. Aller sur [console.firebase.google.com](https://console.firebase.google.com)
2. Créer un nouveau projet
3. Activer Authentication

#### B. Configuration iOS

Télécharger `GoogleService-Info.plist` dans Firebase Console :
- Placer dans `ios/Runner/`
- Configurer Xcode

#### C. Configuration Android

Télécharger `google-services.json` :
- Placer dans `android/app/`

### 5.2 Cloud Messaging (Notifications)

```bash
flutter pub add firebase_messaging
```

Configuration :
- Activer Cloud Messaging dans Firebase Console
- Récupérer les tokens d'appareils
- Envoyer les notifications via le backend

---

## 6. Configuration des Variables d'Environnement

### 6.1 Fichier `.env` (développement)

Créer `.env` à la racine du projet :

```env
# API
API_BASE_URL=http://localhost:8000/api
API_STORAGE_URL=http://localhost:8000/storage

# Google OAuth
GOOGLE_SIGN_IN_CLIENT_ID=YOUR_CLIENT_ID.apps.googleusercontent.com
GOOGLE_SIGN_IN_WEB_CLIENT_ID=YOUR_WEB_CLIENT_ID.apps.googleusercontent.com

# Paiements
STRIPE_PUBLIC_KEY=pk_test_xxxxx
PAYPAL_CLIENT_ID=xxxxx

# Firebase (optionnel)
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_API_KEY=xxxxx
```

### 6.2 Charger les variables

Dans `lib/main.dart` :

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  await dotenv.load(fileName: '.env');
  runApp(const KartApp());
}
```

### 6.3 Accéder aux variables

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

final apiUrl = dotenv.env['API_BASE_URL']!;
final googleClientId = dotenv.env['GOOGLE_SIGN_IN_CLIENT_ID']!;
```

---

## 7. Installation du Backend Local

### 7.1 Prérequis

```bash
# macOS
brew install php composer mysql

# Linux (Ubuntu)
sudo apt install php composer mysql-server

# Windows
# Télécharger XAMPP ou Laragon
```

### 7.2 Clone et configuration

```bash
# Clone backend
git clone https://github.com/your-org/kart-backend.git
cd kart-backend

# Installer les dépendances
composer install

# Créer le fichier .env
cp .env.example .env

# Générer la clé d'application
php artisan key:generate

# Créer la base de données
php artisan migrate --seed

# Démarrer le serveur
php artisan serve
```

### 7.3 Fichier `.env` backend

```env
APP_NAME="KART API"
APP_URL=http://localhost:8000

DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=kart_db
DB_USERNAME=root
DB_PASSWORD=

MAIL_DRIVER=mailgun
MAILGUN_DOMAIN=your-domain.com
MAILGUN_SECRET=your-secret

STRIPE_PUBLIC_KEY=pk_test_xxxxx
STRIPE_SECRET_KEY=sk_test_xxxxx
```

---

## 8. Vérification du Setup

### 8.1 Checklist de configuration

```bash
# 1. Vérifier Flutter
flutter doctor

# 2. Vérifier les dépendances
flutter pub get

# 3. Vérifier Android
cd android && ./gradlew signingReport

# 4. Vérifier iOS
cd ios && pod install

# 5. Vérifier la connexion à l'API
curl http://localhost:8000/api/health

# 6. Vérifier Google OAuth
# - Essayer de se connecter avec Google
```

### 8.2 Test de la configuration

```bash
# Lancer l'app
flutter run

# Tester la connexion
# 1. Appuyer sur "Se connecter"
# 2. Entrer email/password
# 3. Si succès → vérifier les logs

# Tester Google Sign-In
# 1. Appuyer sur "Sign in with Google"
# 2. Sélectionner le compte Google
# 3. Si succès → app ouvre HomeShell

# Tester la caméra
# 1. Aller à l'onglet "Scanner"
# 2. Appuyer sur "Capturer une carte"
# 3. Prendre une photo d'une vraie carte
```

---

## 9. Commandes Utiles

### 9.1 Développement

```bash
# Nettoyer et reconstruire
flutter clean
flutter pub get

# Lancer en debug
flutter run

# Lancer sur un device spécifique
flutter run -d emulator-5554

# Lancer sur iOS
flutter run -d iphone

# Lancer sur web
flutter run -d chrome

# Lancer en mode profile (performance)
flutter run --profile

# Voir les logs
flutter logs

# Rebuild quand un fichier change
flutter run --watch
```

### 9.2 Débogage

```bash
# Ouvrir DevTools
flutter pub global run devtools

# Profiler les performances
flutter run --profile

# Analyser le code
flutter analyze

# Formater le code
dart format lib/

# Linter Dart
flutter pub run flutter_lints
```

### 9.3 Build

```bash
# Build APK (debug)
flutter build apk --debug

# Build APK (release)
flutter build apk --release

# Build AppBundle
flutter build appbundle --release

# Build iOS
flutter build ios --release

# Build web
flutter build web --release
```

---

## 10. Troubleshooting Courants

### 10.1 Google Sign-In ne fonctionne pas

**Problème** : "Invalid client" error

**Solution** :
```bash
# 1. Vérifier le SHA-1 d'Android
cd android && ./gradlew signingReport

# 2. Ajouter le SHA-1 à Google Cloud Console
# 3. Régénérer les credentials

# 4. Redémarrer l'app
flutter clean && flutter run
```

### 10.2 Connexion API échoue

**Problème** : "Connection refused"

**Solution** :
```bash
# 1. Vérifier que le backend est en cours d'exécution
php artisan serve

# 2. Vérifier l'URL dans api_endpoints.dart
# 3. Si sur émulateur Android, utiliser 10.0.2.2 au lieu de 127.0.0.1

# 4. Vérifier les logs du backend
tail -f storage/logs/laravel.log
```

### 10.3 Permissions manquantes Android

**Problème** : App crash lors du scan

**Solution** :
```xml
<!-- Ajouter à AndroidManifest.xml -->
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.INTERNET"/>
```

### 10.4 Erreur "usesCleartextTraffic"

**Problème** : WebView n'ouvre pas les URLs HTTP

**Solution** :
```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<application android:usesCleartextTraffic="true">
```

---

## 11. Architecture du Setup

```
Frontend (Flutter)
├── local config
│   ├── pubspec.yaml (dépendances)
│   ├── .env (variables)
│   └── firebase config (optionnel)
└── connects to →

Backend (Laravel)
├── .env config
│   ├── Database (MySQL)
│   ├── API keys (Stripe, etc)
│   └── OAuth secrets
└── provides API to Frontend

External Services
├── Google Cloud (OAuth)
├── Stripe/PayPal (Paiements)
├── Firebase (Notifications)
└── Mobile scanners (Camera)
```

---

## 12. Support des Environnements

### 12.1 Développement

```bash
# Terminal 1: Backend
cd backend && php artisan serve

# Terminal 2: Frontend
cd kart_app && flutter run
```

### 12.2 Staging (sur serveur)

```bash
# Backend: https://staging-api.kart.com
# Frontend: flutter run --release avec API staging
```

### 12.3 Production

```bash
# Backend: https://api.kart.com
# Frontend: Play Store / App Store

# Vérifier:
# - usesCleartextTraffic disabled
# - HTTPS enforced
# - Secrets not in code
```

---

## 13. Production Checklist

- [ ] Backend déployé et testé
- [ ] Google OAuth Client IDs configurés (dev + prod)
- [ ] Stripe/PayPal intégré et testé
- [ ] Camera permissions bien configurées
- [ ] Variables d'environnement définies
- [ ] SecureStorage configuré pour tokens
- [ ] HTTPS enforced
- [ ] usesCleartextTraffic disabled pour production
- [ ] SHA-1 de release ajouté à Google Cloud
- [ ] Notifications push testées (Firebase)
- [ ] WebView SSL configured
- [ ] App icon et splash screen finalisés
- [ ] Release notes écrites
- [ ] Build APK/AAB testés sur device réel
- [ ] Store listings complétés
- [ ] Privacy policy et Terms of Service en place
- [ ] Analytics configurés
- [ ] Crash reporting configuré
- [ ] Rollout strategy définie
- [ ] Emergency rollback plan en place

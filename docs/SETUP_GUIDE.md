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
3. Renseigner le **Bundle ID** (ex: `com.example.kartapp`)
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
   - **Package name** : `com.example.kart_app` (voir `android/app/build.gradle`)
   - **SHA-1 certificate fingerprint** : Le SHA-1 obtenu à l'étape précédente
4. Sauvegarder

#### 2.3 Configurer build.gradle

Ouvrir `android/app/build.gradle` et vérifier :

```gradle
android {
    namespace "com.example.kart_app"

    defaultConfig {
        applicationId "com.example.kart_app"
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

## 8. Production Checklist

- [ ] Remplacer `baseUrl` par l'URL de production
- [ ] Créer des Client IDs de production (Google)
- [ ] Désactiver `usesCleartextTraffic`
- [ ] Configurer les SHA-1 de release pour Android
- [ ] Tester le flow complet de paiement
- [ ] Tester Google Sign-In sur device réel

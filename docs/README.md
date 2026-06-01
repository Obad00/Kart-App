# 📱 KART - Application Mobile de Carte Digitale Intelligente

**Version:** 1.0.0  
**Framework:** Flutter  
**État Maintenance:** Active  
**Dernière mise à jour:** Mai 2026

---

## 🎯 Vue d'ensemble

**KART** est une application mobile Flutter innovante permettant aux professionnels de créer, gérer et partager des **cartes de visite digitales intelligentes**. L'application résout le problème des cartes de visite papier traditionnelles en offrant une solution digitale, interactive et facilement partageable.

### 🎓 Problématique résolue

- ❌ **Avant** : Cartes papier encombrantes, statiques, difficiles à mettre à jour
- ✅ **Après** : Carte digitale dynamique, partageable par QR code, synchronisée en temps réel

### 🌟 Valeur ajoutée principale

1. **Carte digitale personnalisée** - Design professionnels avec thèmes customisables
2. **Partage instantané** - QR code généré automatiquement
3. **Analytics** - Suivi des scans et partages
4. **Gestion des contacts** - Sauvegarde automatique des contacts scannés
5. **Plans d'abonnement** - Modèle freemium pour la monétisation
6. **Intégration d'entreprise** - Support des équipes et organisations

---

## 📋 Fonctionnalités principales

### 🔐 Authentification & Gestion des utilisateurs
- ✅ Inscription multi-étapes (3 pages)
- ✅ Connexion email/password
- ✅ Google Sign-In OAuth
- ✅ JWT avec refresh token automatique
- ✅ Gestion sécurisée des tokens (SecureStorage)
- ✅ Profil utilisateur complet

### 🎨 Carte Digitale Professionnelle
- ✅ Multiple thèmes de design pré-configurés
- ✅ QR code généré automatiquement
- ✅ Informations personnalisables (contact, réseaux sociaux)
- ✅ Support des expériences et formations
- ✅ Branding d'entreprise intégré
- ✅ Analytics: nombre de scans/partages
- ✅ URL publique unique pour partage

### 📱 Scan de cartes de visite
- ✅ Caméra intégrée pour capturer les cartes
- ✅ Recadrage automatique des images
- ✅ OCR pour extraction de données (reconnaissance texte)
- ✅ Sauvegarde automatique dans les contacts
- ✅ Aperçu et confirmation avant sauvegarde

### 👥 Gestion des contacts
- ✅ Liste des contacts scannés
- ✅ Groupement par entreprise/catégorie
- ✅ Recherche et filtrage
- ✅ Mise à jour des informations
- ✅ Partage des contacts
- ✅ Export CSV

### 💰 Paiements & Plans d'abonnement
- ✅ Système de plans (Free, Pro, Premium)
- ✅ Multiple méthodes de paiement
- ✅ Intégration webview pour paiements sécurisés
- ✅ Historique des paiements
- ✅ Renouvellement automatique
- ✅ Gestion des factures

### 🏢 Onboarding d'entreprise
- ✅ Création de nouvelles entreprises
- ✅ Rejoindre une équipe existante
- ✅ Gestion des membres d'équipe
- ✅ Branding personnalisé par entreprise
- ✅ Restrictions de plan (max utilisateurs)

### 📊 Leads & Analytics
- ✅ Tracking des contacts générés
- ✅ Historique des partages
- ✅ Statistiques d'engagement
- ✅ Filtrage par date/source

### 👤 Complétion de profil
- ✅ Ajout d'expériences professionnelles
- ✅ Ajout de formations/certifications
- ✅ Réseaux sociaux (LinkedIn, Twitter, Facebook, Instagram, GitHub)
- ✅ Champ de site web personnel
- ✅ Validation progressive

---

## 📊 Statistiques du projet

| Métrique | Valeur |
|----------|--------|
| **Nombre de features** | 9 principales |
| **Nombre de providers** | 11 (Provider pattern) |
| **Nombre d'écrans** | 20+ |
| **Dépendances** | 18 packages |
| **Taille de l'app** | ~80-120 MB (APK) |
| **Min API Level** | 21 (Android) |
| **iOS Support** | 12.0+ |

---

## 🎯 Public cible

- **Professionnels indépendants** (freelancers, consultants)
- **Représentants commerciaux** (sales team)
- **Entrepreneurs** et créateurs d'entreprise
- **Petites et moyennes entreprises** (PME)
- **Réseauteurs professionnels**
- **Recruteurs**

---

## 🏗️ Architecture globale

```
KART Application
├── Frontend Flutter (cette doc)
├── Backend Laravel REST API
├── Base de données (PostgreSQL)
└── Services externes (Google OAuth, Stripe/Paypal)
```

### Flux utilisateur principal

```
Splash Screen → Login/Register → Plans → Digital Card → Navigation Hub
                        ↓              ↓
                   Profile Setup   Onboarding
```

### Navigation globale

```
HomeShell (4 onglets)
├── 1. Digital Card (Ma Carte)
├── 2. Scan (Capturer/Voir cartes)
├── 3. Contacts (Mes contacts)
└── 4. Profile (Mon profil)
```

---

## 📦 Stack technologique

### Frontend (Flutter)
```yaml
- Flutter 3.x / Dart 3.x
- Material Design 3
- Provider (State Management)
- Dio (HTTP Client)
```

### Intégrations externes
```
- Google Sign-In (OAuth)
- Mobile Scanner (QR code)
- Firebase (notifications optionnelles)
- Stripe/Paypal (paiements)
```

### Stockage local
```
- flutter_secure_storage (tokens JWT)
- shared_preferences (prefs utilisateur)
- Image picker & cropper (médias)
```

### UI & UX
```
- Google Fonts (typographie)
- Lottie (animations)
- Image Cropper (édition)
- WebView (paiements)
```

---

## 📚 Documentation structure

Cette documentation est organisée en :

| Document | Contenu |
|----------|---------|
| **README.md** (vous êtes ici) | Vue d'ensemble, objectifs, features |
| **ARCHITECTURE.md** | Structure, patterns, design decisions |
| **API.md** | Documentation complète des endpoints |
| **AUTH.md** | Authentification, sécurité, JWT |
| **COMPONENTS.md** | Widgets, écrans, hiérarchie UI |
| **STATE_MANAGEMENT.md** | Providers, data flow, patterns |
| **PERFORMANCE.md** | Optimisations, best practices |
| **SECURITY.md** | Sécurité mobile, encryption, risques |
| **DEPLOYMENT.md** | Build, release, CI/CD |
| **MINDMAP.md** | Vue d'ensemble complète du projet |

---

## 🚀 Quick start développement

### Prérequis
```bash
flutter --version  # 3.x ou plus
dart --version     # 3.x ou plus
```

### Installation
```bash
cd /Users/m/Desktop/kart_app

# Télécharger les dépendances
flutter pub get

# Configuration des variables d'environnement
export GOOGLE_SIGN_IN_CLIENT_ID="your_client_id"
```

### Lancer l'app
```bash
# Mode debug
flutter run -d chrome  # Web
flutter run -d emulator-5554  # Android
flutter run -d "iPhone 15"  # iOS

# Mode release
flutter run --release
```

### Build
```bash
# Android
flutter build apk --release
flutter build appbundle --release

# iOS
flutter build ios --release
```

---

## 🔧 Configuration

### Backend API
L'endpoint API est configuré dans [lib/core/network/api_endpoints.dart](../lib/core/network/api_endpoints.dart) :

```dart
static const baseUrl = 'https://backend.kart.business/api';
static const storageUrl = 'https://backend.kart.business/storage';
```

### Google OAuth
Configuré dans [lib/features/auth/providers/auth_provider.dart](../lib/features/auth/providers/auth_provider.dart)

### Plans et paiements
Configurés dans `lib/features/payment/` et synchronisés via API

---

## 🧪 Tests

### Types de tests implémentés
- ✅ Widget tests (UI components)
- ✅ Unit tests (logic)
- ⏳ Integration tests (à configurer)

### Lancer les tests
```bash
flutter test

# Avec couverture
flutter test --coverage
```

---

## 🔐 Sécurité

### Mesures implémentées
- ✅ JWT tokens avec expiration
- ✅ Secure Storage (Keychain iOS / Keystore Android)
- ✅ HTTPS only
- ✅ Token refresh automatique
- ✅ Validation côté client

**Pour plus de détails** → [SECURITY.md](SECURITY.md)

---

## 🎨 Design System

### Couleurs principales
- **Dark Theme** : `#0A0A0A` (fond), `#F6F6F8` (texte clair)
- **Light Theme** : `#F8F9FA` (fond), `#1A1A2E` (texte)
- **Accent** : `#3B82F6` (bleu)

### Typography
- **Font** : Google Fonts - Syne
- **Tailles** : 12px → 28px (Material 3 standard)

### Spacing
- **Standard** : 8px, 12px, 16px, 24px, 32px
- **Border Radius** : 12px, 16px, 24px

### Animations
- **Durée standard** : 300-600ms
- **Courves** : `easeOutCubic`, `easeInOut`

---

## 📱 Support des plateformes

| Plateforme | Support | Min Version |
|-----------|---------|------------|
| Android | ✅ Complet | API 21 |
| iOS | ✅ Complet | 12.0 |
| Web | ⏳ Partiel | Chrome 90+ |
| Windows | ❌ Non | - |
| macOS | ❌ Non | - |
| Linux | ❌ Non | - |

---

## 📞 Support & Contribution

### Contacter le team
- 📧 Email: dev@kart.business
- 🐛 Issues: GitHub Issues
- 📋 Wiki: Documentation interne

### Guidelines de contribution
1. Créer une branche `feature/nom-feature`
2. Respecter le style de code (Dart conventions)
3. Ajouter des tests unitaires
4. Soumettre un Pull Request

---

## 📜 Licences

- **Code** : Propriétaire
- **Dépendances** : Voir `pubspec.yaml`
  - Provider: MIT
  - Dio: MIT
  - Flutter: BSD

---

## 🗺️ Roadmap

### V1.0 (actuellement)
- ✅ Authentification
- ✅ Carte digitale
- ✅ Scan de cartes
- ✅ Gestion contacts
- ✅ Paiements

### V1.1 (prochainement)
- 🔜 Partage social avancé
- 🔜 Notifications push
- 🔜 Analytics détaillées
- 🔜 Templates de cartes

### V2.0 (futur)
- 🔮 AR business card
- 🔮 Video card
- 🔮 AI profile auto-completion
- 🔮 Native app store publishing

---

## 📊 Métriques & Analytics

### Suivi de projet
```
Commits: 150+
Branches: 12+
Issues résolus: 95%
Test coverage: 65%
```

### Performances
- **Build time** : ~2-3 minutes
- **App size** : 85 MB (APK release)
- **Startup time** : <2 secondes
- **Frame rate** : 60 FPS (cible)

---

## 🎓 Documentation connexe

- **[Architecture détaillée →](ARCHITECTURE.md)**
- **[API Reference →](API.md)**
- **[Authentication →](AUTH.md)**
- **[Components →](COMPONENTS.md)**
- **[State Management →](STATE_MANAGEMENT.md)**
- **[Performance →](PERFORMANCE.md)**
- **[Security →](SECURITY.md)**
- **[Deployment →](DEPLOYMENT.md)**
- **[Mindmap →](MINDMAP.md)**

---

## ✅ Checklist pour onboarding développeurs

- [ ] Lire ce README
- [ ] Consulter ARCHITECTURE.md
- [ ] Cloner le repo et installer dépendances
- [ ] Lancer l'app en mode debug
- [ ] Consulter STATE_MANAGEMENT.md
- [ ] Consulter API.md pour intégrations backend
- [ ] Faire un premier test/fix
- [ ] Rejoindre Slack du team dev

---

**Dernière mise à jour** : 18 Mai 2026  
**Responsable** : Architecture Team  
**Status** : ✅ Documentation Complète

#!/bin/bash

set -e

PUBSPEC="pubspec.yaml"

# Lire la version Flutter
VERSION=$(grep '^version:' "$PUBSPEC" | awk '{print $2}')

if [[ ! "$VERSION" =~ ^([0-9]+\.[0-9]+\.[0-9]+)\+([0-9]+)$ ]]; then
    echo "❌ Format de version invalide : $VERSION"
    echo "Format attendu : 1.0.3+1"
    exit 1
fi

VERSION_NAME="${BASH_REMATCH[1]}"
VERSION_CODE="${BASH_REMATCH[2]}"

# Incrémenter automatiquement le versionCode
NEW_VERSION_CODE=$((VERSION_CODE + 1))

NEW_VERSION="${VERSION_NAME}+${NEW_VERSION_CODE}"

echo ""
echo "📱 Kart App"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Version actuelle : $VERSION"
echo "Nouvelle version : $NEW_VERSION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Modifier pubspec.yaml
sed -i "s/^version: .*/version: $NEW_VERSION/" "$PUBSPEC"

echo "✅ Version mise à jour : $NEW_VERSION"

# Nettoyage
echo "🧹 Nettoyage..."
flutter clean

# Dépendances
echo "📦 Installation des dépendances..."
flutter pub get

# Build signé
echo "🔐 Génération du AAB signé..."
flutter build appbundle --release

# Vérifier le fichier
AAB="build/app/outputs/bundle/release/app-release.aab"

if [ ! -f "$AAB" ]; then
    echo "❌ Le fichier AAB n'a pas été généré."
    exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ BUILD RÉUSSI"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📱 Version : $NEW_VERSION"
echo "🔢 Version code : $NEW_VERSION_CODE"
echo "📦 AAB : $AAB"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

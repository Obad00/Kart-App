#!/bin/bash
# Version commune iOS + Android, calculée à partir du COMMIT (et non du
# numéro d'exécution propre à chaque workflow) : deux builds du même commit
# portent exactement la même version sur les deux stores.
#
#   numéro de build = nombre de commits de la branche (git rev-list --count),
#                     strictement croissant d'un push à l'autre ;
#   version         = MAJOR.(MINOR + n / 100).(n % 100), MAJOR.MINOR lus
#                     dans pubspec.yaml (n = 469 → 1.4.69).
#
# Exige un checkout complet (actions/checkout avec fetch-depth: 0). Arrête le
# build si le numéro n'est pas supérieur au dernier publié : 220 (App Store
# 1.2.20) et, s'il est renseigné, ANDROID_LAST_VERSION_CODE (variable du
# dépôt, versionCode de la dernière version Play Store).
set -euo pipefail

LAST_IOS_BUILD=220

if [ "$(git rev-parse --is-shallow-repository)" = "true" ]; then
  echo "::error::Checkout superficiel : ajoutez fetch-depth: 0 à actions/checkout."
  exit 1
fi

BUILD_NUMBER=$(git rev-list --count HEAD)

FLOOR=$LAST_IOS_BUILD
if [ -n "${ANDROID_LAST_VERSION_CODE:-}" ] && [ "$ANDROID_LAST_VERSION_CODE" -gt "$FLOOR" ]; then
  FLOOR=$ANDROID_LAST_VERSION_CODE
fi
if [ "$BUILD_NUMBER" -le "$FLOOR" ]; then
  echo "::error::Numéro de build $BUILD_NUMBER non supérieur au dernier publié ($FLOOR). Build arrêté."
  exit 1
fi

BASE_VERSION=$(grep '^version:' pubspec.yaml | sed 's/version: *//' | cut -d'+' -f1)
BASE_MAJOR=$(echo "$BASE_VERSION" | cut -d'.' -f1)
BASE_MINOR=$(echo "$BASE_VERSION" | cut -d'.' -f2)
BUILD_NAME="${BASE_MAJOR}.$((BASE_MINOR + BUILD_NUMBER / 100)).$((BUILD_NUMBER % 100))"

echo "Commit $(git rev-parse --short HEAD) → version $BUILD_NAME ($BUILD_NUMBER)"
if [ -n "${GITHUB_ENV:-}" ]; then
  echo "BUILD_NAME=$BUILD_NAME" >> "$GITHUB_ENV"
  echo "BUILD_NUMBER=$BUILD_NUMBER" >> "$GITHUB_ENV"
fi

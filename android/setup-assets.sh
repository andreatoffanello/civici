#!/bin/bash
# setup-assets.sh — copia assets condivisi da iOS/data nella cartella Android
# Eseguire dalla root del progetto: bash android/setup-assets.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
ANDROID_ASSETS="$SCRIPT_DIR/app/src/main/assets"
ANDROID_FONTS="$SCRIPT_DIR/app/src/main/res/font"

mkdir -p "$ANDROID_ASSETS"
mkdir -p "$ANDROID_FONTS"

echo "→ Copia civici.json..."
cp "$ROOT_DIR/data/civici.json" "$ANDROID_ASSETS/civici.json"
echo "  ✓ $ANDROID_ASSETS/civici.json"

echo "→ Copia font nizioleti..."
cp "$ROOT_DIR/ios/DoVe/Resources/Fonts/CCXLKSNizioleti-Regular.ttf" "$ANDROID_FONTS/nizioleti_regular.ttf"
echo "  ✓ $ANDROID_FONTS/nizioleti_regular.ttf"

echo ""
echo "✓ Setup completato."
echo "  Ora apri android/ con Android Studio e fai Build → Make Project."

#!/bin/bash
# gera build/arkhe-adhd.app (app de mac que abre sem precisar do "love .")
# usa o LÖVE instalado em /Applications/love.app
# rodar na pasta do projeto: ./build_mac.sh

set -e

LOVE_APP="/Applications/love.app"
PASTA="$(cd "$(dirname "$0")" && pwd)"
BUILD="$PASTA/build"

# o app e montado numa pasta temporaria fora do iCloud,
# porque o iCloud coloca atributos nos arquivos que impedem a assinatura
TEMP="$(mktemp -d)"
APP="$TEMP/arkhe-adhd.app"
PLIST="$APP/Contents/Info.plist"

if [ ! -d "$LOVE_APP" ]; then
    echo "LÖVE não encontrado em $LOVE_APP"
    exit 1
fi

# 1. arkhe-adhd.love: zip so com os arquivos da gui, com main.lua na raiz
cd "$PASTA"
zip -9 -q "$TEMP/arkhe-adhd.love" main.lua conf.lua gui.lua functions.lua

# 2. copia o LÖVE e coloca o arkhe-adhd.love dentro dele
ditto "$LOVE_APP" "$APP"
cp "$TEMP/arkhe-adhd.love" "$APP/Contents/Resources/"

# 3. troca nome e identificador, e tira a associacao com arquivos .love
/usr/libexec/PlistBuddy -c "Set :CFBundleName arkhe-adhd" "$PLIST"
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier com.enzotucci.arkhe-adhd" "$PLIST"
/usr/libexec/PlistBuddy -c "Set :LSApplicationCategoryType public.app-category.productivity" "$PLIST"
/usr/libexec/PlistBuddy -c "Delete :UTExportedTypeDeclarations" "$PLIST"
/usr/libexec/PlistBuddy -c "Delete :CFBundleDocumentTypes" "$PLIST"

# 4. assinatura local (ad-hoc), para o mac aceitar o app modificado
xattr -cr "$APP" # tira atributos extras do mac, que impedem a assinatura
codesign --force --deep --sign - "$APP"

# 5. copia o resultado para build/
rm -rf "$BUILD"
mkdir -p "$BUILD"
ditto "$APP" "$BUILD/arkhe-adhd.app"
cp "$TEMP/arkhe-adhd.love" "$BUILD/"
rm -rf "$TEMP"

echo "Pronto: $BUILD/arkhe-adhd.app"

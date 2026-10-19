#!/bin/sh
# Zostaví Neposearch.app (menu bar aplikácia bez ikony v Docku).
#   --install  skopíruje ju do /Applications a spustí (odtiaľ sa spúšťa aj pri prihlásení)
#   --debug    ladiaca verzia
set -e
cd "$(dirname "$0")/.."
CONFIG=release
INSTALL=0
for arg in "$@"; do
    case "$arg" in
        --install) INSTALL=1 ;;
        --debug) CONFIG=debug ;;
        *) echo "Neznámy parameter: $arg" >&2; exit 1 ;;
    esac
done
swift build -c "$CONFIG"
BIN=.build/$CONFIG
APP=build/Neposearch.app

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Frameworks" "$APP/Contents/Resources"
# Ikona z icon.png – prepočíta sa len po jeho zmene
if [ ! -f build/AppIcon.icns ] || [ icon.png -nt build/AppIcon.icns ]; then
    swift scripts/make_icon.swift icon.png build/AppIcon.icns
fi
cp build/AppIcon.icns "$APP/Contents/Resources/"
cp "$BIN/Neposearch" "$APP/Contents/MacOS/"
cp -R "$BIN/ObjectBox.framework" "$APP/Contents/Frameworks/"
install_name_tool -add_rpath @executable_path/../Frameworks "$APP/Contents/MacOS/Neposearch" 2>/dev/null || true

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>Neposearch</string>
    <key>CFBundleIdentifier</key><string>dev.neposearch.app</string>
    <key>CFBundleExecutable</key><string>Neposearch</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleIconFile</key><string>AppIcon</string>
    <key>CFBundleShortVersionString</key><string>0.1.0</string>
    <key>CFBundleVersion</key><string>1</string>
    <key>LSMinimumSystemVersion</key><string>26.0</string>
    <key>LSUIElement</key><true/>
    <key>NSContactsUsageDescription</key><string>Neposearch prepája osoby a firmy z Kontaktov so súbormi a stretnutiami.</string>
    <key>NSCalendarsFullAccessUsageDescription</key><string>Neposearch zobrazuje stretnutia a prepája ich s osobami a súbormi.</string>
    <key>NSRemindersFullAccessUsageDescription</key><string>Neposearch zobrazuje nesplnené pripomienky v spúšťači.</string>
    <key>NSAppleEventsUsageDescription</key><string>Neposearch prepína karty prehliadača a vykonáva systémové príkazy (vysypať kôš, tmavý režim).</string>
    <key>CFBundleDevelopmentRegion</key><string>sk</string>
    <key>CFBundleLocalizations</key><array><string>sk</string><string>en</string></array>
</dict>
</plist>
PLIST

# Stabilný podpis (scripts/create_signing_cert.sh), aby macOS nežiadal povolenia po každom builde
if security find-identity -p codesigning 2>/dev/null | grep -q "Neposearch Dev"; then
    codesign --force --deep --sign "Neposearch Dev" "$APP"
else
    echo "Upozornenie: chýba certifikát „Neposearch Dev“ – podpisujem ad-hoc (spusti scripts/create_signing_cert.sh)"
    codesign --force --deep --sign - "$APP"
fi
echo "Hotovo: $APP"

if [ "$INSTALL" = 1 ]; then
    pkill -x Neposearch || true
    rm -rf /Applications/Neposearch.app
    cp -R "$APP" /Applications/
    open /Applications/Neposearch.app
    echo "Nainštalované do /Applications"
fi

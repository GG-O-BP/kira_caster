#!/usr/bin/env bash
# macOS .app 번들과 .dmg 이미지를 생성합니다.
# 사용법: ./scripts/build_macos_app.sh [release-dir]
# release-dir은 package_release.sh가 생성한 디렉토리 (예: kira_caster-macos-arm64)
set -e

RELEASE_DIR="${1:?사용법: $0 <release-dir>}"
APP_NAME="kira_caster"
APP_BUNDLE="${APP_NAME}.app"
DMG_NAME="${RELEASE_DIR}.dmg"

if [ ! -d "$RELEASE_DIR" ]; then
  echo "릴리스 디렉토리를 찾을 수 없습니다: $RELEASE_DIR"
  exit 1
fi

echo "=== macOS .app 번들 생성 ==="

# 1. .app 디렉토리 구조 생성
rm -rf "$APP_BUNDLE"
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

# 2. Info.plist 생성
cat > "${APP_BUNDLE}/Contents/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key>
  <string>kira_caster</string>
  <key>CFBundleDisplayName</key>
  <string>kira_caster</string>
  <key>CFBundleIdentifier</key>
  <string>com.kiracaster.app</string>
  <key>CFBundleVersion</key>
  <string>1.0</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleExecutable</key>
  <string>launcher</string>
  <key>LSMinimumSystemVersion</key>
  <string>12.0</string>
</dict>
</plist>
PLIST

# 3. 릴리스 파일을 Resources로 복사
cp -r "${RELEASE_DIR}/"* "${APP_BUNDLE}/Contents/Resources/"

# 4. 런처 스크립트 생성
cat > "${APP_BUNDLE}/Contents/MacOS/launcher" << 'LAUNCHER'
#!/usr/bin/env bash
RESOURCES="$(cd "$(dirname "$0")/../Resources" && pwd)"
cd "$RESOURCES"
exec ./start.sh
LAUNCHER
chmod +x "${APP_BUNDLE}/Contents/MacOS/launcher"

# 5. .dmg 생성 (macOS에서만)
if command -v hdiutil &>/dev/null; then
  echo ".dmg 생성 중..."
  rm -f "$DMG_NAME"
  hdiutil create -volname "$APP_NAME" -srcfolder "$APP_BUNDLE" \
    -ov -format UDZO "$DMG_NAME"
  echo "DMG 생성 완료: $DMG_NAME"
else
  echo "hdiutil을 사용할 수 없습니다 (macOS가 아닌 환경). .app 번들만 생성합니다."
  tar czf "${RELEASE_DIR}-app.tar.gz" "$APP_BUNDLE"
  echo ".app 번들: ${RELEASE_DIR}-app.tar.gz"
fi

# 정리
rm -rf "$APP_BUNDLE"
echo "=== macOS 패키징 완료 ==="

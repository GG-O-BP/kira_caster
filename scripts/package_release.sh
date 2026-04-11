#!/usr/bin/env bash
# BEAM 파일만 번들 — 시스템 Erlang 사용 (크로스 플랫폼 호환)
# 사용법: ./scripts/package_release.sh [target-name]
set -e

TARGET="${1:-$(uname -s)-$(uname -m)}"
RELEASE_DIR="kira_caster-${TARGET}"

echo "=== kira_caster 릴리스 패키징 ==="
echo "Target: ${TARGET}"

# 1. Gleam shipment 확인
if [ ! -d "build/erlang-shipment" ]; then
  echo "빌드 디렉토리가 없습니다. gleam export erlang-shipment을 먼저 실행하세요."
  exit 1
fi

# 2. 릴리스 디렉토리 구성
rm -rf "$RELEASE_DIR"
mkdir -p "${RELEASE_DIR}/erlang"

# 3. 앱 BEAM 파일 복사 (entrypoint 스크립트 제외)
cp -r build/erlang-shipment/* "${RELEASE_DIR}/erlang/"
mv "${RELEASE_DIR}/erlang/entrypoint.sh"  "${RELEASE_DIR}/" 2>/dev/null || true
mv "${RELEASE_DIR}/erlang/entrypoint.ps1" "${RELEASE_DIR}/" 2>/dev/null || true

# 4. 설정 파일 복사
cp gleam.toml "${RELEASE_DIR}/"
cp .env.example "${RELEASE_DIR}/"

if [ -f "scripts/kira-caster.desktop" ]; then
  cp scripts/kira-caster.desktop "${RELEASE_DIR}/"
fi

# 5. Linux/macOS 시작 스크립트
cat > "${RELEASE_DIR}/start.sh" << 'LAUNCHER'
#!/usr/bin/env bash
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# .env 로드
if [ -f .env ]; then
  set -a; source .env; set +a
fi

PORT="${KIRA_ADMIN_PORT:-9693}"

# Erlang 설치 확인
if ! command -v erl &>/dev/null; then
  echo "오류: Erlang/OTP가 설치되어 있지 않습니다."
  echo ""
  echo "설치 방법:"
  echo "  Linux (apt):  sudo apt install erlang"
  echo "  Linux (dnf):  sudo dnf install erlang"
  echo "  macOS:        brew install erlang"
  echo "  공식 다운로드: https://www.erlang.org/downloads"
  exit 1
fi

# 포트 사용 중 확인
if command -v ss &>/dev/null; then
  if ss -tlnp 2>/dev/null | grep -q ":$PORT "; then
    echo "오류: 포트 $PORT이(가) 이미 사용 중입니다."
    echo ".env 파일에서 KIRA_ADMIN_PORT를 다른 값으로 바꿔주세요."
    exit 1
  fi
fi

echo "kira_caster 시작 중... http://localhost:$PORT"

if command -v xdg-open &>/dev/null; then
  (sleep 2 && xdg-open "http://localhost:$PORT") &
elif command -v open &>/dev/null; then
  (sleep 2 && open "http://localhost:$PORT") &
fi

exec erl \
  -pa erlang/*/ebin \
  -noshell \
  -eval "kira_caster@@main:run(kira_caster)"
LAUNCHER
chmod +x "${RELEASE_DIR}/start.sh"

# 6. Windows 시작 스크립트
cat > "${RELEASE_DIR}/start.bat" << 'BATCH'
@echo off
chcp 65001 >nul
cd /d "%~dp0"
if exist .env (for /f "usebackq tokens=1,* delims==" %%a in (".env") do set "%%a=%%b")
if not defined KIRA_ADMIN_PORT set KIRA_ADMIN_PORT=9693
where erl >nul 2>&1
if errorlevel 1 (
  echo 오류: Erlang/OTP가 설치되어 있지 않습니다.
  echo 설치: https://www.erlang.org/downloads
  pause
  exit /b 1
)
echo kira_caster 시작 중... http://localhost:%KIRA_ADMIN_PORT%
start "" "http://localhost:%KIRA_ADMIN_PORT%"
erl -pa erlang/*/ebin -noshell -eval "kira_caster@@main:run(kira_caster)"
BATCH

# 7. 패키징
tar czf "kira_caster-${TARGET}.tar.gz" "$RELEASE_DIR"
echo ""
echo "=== 패키징 완료 ==="
echo "파일: kira_caster-${TARGET}.tar.gz"
echo "크기: $(du -sh "kira_caster-${TARGET}.tar.gz" | cut -f1)"

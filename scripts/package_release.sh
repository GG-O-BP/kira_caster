#!/usr/bin/env bash
# ERTS + OTP 완전 번들 — 별도 설치 불필요
# CI는 반드시 ubuntu-22.04에서 빌드 (OpenSSL 3.0.x 고정)
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

# 2. Erlang 경로 탐지
ERL_ROOT=$(erl -noshell -eval 'io:format("~s",[code:root_dir()])' -s init stop)
ERTS_DIR=$(ls -d "${ERL_ROOT}"/erts-* 2>/dev/null | head -1)
ERTS_VERSION=$(basename "$ERTS_DIR")

if [ -z "$ERTS_DIR" ] || [ ! -d "$ERTS_DIR" ]; then
  echo "Erlang ERTS를 찾을 수 없습니다."
  exit 1
fi

echo "Erlang root: ${ERL_ROOT}"
echo "ERTS: ${ERTS_VERSION}"

# 3. 릴리스 디렉토리 구성
rm -rf "$RELEASE_DIR"
mkdir -p "${RELEASE_DIR}/${ERTS_VERSION}/bin"
mkdir -p "${RELEASE_DIR}/bin"
mkdir -p "${RELEASE_DIR}/lib"
mkdir -p "${RELEASE_DIR}/erlang"

# 4. ERTS 바이너리 복사
cp -r "${ERTS_DIR}/bin/"* "${RELEASE_DIR}/${ERTS_VERSION}/bin/"

# 5. OTP boot 파일 복사
cp "${ERL_ROOT}/bin/"*.boot "${RELEASE_DIR}/bin/" 2>/dev/null || true

# 6. OTP 라이브러리 전체 복사
cp -r "${ERL_ROOT}/lib/"* "${RELEASE_DIR}/lib/"

# 7. 앱 BEAM 파일 복사
cp -r build/erlang-shipment/* "${RELEASE_DIR}/erlang/"
mv "${RELEASE_DIR}/erlang/entrypoint.sh"  "${RELEASE_DIR}/" 2>/dev/null || true
rm -f "${RELEASE_DIR}/erlang/entrypoint.ps1" 2>/dev/null || true

# 7.1. entrypoint.ps1 재생성 (번들 ERTS 사용)
cat > "${RELEASE_DIR}/entrypoint.ps1" << 'PS1SCRIPT'
$ErrorActionPreference = "Stop"

$PackageName = "kira_caster"
$BaseDirectory = $PSScriptRoot
$ScriptCommand = $args[0]

$CodePath = Join-Path -Path $BaseDirectory -ChildPath "erlang\*\ebin" -Resolve

# 번들된 ERTS 찾기
$ErtsDir = Get-ChildItem -Path $BaseDirectory -Directory -Filter "erts-*" | Select-Object -First 1
if ($ErtsDir) {
  $ErlExe = Join-Path $ErtsDir.FullName "bin\erl.exe"
  $env:ROOTDIR = $BaseDirectory
  $env:BINDIR = Join-Path $ErtsDir.FullName "bin"
  $env:EMU = "beam"
  $env:PROGNAME = "erl"
  $env:ERL_LIBS = "$BaseDirectory\lib;$BaseDirectory\erlang"
  $BootPath = Join-Path $BaseDirectory "bin\start"
} else {
  $ErlExe = "erl"
  $BootPath = $null
}

function Run {
  $PaArgs = @()
  foreach ($p in $CodePath) { $PaArgs += "-pa"; $PaArgs += $p }
  if ($BootPath) { $PaArgs += "-boot"; $PaArgs += $BootPath }
  & $ErlExe @PaArgs `
    -eval "$PackageName@@main:run($PackageName)" `
    -noshell `
    -extra $args
}

function Shell {
  $PaArgs = @()
  foreach ($p in $CodePath) { $PaArgs += "-pa"; $PaArgs += $p }
  if ($BootPath) { $PaArgs += "-boot"; $PaArgs += $BootPath }
  & $ErlExe @PaArgs
}

switch ($ScriptCommand) {
  "run" {
    Run $args[1..($args.Length - 1)]
  }
  "shell" {
    Shell
  }
  default {
    Write-Host "usage:"
    Write-Host "  entrypoint.ps1 `$COMMAND"
    Write-Host ""
    Write-Host "commands:"
    Write-Host "  run    Run the project main function"
    Write-Host "  shell  Run an Erlang shell"
    exit 1
  }
}
PS1SCRIPT

# 8. 설정 파일 복사
cp gleam.toml "${RELEASE_DIR}/"
cp .env.example "${RELEASE_DIR}/"

if [ -f "scripts/kira-caster.desktop" ]; then
  cp scripts/kira-caster.desktop "${RELEASE_DIR}/"
fi

# 9. Linux/macOS 시작 스크립트
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

# 번들된 ERTS 사용
ERTS_DIR=$(ls -d "$SCRIPT_DIR"/erts-* 2>/dev/null | head -1)
export ROOTDIR="$SCRIPT_DIR"
export BINDIR="$ERTS_DIR/bin"
export EMU=beam
export PROGNAME=erl

ERL_LIBS="$SCRIPT_DIR/lib"
for d in "$SCRIPT_DIR/erlang"/*/ebin; do
  ERL_LIBS="$ERL_LIBS:$(dirname "$d")"
done
export ERL_LIBS

exec "$BINDIR/erlexec" \
  -boot "$ROOTDIR/bin/start" \
  -pa erlang/*/ebin \
  -noshell \
  -eval "kira_caster@@main:run(kira_caster)"
LAUNCHER
chmod +x "${RELEASE_DIR}/start.sh"

# 10. Windows 시작 스크립트 (번들 ERTS 사용, 별도 설치 불필요)
# 주의: cmd.exe 괄호 블록 안에 한국어(UTF-8 멀티바이트)를 넣으면
#       CP949 파싱 충돌로 "was unexpected at this time" 에러 발생.
#       goto 기반 흐름 제어 + 영문 메시지로 회피.
cat > "${RELEASE_DIR}/start.bat" << 'BATCH'
@echo off
setlocal EnableDelayedExpansion
chcp 65001 >nul 2>&1
title kira_caster
cd /d "%~dp0"

:: .env
if not exist .env goto :env_done
for /f "usebackq eol=# tokens=1,* delims==" %%a in (".env") do set "%%a=%%b"
:env_done
if not defined KIRA_ADMIN_PORT set "KIRA_ADMIN_PORT=9693"

:: port check
netstat -an 2>nul | findstr ":%KIRA_ADMIN_PORT% " | findstr "LISTENING" >nul 2>&1
if errorlevel 1 goto :port_ok
echo.
echo  [!] %KIRA_ADMIN_PORT% port is already in use.
echo  Close existing kira_caster first, or change port in .env file.
echo.
pause
exit /b 1
:port_ok

:: find bundled ERTS
set "ERTS_DIR="
for /d %%d in (erts-*) do set "ERTS_DIR=%%d"
if defined ERTS_DIR goto :erts_ok
echo.
echo  [!] Erlang runtime (erts) not found.
echo  Files may be corrupted. Please re-download.
echo.
pause
exit /b 1
:erts_ok

:: setup
set "ROOTDIR=%~dp0"
if "!ROOTDIR:~-1!"=="\" set "ROOTDIR=!ROOTDIR:~0,-1!"
set "BINDIR=!ROOTDIR!\!ERTS_DIR!\bin"
set "EMU=beam"
set "PROGNAME=erl"
set "ERL_LIBS=!ROOTDIR!\lib;!ROOTDIR!\erlang"

set "PA="
for /d %%d in (erlang\*) do if exist "%%d\ebin" set "PA=!PA! -pa %%d\ebin"

echo.
echo  kira_caster starting...
echo  http://localhost:%KIRA_ADMIN_PORT%
echo.
echo  Close this window or press Ctrl+C to stop.
echo.

start /b cmd /c "timeout /t 3 /nobreak >nul 2>&1 && start http://localhost:%KIRA_ADMIN_PORT%"

"!BINDIR!\erl.exe" -boot "!ROOTDIR!\bin\start" !PA! -noshell -eval "kira_caster@@main:run(kira_caster)"

echo.
echo  Program has stopped.
echo  If this keeps happening, send erl_crash.dump to the developer.
echo.
pause
BATCH
# LF → CRLF 변환 (cmd.exe 호환성)
if command -v sed &>/dev/null; then
  sed -i 's/$/\r/' "${RELEASE_DIR}/start.bat"
elif command -v unix2dos &>/dev/null; then
  unix2dos "${RELEASE_DIR}/start.bat" 2>/dev/null
fi

# 11. 패키징
tar czf "kira_caster-${TARGET}.tar.gz" "$RELEASE_DIR"
echo ""
echo "=== 패키징 완료 ==="
echo "파일: kira_caster-${TARGET}.tar.gz"
echo "크기: $(du -sh "kira_caster-${TARGET}.tar.gz" | cut -f1)"

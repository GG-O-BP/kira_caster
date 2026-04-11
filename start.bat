@echo off
chcp 65001 >nul
cd /d "%~dp0"

:: Load .env if exists
if exist .env (
  for /f "usebackq tokens=1,* delims==" %%a in (".env") do (
    set "%%a=%%b"
  )
)

if not defined KIRA_ADMIN_PORT set KIRA_ADMIN_PORT=8080

:: Check for pre-built release
if exist "erlang" (
  where erl >nul 2>&1
  if errorlevel 1 (
    echo Erlang이 설치되어 있지 않습니다.
    echo https://www.erlang.org/downloads 에서 설치해주세요.
    pause
    exit /b 1
  )
  echo kira_caster 시작 중... http://localhost:%KIRA_ADMIN_PORT%
  start "" "http://localhost:%KIRA_ADMIN_PORT%"
  erl -pa erlang/*/ebin -noshell -eval "gleam@@main:run(kira_caster)"
  goto :eof
)

:: Development mode
where gleam >nul 2>&1
if errorlevel 1 (
  echo Gleam이 설치되어 있지 않습니다.
  echo https://gleam.run/getting-started/installing/ 에서 설치해주세요.
  pause
  exit /b 1
)

if not exist "build\dev\erlang" (
  echo 처음 실행: 빌드 중...
  gleam deps download
  gleam build
)

echo kira_caster 시작 중... http://localhost:%KIRA_ADMIN_PORT%
start "" "http://localhost:%KIRA_ADMIN_PORT%"
gleam run

@echo off
chcp 65001 >nul
cd /d "%~dp0"

:: Load .env if exists
if exist .env (
  for /f "usebackq tokens=1,* delims==" %%a in (".env") do (
    set "%%a=%%b"
  )
)

if not defined KIRA_ADMIN_PORT set KIRA_ADMIN_PORT=9693

:: Check port availability
netstat -an 2>nul | findstr ":%KIRA_ADMIN_PORT% " | findstr "LISTENING" >nul 2>&1
if not errorlevel 1 (
  echo 오류: 포트 %KIRA_ADMIN_PORT%이 이미 사용 중입니다.
  echo.
  echo 해결 방법:
  echo   1. 다른 프로그램이 같은 포트를 사용하고 있는지 확인하세요
  echo   2. 포트 번호를 변경하려면 프로그램 폴더의 .env 파일을 메모장으로 열고
  echo      KIRA_ADMIN_PORT=8081 로 수정한 뒤 저장하세요
  echo      ^(.env 파일이 없으면 .env.example을 .env로 복사한 후 수정하세요^)
  pause
  exit /b 1
)

:: Check for pre-built release
if exist "erlang" (
  where erl >nul 2>&1
  if errorlevel 1 (
    echo 오류: Erlang이 설치되어 있지 않습니다.
    echo.
    echo 설치 방법:
    echo   https://www.erlang.org/downloads 에서 Erlang을 설치해주세요.
    echo.
    echo 설치 후 이 파일을 다시 실행해주세요.
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
  echo 오류: Gleam이 설치되어 있지 않습니다.
  echo.
  echo 설치 방법:
  echo   https://gleam.run/getting-started/installing/ 에서 Gleam을 설치해주세요.
  echo.
  echo 설치 후 이 파일을 다시 실행해주세요.
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

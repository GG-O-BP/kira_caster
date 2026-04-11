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

:: pre-built release
if not exist "erlang" goto :dev_mode

set "ERTS_DIR="
for /d %%d in (erts-*) do set "ERTS_DIR=%%d"

set "PA="
for /d %%d in (erlang\*) do if exist "%%d\ebin" set "PA=!PA! -pa %%d\ebin"

echo kira_caster starting... http://localhost:%KIRA_ADMIN_PORT%
start /b cmd /c "timeout /t 3 /nobreak >nul 2>&1 && start http://localhost:%KIRA_ADMIN_PORT%"

if not defined ERTS_DIR goto :system_erl
set "ROOTDIR=%~dp0"
if "!ROOTDIR:~-1!"=="\" set "ROOTDIR=!ROOTDIR:~0,-1!"
set "BINDIR=!ROOTDIR!\!ERTS_DIR!\bin"
set "EMU=beam"
set "PROGNAME=erl"
set "ERL_LIBS=!ROOTDIR!\lib;!ROOTDIR!\erlang"
"!BINDIR!\erl.exe" -boot "!ROOTDIR!\bin\start" !PA! -noshell -eval "kira_caster@@main:run(kira_caster)"
pause
goto :eof

:system_erl
where erl >nul 2>&1
if errorlevel 1 goto :no_erl
erl !PA! -noshell -eval "kira_caster@@main:run(kira_caster)"
pause
goto :eof

:no_erl
echo.
echo  [!] Erlang not found. Install from https://www.erlang.org/downloads
echo.
pause
exit /b 1

:dev_mode
where gleam >nul 2>&1
if errorlevel 1 goto :no_gleam

if not exist "build\dev\erlang" (
  echo First run: building...
  gleam deps download
  gleam build
)

echo kira_caster starting... http://localhost:%KIRA_ADMIN_PORT%
start "" "http://localhost:%KIRA_ADMIN_PORT%"
gleam run
goto :eof

:no_gleam
echo.
echo  [!] Gleam not found. Install from https://gleam.run/getting-started/installing/
echo.
pause
exit /b 1

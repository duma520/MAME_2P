@echo off
chcp 65001 >nul
setlocal
cd /d "%~dp0"

set "PY=D:\Program Files\Python310\python.exe"
if not exist "%PY%" (
    echo [ERROR] Python not found: %PY%
    echo Edit PY in this file.
    pause
    exit /b 1
)

if "%~1"=="" goto help
if /i "%~1"=="install"   goto install
if /i "%~1"=="uninstall" goto uninstall
if /i "%~1"=="verify"    goto verify
if /i "%~1"=="status"    goto status
if /i "%~1"=="selftest"  goto selftest
if /i "%~1"=="help"      goto help
echo Unknown arg: %~1
goto help

:install
"%PY%" -m mame_2p install
pause
goto end

:uninstall
"%PY%" -m mame_2p uninstall
pause
goto end

:verify
"%PY%" -m mame_2p verify
pause
goto end

:status
"%PY%" -m mame_2p status
pause
goto end

:selftest
"%PY%" -m mame_2p selftest
pause
goto end

:help
echo MAME copilot2p plugin tool
echo   run.bat install     install/update plugin into MAME
echo   run.bat uninstall   remove plugin, restore plugin.ini
echo   run.bat verify      preflight check + lua static check
echo   run.bat status      read plugin_status.json (menu_verify etc.)
echo   run.bat selftest    read-only self check
echo.
echo NOTE: plugin code is cached by require. To load a new version you must
echo       FULLY EXIT MAMEUI front-end and start it again.
pause
goto end

:end
endlocal

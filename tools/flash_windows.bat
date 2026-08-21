@echo off
chcp 65001 >nul
title ESP32 HDMI-CEC Firmware Flasher
color 0A

echo ===============================================================================
echo        ESP32 HDMI-CEC TV Autostart - Windows Flasher Tool
echo ===============================================================================
echo.

:: Check Python installation
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] Python was not found on your system.
    echo [*] Opening standalone browser-based Web Flasher (0 setup required)...
    timeout /t 2 >nul
    start "" "%~dp0web_flasher.html"
    pause
    exit /b
)

:: Install dependencies
echo [*] Checking dependencies (esptool, pyserial)...
python -m pip install esptool pyserial --quiet --disable-pip-version-check

:: Launch GUI
echo [*] Launching Flasher GUI...
start "" python "%~dp0flasher_gui.py"

exit /b

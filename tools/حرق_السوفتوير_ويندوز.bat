@echo off
chcp 65001 >nul
title أداة حرق السوفتوير - ESP32 HDMI-CEC TV Autostart
color 0B

echo ===============================================================================
echo     📺 أداة حرق السوفتوير لشريحة ESP32 - تشغيل التلفزيون التلقائي HDMI-CEC
echo ===============================================================================
echo.

:: Check if Python is available
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] بايثون Python غير مثبت على جهازك.
    echo [*] جاري فتح أداة الحرق المباشرة عبر المتصفح (Web Flasher) بدون الحاجة لتثبيت أي برامج...
    echo.
    timeout /t 2 >nul
    start "" "%~dp0web_flasher.html"
    pause
    exit /b
)

:: Check and install required packages
echo [*] فحص وتثبيت الحزم المطلوبة (esptool, pyserial)...
python -m pip install esptool pyserial --quiet --disable-pip-version-check

:: Launch Graphical Application
echo [*] جاري تشغيل واجهة الحرق الرسومية...
start "" python "%~dp0flasher_gui.py"

exit /b

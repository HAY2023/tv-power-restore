@echo off
chcp 65001 >nul
title أداة حرق السوفتوير - ESP32 HDMI-CEC TV Autostart
color 0B
setlocal enabledelayedexpansion

:MAIN_MENU
cls
echo ===============================================================================
echo     📺 أداة حرق السوفتوير لشريحة ESP32 - نظام تشغيل التلفزيون التلقائي HDMI-CEC
echo ===============================================================================
echo.
echo  [1] حرق السوفتوير لشريحة ESP32 WROOM / DevKit v1 (الأساسية الافتراضية)
echo  [2] حرق السوفتوير لشريحة ESP32-C3 Super Mini (الاختيارية الصغيرة)
echo  [3] مسح ذاكرة الشريحة بالكامل (Full Chip Erase)
echo  [4] إعادة فحص منافذ التوصيل (COM Ports)
echo  [5] خروج (Exit)
echo.
echo ===============================================================================
set /p "CHOICE=👉 اختر رقم العملية ثم اضغط Enter [1-5]: "

if "%CHOICE%"=="1" (
    set "CHIP=esp32"
    set "BOARD_NAME=ESP32 WROOM (DevKit v1)"
    set "BIN_FILE=esp32-wroom-complete-flash-offset-0x0.bin"
    set "ALT_BIN=.pio\build\esp32dev\firmware.bin"
    set "OFFSET=0x0"
    goto SCAN_PORT
)
if "%CHOICE%"=="2" (
    set "CHIP=esp32c3"
    set "BOARD_NAME=ESP32-C3 Super Mini"
    set "BIN_FILE=esp32-c3-complete-flash-offset-0x0.bin"
    set "ALT_BIN=.pio\build\esp32c3\firmware.bin"
    set "OFFSET=0x0"
    goto SCAN_PORT
)
if "%CHOICE%"=="3" (
    goto ERASE_MENU
)
if "%CHOICE%"=="4" (
    goto MAIN_MENU
)
if "%CHOICE%"=="5" (
    echo مع السلامة!
    exit /b
)
echo ⚠️ اختيار غير صحيح، حاول مرة أخرى.
timeout /t 2 >nul
goto MAIN_MENU

:SCAN_PORT
cls
echo ===============================================================================
echo   🔍 جاري البحث عن منافذ COM المتصلة بجهازك...
echo ===============================================================================
echo.

:: Use PowerShell to detect COM ports
for /f "usebackq delims=" %%P in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "[System.IO.Ports.SerialPort]::GetPortNames()"`) do (
    set "FOUND_PORT=%%P"
)

if "%FOUND_PORT%"=="" (
    echo ⚠️ لم يتم العثور على أي شريحة متصلة عبر منفذ COM!
    echo.
    echo  يرجى التأكد من:
    echo   1. توصيل شريحة الـ ESP32 بالكمبيوتر عبر كابل USB يدعم نقل البيانات.
    echo   2. تثبيت تعريف المنفذ (CH340 أو CP2102).
    echo.
    echo اضغط أي مفتاح لإعادة الفحص...
    pause >nul
    goto SCAN_PORT
)

echo [✓] تم اكتشاف المنفذ: %FOUND_PORT%
echo.
set /p "USER_PORT=👉 اضغط Enter لاستخدام (%FOUND_PORT%) أو اكتب رقم منفذ آخر (مثال COM4): "
if "%USER_PORT%"=="" (
    set "PORT=%FOUND_PORT%"
) else (
    set "PORT=%USER_PORT%"
)

:CHECK_PYTHON
echo.
echo [*] فحص توفر أداة البرمجة (esptool)...
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo ⚠️ بايثون Python غير مثبت على جهازك!
    echo    يرجى تثبيت Python من https://www.python.org/ ثم تفعيل خيار (Add to PATH).
    echo.
    pause
    goto MAIN_MENU
)

:: Ensure esptool is installed
python -m pip show esptool >nul 2>&1
if %errorlevel% neq 0 (
    echo [*] جاري تثبيت أداة esptool تلقائياً لأول مرة...
    python -m pip install esptool pyserial --quiet --disable-pip-version-check
)

:LOCATE_BINARY
set "TARGET_BIN="
if exist "%BIN_FILE%" set "TARGET_BIN=%BIN_FILE%"
if exist "release_binaries\%BIN_FILE%" set "TARGET_BIN=release_binaries\%BIN_FILE%"
if exist "%ALT_BIN%" (
    set "TARGET_BIN=%ALT_BIN%"
    set "OFFSET=0x10000"
)

if "%TARGET_BIN%"=="" (
    echo.
    echo ⚠️ لم يتم العثور على ملف السوفتوير الجاهز (%BIN_FILE%).
    echo    هل ترغب في تجميع السوفتوير محلياً الآن باستخدام PlatformIO؟
    echo.
    set /p "BUILD_CONFIRM=👉 اكتب Y للموافقة أو N للرجوع: "
    if /i "!BUILD_CONFIRM!"=="Y" (
        echo [*] جاري تجميع السوفتوير...
        if "%CHIP%"=="esp32" (pio run -e esp32dev) else (pio run -e esp32c3)
        if exist "%ALT_BIN%" (
            set "TARGET_BIN=%ALT_BIN%"
            set "OFFSET=0x10000"
        ) else (
            echo ❌ فشل تجميع السوفتوير.
            pause
            goto MAIN_MENU
        )
    ) else (
        goto MAIN_MENU
    )
)

:START_FLASH
cls
echo ===============================================================================
echo   🔥 بدء عملية حرق السوفتوير على شريحة الـ ESP32
echo ===============================================================================
echo.
echo   - اللوحة المستهدفة : %BOARD_NAME%
echo   - منفذ التوصيل      : %PORT%
echo   - ملف السوفتوير     : %TARGET_BIN%
echo   - عنوان الفلاش     : %OFFSET%
echo.
echo ⏳ جاري الاتصال بالشريحة وكتابة الفلاش...
echo    (إذا توقف البرنامج عند Connecting... اضغط باستمرار على زر BOOT في الشريحة)
echo.
echo -------------------------------------------------------------------------------

python -m esptool --chip %CHIP% --port %PORT% --baud 460800 write_flash -z %OFFSET% "%TARGET_BIN%"

if %errorlevel% equ 0 (
    echo.
    echo ===============================================================================
    echo   🎉 مبروك! تمت عملية البرمجة وحرق السوفتوير بنجاح 100%%!
    echo   يمكنك الآن فصل الشريحة وتوصيلها بمنفذ الـ HDMI في التلفزيون.
    echo ===============================================================================
    echo.
    pause
    goto MAIN_MENU
)

echo.
echo ⚠️ فشلت المحاولة الأولى. جاري إعادة المحاولة بسرعة نقل أبطأ وأكثر استقراراً (115200)...
echo    (يرجى الضغط باستمرار على زر BOOT في لوحة الـ ESP32 الآن)
echo.
timeout /t 2 >nul

python -m esptool --chip %CHIP% --port %PORT% --baud 115200 write_flash -z %OFFSET% "%TARGET_BIN%"

if %errorlevel% equ 0 (
    echo.
    echo ===============================================================================
    echo   🎉 مبروك! تمت عملية البرمجة بنجاح 100%%!
    echo ===============================================================================
    echo.
    pause
    goto MAIN_MENU
) else (
    echo.
    echo ❌ تعذر الاتصال بالشريحة. تأكد من:
    echo   1. الضغط باستمرار على زر BOOT في اللوحة أثناء محاولة الاتصال.
    echo   2. التأكد من أن كابل الـ USB سليم وينقل البيانات.
    echo.
    pause
    goto MAIN_MENU
)

:ERASE_MENU
cls
echo ===============================================================================
echo   🗑️ مسح ذاكرة الشريحة بالكامل (Chip Erase)
echo ===============================================================================
echo.
echo  [1] مسح شريحة ESP32 WROOM
echo  [2] مسح شريحة ESP32-C3
echo  [3] رجوع للقائمة الرئيسية
echo.
set /p "ERASE_CHOICE=👉 اختر اللوحة [1-3]: "

if "%ERASE_CHOICE%"=="1" (
    set "CHIP=esp32"
) else if "%ERASE_CHOICE%"=="2" (
    set "CHIP=esp32c3"
) else (
    goto MAIN_MENU
)

for /f "usebackq delims=" %%P in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "[System.IO.Ports.SerialPort]::GetPortNames()"`) do (
    set "FOUND_PORT=%%P"
)
if "%FOUND_PORT%"=="" (
    echo لم يتم العثور على منفذ متصل!
    pause
    goto MAIN_MENU
)
echo [*] جاري مسح الذاكرة على المنفذ %FOUND_PORT%...
python -m esptool --chip %CHIP% --port %FOUND_PORT% erase_flash
echo.
echo [✓] تم مسح الذاكرة.
pause
goto MAIN_MENU

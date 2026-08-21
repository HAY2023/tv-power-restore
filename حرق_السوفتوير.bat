@echo off
chcp 65001 >nul
title أداة حرق السوفتوير - ESP32 HDMI-CEC TV Autostart (v1.0.0)
color 0B
setlocal enabledelayedexpansion

set "VERSION=1.0.0"

:MAIN_MENU
cls
echo ===============================================================================
echo     📺 أداة حرق السوفتوير لشريحة ESP32 - نظام تشغيل التلفزيون HDMI-CEC
echo                       الإصدار الرسمي: v%VERSION%
echo ===============================================================================
echo.
echo  [1] 🔍 كشف جميع المتحكمات المتصلة واختيار الشريحة للحرق المباشر
echo  [2] ⚡ حرق شريحة ESP32 WROOM / DevKit v1 (الأساسية الافتراضية)
echo  [3] ⚡ حرق شريحة ESP32-C3 Super Mini (الاختيارية الصغيرة)
echo  [4] 📋 قراءة بيانات وتفاصيل الشريحة المتصلة (Chip Info / MAC / Flash)
echo  [5] 🗑️ مسح ذاكرة الشريحة بالكامل (Full Chip Erase)
echo  [6] ❌ خروج (Exit)
echo.
echo ===============================================================================
set /p "CHOICE=👉 اختر رقم العملية ثم اضغط Enter [1-6]: "

if "%CHOICE%"=="1" (
    goto AUTO_DETECT_AND_FLASH
)
if "%CHOICE%"=="2" (
    set "CHIP=esp32"
    set "BOARD_NAME=ESP32 WROOM (DevKit v1)"
    set "BIN_FILE=esp32-wroom-complete-flash-offset-0x0.bin"
    set "ALT_BIN=.pio\build\esp32dev\firmware.bin"
    set "OFFSET=0x0"
    goto SELECT_PORT_MENU
)
if "%CHOICE%"=="3" (
    set "CHIP=esp32c3"
    set "BOARD_NAME=ESP32-C3 Super Mini"
    set "BIN_FILE=esp32-c3-complete-flash-offset-0x0.bin"
    set "ALT_BIN=.pio\build\esp32c3\firmware.bin"
    set "OFFSET=0x0"
    goto SELECT_PORT_MENU
)
if "%CHOICE%"=="4" (
    goto READ_CHIP_INFO
)
if "%CHOICE%"=="5" (
    goto ERASE_MENU
)
if "%CHOICE%"=="6" (
    echo شكراً لاستخدامك الأداة. مع السلامة!
    exit /b
)

echo ⚠️ اختيار غير صحيح، يرجى إدخال رقم من 1 إلى 6.
timeout /t 2 >nul
goto MAIN_MENU

:: ============================================================================
:: 1. AUTO DETECT AND FLASH MENU
:: ============================================================================
:AUTO_DETECT_AND_FLASH
cls
echo ===============================================================================
echo     🔍 فحص وكشف جميع المتحكمات والشاشات المتصلة بمنافذ الـ USB / COM
echo ===============================================================================
echo.

call :LIST_ALL_PORTS

if "%PORT_COUNT%"=="0" (
    echo.
    echo ⚠️ لم يتم العثور على أي متحكم أو منفذ متصل بالكمبيوتر!
    echo    - تأكد من توصيل شريحة الـ ESP32 بكابل USB سليم ينقل البيانات.
    echo    - تأكد من تثبيت تعريف المنفذ (CH340 أو CP2102).
    echo.
    pause
    goto MAIN_MENU
)

echo.
echo ===============================================================================
echo 👉 اختر رقم المتحكم المراد حرقه [1-%PORT_COUNT%] أو اكتب اسم المنفذ (مثال COM3):
set /p "PORT_SEL=رقم الاختيار: "

:: Determine chosen port
set "SELECTED_PORT="
if defined PORT_NAME_%PORT_SEL% (
    set "SELECTED_PORT=!PORT_NAME_%PORT_SEL%!"
) else (
    set "SELECTED_PORT=%PORT_SEL%"
)

if "%SELECTED_PORT%"=="" (
    echo ⚠️ اختيار غير صحيح.
    pause
    goto MAIN_MENU
)

cls
echo ===============================================================================
echo   المتحكم المحدد: [%SELECTED_PORT%]
echo ===============================================================================
echo.
echo  اختر نوع السوفتوير المناسب لشريحتك:
echo.
echo  [1] ESP32 WROOM / DevKit v1 (الأساسية الافتراضية - الأكثر انتشاراً)
echo  [2] ESP32-C3 Super Mini (الشريحة الصغيرة)
echo  [3] إلغاء والعودة للقائمة الرئيسية
echo.
set /p "BOARD_SEL=👉 اختر رقم اللوحة [1-3]: "

if "%BOARD_SEL%"=="1" (
    set "CHIP=esp32"
    set "BOARD_NAME=ESP32 WROOM (DevKit v1)"
    set "BIN_FILE=esp32-wroom-complete-flash-offset-0x0.bin"
    set "ALT_BIN=.pio\build\esp32dev\firmware.bin"
    set "OFFSET=0x0"
    set "PORT=%SELECTED_PORT%"
    goto CHECK_PYTHON
)
if "%BOARD_SEL%"=="2" (
    set "CHIP=esp32c3"
    set "BOARD_NAME=ESP32-C3 Super Mini"
    set "BIN_FILE=esp32-c3-complete-flash-offset-0x0.bin"
    set "ALT_BIN=.pio\build\esp32c3\firmware.bin"
    set "OFFSET=0x0"
    set "PORT=%SELECTED_PORT%"
    goto CHECK_PYTHON
)
goto MAIN_MENU

:: ============================================================================
:: PORT SELECTION HELPER
:: ============================================================================
:SELECT_PORT_MENU
cls
echo ===============================================================================
echo     🔍 المتحكمات والمنافذ المتاحة للوحة: %BOARD_NAME%
echo ===============================================================================
echo.

call :LIST_ALL_PORTS

if "%PORT_COUNT%"=="0" (
    echo.
    echo ⚠️ لم يتم العثور على أي شريحة متصلة!
    echo اضغط أي مفتاح لإعادة المحاولة...
    pause >nul
    goto SELECT_PORT_MENU
)

echo.
if "%PORT_COUNT%"=="1" (
    set "PORT=%PORT_NAME_1%"
    echo [✓] تم اختيار المنفذ الوحيد المتاح تلقائياً: !PORT!
    echo.
    set /p "CONFIRM_PORT=👉 اضغط Enter للمتابعة أو اكتب منفذ آخر: "
    if not "!CONFIRM_PORT!"=="" set "PORT=!CONFIRM_PORT!"
    goto CHECK_PYTHON
) else (
    echo ===============================================================================
    set /p "PORT_SEL=👉 اختر رقم المنفذ [1-%PORT_COUNT%] أو اكتب المنفذ مباشرة: "
    if defined PORT_NAME_!PORT_SEL! (
        set "PORT=!PORT_NAME_%PORT_SEL%!"
    ) else (
        set "PORT=!PORT_SEL!"
    )
    goto CHECK_PYTHON
)

:: ============================================================================
:: SUBROUTINE: LIST ALL SERIAL PORTS WITH FRIENDLY DESCRIPTIONS
:: ============================================================================
:LIST_ALL_PORTS
set "PORT_COUNT=0"

:: Query devices using PowerShell WMI/CIM
for /f "usebackq tokens=1,2* delims=|" %%A in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-CimInstance Win32_PnPEntity | Where-Object { $_.Name -match '\((COM\d+)\)' } | ForEach-Object { if ($_.Name -match '\((COM\d+)\)') { $p = $matches[1]; \"$p|$($_.Name)\" } }"`) do (
    set /a PORT_COUNT+=1
    set "PORT_NAME_!PORT_COUNT!=%%A"
    set "PORT_DESC_!PORT_COUNT!=%%B"
    echo   [!PORT_COUNT!] %%A  ^<--  %%B
)

:: Fallback if WMI returned nothing
if "%PORT_COUNT%"=="0" (
    for /f "usebackq delims=" %%P in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "[System.IO.Ports.SerialPort]::GetPortNames()"`) do (
        set /a PORT_COUNT+=1
        set "PORT_NAME_!PORT_COUNT!=%%P"
        set "PORT_DESC_!PORT_COUNT!=منفذ تسلسلي (%%P)"
        echo   [!PORT_COUNT!] %%P
    )
)
exit /b

:: ============================================================================
:: 4. READ DETAILED CHIP INFO
:: ============================================================================
:READ_CHIP_INFO
cls
echo ===============================================================================
echo     📋 قراءة بيانات وتفاصيل الشريحة المتصلة (Hardware Diagnostics)
echo ===============================================================================
echo.

call :LIST_ALL_PORTS
if "%PORT_COUNT%"=="0" (
    echo ⚠️ لم يتم العثور على أي شريحة متصلة.
    pause
    goto MAIN_MENU
)

echo.
set /p "INFO_PORT_SEL=👉 اختر رقم المنفذ المراد فحصه [1-%PORT_COUNT%]: "
if defined PORT_NAME_%INFO_PORT_SEL% (
    set "TARGET_PORT=!PORT_NAME_%INFO_PORT_SEL%!"
) else (
    set "TARGET_PORT=%INFO_PORT_SEL%"
)

echo.
echo [*] جاري فحص بيانات الشريحة على المنفذ %TARGET_PORT%...
echo.

python -m esptool --port %TARGET_PORT% chip_id
echo.
python -m esptool --port %TARGET_PORT% flash_id
echo.
echo ===============================================================================
pause
goto MAIN_MENU

:: ============================================================================
:: PYTHON & DEPENDENCY CHECK
:: ============================================================================
:CHECK_PYTHON
echo.
echo [*] فحص توفر أداة البرمجة (esptool)...
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo ⚠️ بايثون Python غير مثبت على جهازك!
    echo    يرجى تثبيت Python من https://www.python.org/ وتفعيل خيار (Add Python to PATH).
    echo.
    pause
    goto MAIN_MENU
)

python -m pip show esptool >nul 2>&1
if %errorlevel% neq 0 (
    echo [*] جاري تثبيت أداة esptool تلقائياً...
    python -m pip install esptool pyserial --quiet --disable-pip-version-check
)

:: ============================================================================
:: LOCATE FIRMWARE BINARY
:: ============================================================================
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
    echo ⚠️ لم يتم العثور على ملف الفلاش المدمج (%BIN_FILE%).
    echo    هل ترغب في بناء وتجميع السوفتوير محلياً الآن باستخدام PlatformIO؟
    echo.
    set /p "BUILD_CONFIRM=👉 اكتب Y للموافقة أو N للرجوع: "
    if /i "!BUILD_CONFIRM!"=="Y" (
        echo [*] جاري تجميع السوفتوير للوحة %BOARD_NAME%...
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

:: ============================================================================
:: EXECUTE FLASH
:: ============================================================================
:START_FLASH
cls
echo ===============================================================================
echo   🔥 بدء عملية حرق السوفتوير (الإصدار v%VERSION%)
echo ===============================================================================
echo.
echo   - اللوحة المستهدفة : %BOARD_NAME%
echo   - منفذ التوصيل      : %PORT%
echo   - ملف السوفتوير     : %TARGET_BIN%
echo   - عنوان الذاكرة     : %OFFSET%
echo.
echo ⏳ جاري الاتصال بالشريحة وكتابة الفلاش...
echo    (إذا توقف البرنامج عند Connecting... اضغط باستمرار على زر BOOT في الشريحة)
echo.
echo -------------------------------------------------------------------------------

python -m esptool --chip %CHIP% --port %PORT% --baud 460800 write_flash -z %OFFSET% "%TARGET_BIN%"

if %errorlevel% equ 0 (
    echo.
    echo ===============================================================================
    echo   🎉 مبروك! تمت برمجة الشريحة بنجاح 100%% (الإصدار v%VERSION%)!
    echo   يمكنك الآن فصل لوحة الـ ESP32 وتوصيلها بمنفذ الـ HDMI في التلفزيون.
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
    echo   🎉 مبروك! تمت عملية البرمجة بنجاح 100%% (الإصدار v%VERSION%)!
    echo ===============================================================================
    echo.
    pause
    goto MAIN_MENU
) else (
    echo.
    echo ❌ تعذر الاتصال بالشريحة. تأكد من:
    echo   1. الضغط باستمرار على زر BOOT في اللوحة أثناء محاولة الاتصال.
    echo   2. التأكد من أن كابل الـ USB سليم وينقل البيانات.
    echo   3. اختيار منفذ الـ COM الصحيح.
    echo.
    pause
    goto MAIN_MENU
)

:: ============================================================================
:: 5. FULL CHIP ERASE
:: ============================================================================
:ERASE_MENU
cls
echo ===============================================================================
echo   🗑️ مسح ذاكرة الشريحة بالكامل (Full Chip Erase)
echo ===============================================================================
echo.
call :LIST_ALL_PORTS
if "%PORT_COUNT%"=="0" (
    echo ⚠️ لم يتم العثور على أي منفذ متصل!
    pause
    goto MAIN_MENU
)

echo.
set /p "ERASE_PORT_SEL=👉 اختر رقم المنفذ المراد مسح ذاكرته [1-%PORT_COUNT%]: "
if defined PORT_NAME_%ERASE_PORT_SEL% (
    set "ERASE_PORT=!PORT_NAME_%ERASE_PORT_SEL%!"
) else (
    set "ERASE_PORT=%ERASE_PORT_SEL%"
)

echo.
echo [*] جاري مسح الذاكرة بالكامل على المنفذ %ERASE_PORT%...
python -m esptool --port %ERASE_PORT% erase_flash
echo.
echo [✓] تم مسح الذاكرة بنجاح.
pause
goto MAIN_MENU

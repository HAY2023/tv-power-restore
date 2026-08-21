@echo off
chcp 65001 >nul
title ESP32 HDMI-CEC TV Autostart Flasher v1.1.0
color 0B
setlocal enabledelayedexpansion

set "VERSION=1.1.0"

:: Detect Python
set "PY_CMD="
where python >nul 2>&1
if %errorlevel% equ 0 set "PY_CMD=python"
if "%PY_CMD%"=="" (
    where py >nul 2>&1
    if %errorlevel% equ 0 set "PY_CMD=py -3"
)
if "%PY_CMD%"=="" (
    where python3 >nul 2>&1
    if %errorlevel% equ 0 set "PY_CMD=python3"
)

:MAIN_MENU
cls
echo ===============================================================================
echo     ESP32 HDMI-CEC TV Autostart Flasher - Tool v%VERSION%
echo ===============================================================================
echo.
echo  [1] Auto-detect COM port and Flash
echo  [2] Flash ESP32 WROOM / DevKit v1
echo  [3] Flash ESP32-C3 Super Mini
echo  [4] Flash ESP32-S2
echo  [5] Flash ESP32-S3
echo  [6] Flash ESP8266 (NodeMCU / Wemos)
echo  [7] Read Chip Info / MAC Address
echo  [8] Full Chip Erase
echo  [9] Exit
echo.
echo ===============================================================================
set "CHOICE="
set /p "CHOICE=Select an option [1-9]: "

if "%CHOICE%"=="1" goto AUTO_DETECT_AND_FLASH
if "%CHOICE%"=="2" goto SELECT_ESP32
if "%CHOICE%"=="3" goto SELECT_ESP32C3
if "%CHOICE%"=="4" goto SELECT_ESP32S2
if "%CHOICE%"=="5" goto SELECT_ESP32S3
if "%CHOICE%"=="6" goto SELECT_ESP8266
if "%CHOICE%"=="7" goto READ_CHIP_INFO
if "%CHOICE%"=="8" goto ERASE_MENU
if "%CHOICE%"=="9" goto EXIT_SCRIPT

echo [WARNING] Invalid option. Please enter a number from 1 to 9.
timeout /t 2 >nul
goto MAIN_MENU

:SELECT_ESP32
set "CHIP=esp32"
set "BOARD_NAME=ESP32 WROOM (DevKit v1)"
set "BIN_FILE=ESP32_WROOM_Firmware.bin"
set "ALT_BIN=.pio\build\esp32dev\firmware.bin"
set "ENV_NAME=esp32dev"
set "OFFSET=0x0"
goto SELECT_PORT_MENU

:SELECT_ESP32C3
set "CHIP=esp32c3"
set "BOARD_NAME=ESP32-C3 Super Mini"
set "BIN_FILE=ESP32_C3_Firmware.bin"
set "ALT_BIN=.pio\build\esp32c3\firmware.bin"
set "ENV_NAME=esp32c3"
set "OFFSET=0x0"
goto SELECT_PORT_MENU

:SELECT_ESP32S2
set "CHIP=esp32s2"
set "BOARD_NAME=ESP32-S2"
set "BIN_FILE=ESP32_S2_Firmware.bin"
set "ALT_BIN=.pio\build\esp32s2\firmware.bin"
set "ENV_NAME=esp32s2"
set "OFFSET=0x0"
goto SELECT_PORT_MENU

:SELECT_ESP32S3
set "CHIP=esp32s3"
set "BOARD_NAME=ESP32-S3"
set "BIN_FILE=ESP32_S3_Firmware.bin"
set "ALT_BIN=.pio\build\esp32s3\firmware.bin"
set "ENV_NAME=esp32s3"
set "OFFSET=0x0"
goto SELECT_PORT_MENU

:SELECT_ESP8266
set "CHIP=esp8266"
set "BOARD_NAME=ESP8266"
set "BIN_FILE=ESP8266_Firmware.bin"
set "ALT_BIN=.pio\build\esp8266\firmware.bin"
set "ENV_NAME=esp8266"
set "OFFSET=0x0"
goto SELECT_PORT_MENU

:EXIT_SCRIPT
echo.
echo Thank you for using ESP32 HDMI-CEC Autostart Flasher. Goodbye.
exit /b 0

:: ============================================================================
:: 1. AUTO DETECT AND FLASH
:: ============================================================================
:AUTO_DETECT_AND_FLASH
cls
echo ===============================================================================
echo     Scanning connected COM ports / Microcontrollers...
echo ===============================================================================
echo.

call :LIST_ALL_PORTS

if "%PORT_COUNT%"=="0" (
    echo.
    echo [WARNING] No COM ports detected.
    echo     - Please plug your microcontroller into USB.
    echo     - Ensure CH340 or CP2102 drivers are installed.
    echo.
    pause
    goto MAIN_MENU
)

echo.
echo ===============================================================================
set /p "PORT_SEL=Select port number [1-%PORT_COUNT%] or type port (e.g. COM3): "

set "SELECTED_PORT="
if defined PORT_NAME_%PORT_SEL% (
    set "SELECTED_PORT=!PORT_NAME_%PORT_SEL%!"
) else (
    set "SELECTED_PORT=%PORT_SEL%"
)

if "%SELECTED_PORT%"=="" (
    echo [ERROR] Invalid port selection.
    pause
    goto MAIN_MENU
)

cls
echo ===============================================================================
echo   Selected Port: [%SELECTED_PORT%]
echo ===============================================================================
echo.
echo  Select your target board:
echo.
echo  [1] ESP32 WROOM / DevKit v1
echo  [2] ESP32-C3 Super Mini
echo  [3] ESP32-S2
echo  [4] ESP32-S3
echo  [5] ESP8266 (NodeMCU / Wemos)
echo  [6] Cancel and return to main menu
echo.
set /p "BOARD_SEL=Select board [1-6]: "

if "%BOARD_SEL%"=="1" (
    set "CHIP=esp32"
    set "BOARD_NAME=ESP32 WROOM (DevKit v1)"
    set "BIN_FILE=ESP32_WROOM_Firmware.bin"
    set "ALT_BIN=.pio\build\esp32dev\firmware.bin"
    set "ENV_NAME=esp32dev"
    set "OFFSET=0x0"
    set "PORT=%SELECTED_PORT%"
    goto CHECK_PYTHON
)
if "%BOARD_SEL%"=="2" (
    set "CHIP=esp32c3"
    set "BOARD_NAME=ESP32-C3 Super Mini"
    set "BIN_FILE=ESP32_C3_Firmware.bin"
    set "ALT_BIN=.pio\build\esp32c3\firmware.bin"
    set "ENV_NAME=esp32c3"
    set "OFFSET=0x0"
    set "PORT=%SELECTED_PORT%"
    goto CHECK_PYTHON
)
if "%BOARD_SEL%"=="3" (
    set "CHIP=esp32s2"
    set "BOARD_NAME=ESP32-S2"
    set "BIN_FILE=ESP32_S2_Firmware.bin"
    set "ALT_BIN=.pio\build\esp32s2\firmware.bin"
    set "ENV_NAME=esp32s2"
    set "OFFSET=0x0"
    set "PORT=%SELECTED_PORT%"
    goto CHECK_PYTHON
)
if "%BOARD_SEL%"=="4" (
    set "CHIP=esp32s3"
    set "BOARD_NAME=ESP32-S3"
    set "BIN_FILE=ESP32_S3_Firmware.bin"
    set "ALT_BIN=.pio\build\esp32s3\firmware.bin"
    set "ENV_NAME=esp32s3"
    set "OFFSET=0x0"
    set "PORT=%SELECTED_PORT%"
    goto CHECK_PYTHON
)
if "%BOARD_SEL%"=="5" (
    set "CHIP=esp8266"
    set "BOARD_NAME=ESP8266"
    set "BIN_FILE=ESP8266_Firmware.bin"
    set "ALT_BIN=.pio\build\esp8266\firmware.bin"
    set "ENV_NAME=esp8266"
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
echo     Available Ports for: %BOARD_NAME%
echo ===============================================================================
echo.

call :LIST_ALL_PORTS

if "%PORT_COUNT%"=="0" (
    echo.
    echo [WARNING] No microcontrollers found.
    echo     Please connect your board via USB cable.
    echo.
    pause
    goto MAIN_MENU
)

echo.
if "%PORT_COUNT%"=="1" (
    set "PORT=%PORT_NAME_1%"
    echo [INFO] Auto-selected available port: !PORT!
    echo.
    set /p "CONFIRM_PORT=Press Enter to proceed or type a different port: "
    if not "!CONFIRM_PORT!"=="" set "PORT=!CONFIRM_PORT!"
    goto CHECK_PYTHON
) else (
    echo ===============================================================================
    set /p "PORT_SEL=Select port [1-%PORT_COUNT%] or type port directly: "
    if defined PORT_NAME_!PORT_SEL! (
        set "PORT=!PORT_NAME_%PORT_SEL%!"
    ) else (
        set "PORT=!PORT_SEL!"
    )
    goto CHECK_PYTHON
)

:: ============================================================================
:: SUBROUTINE: LIST PORTS
:: ============================================================================
:LIST_ALL_PORTS
set "PORT_COUNT=0"

for /f "usebackq tokens=1* delims=:" %%A in (`powershell -NoProfile -Command "Get-CimInstance Win32_PnPEntity ^| Where-Object { $_.Name -match '\(COM\d+\)' } ^| ForEach-Object { $m=[regex]::Match($_.Name, 'COM\d+').Value; Write-Output ($m + ':' + $_.Name) }" 2^>nul`) do (
    set /a PORT_COUNT+=1
    set "PORT_NAME_!PORT_COUNT!=%%A"
    set "PORT_DESC_!PORT_COUNT!=%%B"
    echo   [!PORT_COUNT!] %%A  ^<--  %%B
)

if "%PORT_COUNT%"=="0" (
    for /f "usebackq delims=" %%P in (`powershell -NoProfile -Command "[System.IO.Ports.SerialPort]::GetPortNames()" 2^>nul`) do (
        set /a PORT_COUNT+=1
        set "PORT_NAME_!PORT_COUNT!=%%P"
        set "PORT_DESC_!PORT_COUNT!=Serial Port (%%P)"
        echo   [!PORT_COUNT!] %%P  ^<--  Serial Port
    )
)
exit /b

:: ============================================================================
:: READ CHIP INFO
:: ============================================================================
:READ_CHIP_INFO
cls
echo ===============================================================================
echo     Read Chip Info / MAC Address
echo ===============================================================================
echo.

call :LIST_ALL_PORTS
if "%PORT_COUNT%"=="0" (
    echo [WARNING] No serial ports detected.
    pause
    goto MAIN_MENU
)

echo.
set /p "INFO_PORT_SEL=Select port [1-%PORT_COUNT%]: "
if defined PORT_NAME_%INFO_PORT_SEL% (
    set "TARGET_PORT=!PORT_NAME_%INFO_PORT_SEL%!"
) else (
    set "TARGET_PORT=%INFO_PORT_SEL%"
)

if "%TARGET_PORT%"=="" (
    echo [ERROR] Invalid selection.
    pause
    goto MAIN_MENU
)

call :ENSURE_PYTHON_READY
if %errorlevel% neq 0 goto MAIN_MENU

echo.
echo [INFO] Querying chip info on %TARGET_PORT%...
echo.

%PY_CMD% -m esptool --port %TARGET_PORT% chip_id
echo.
%PY_CMD% -m esptool --port %TARGET_PORT% flash_id
echo.
echo ===============================================================================
pause
goto MAIN_MENU

:: ============================================================================
:: PYTHON CHECK
:: ============================================================================
:CHECK_PYTHON
call :ENSURE_PYTHON_READY
if %errorlevel% neq 0 goto MAIN_MENU
goto LOCATE_BINARY

:ENSURE_PYTHON_READY
if "%PY_CMD%"=="" (
    echo.
    echo [ERROR] Python is not installed or not in PATH.
    echo     Please install Python from https://www.python.org/ and check 'Add Python to PATH'.
    echo.
    pause
    exit /b 1
)

%PY_CMD% -m pip show esptool >nul 2>&1
if %errorlevel% neq 0 (
    echo [INFO] Installing esptool and pyserial...
    %PY_CMD% -m pip install esptool pyserial --quiet --disable-pip-version-check
)
exit /b 0

:: ============================================================================
:: LOCATE BINARY
:: ============================================================================
:LOCATE_BINARY
set "TARGET_BIN="
if exist "binaries\%BIN_FILE%" set "TARGET_BIN=binaries\%BIN_FILE%"
if "%TARGET_BIN%"=="" (
    if exist "%BIN_FILE%" set "TARGET_BIN=%BIN_FILE%"
)
if "%TARGET_BIN%"=="" (
    if exist "release_binaries\%BIN_FILE%" set "TARGET_BIN=release_binaries\%BIN_FILE%"
)
if "%TARGET_BIN%"=="" (
    if exist "%ALT_BIN%" (
        set "TARGET_BIN=%ALT_BIN%"
        set "OFFSET=0x10000"
    )
)

if "%TARGET_BIN%"=="" (
    echo.
    echo [WARNING] Firmware binary (%BIN_FILE%) was not found locally.
    echo     Would you like to compile it now using PlatformIO?
    echo.
    set /p "BUILD_CONFIRM=Type Y to compile or N to return to menu: "
    if /i "!BUILD_CONFIRM!"=="Y" (
        echo [INFO] Compiling firmware for %BOARD_NAME%...
        pio run -e %ENV_NAME%
        if exist "%ALT_BIN%" (
            set "TARGET_BIN=%ALT_BIN%"
            set "OFFSET=0x10000"
        ) else (
            echo [ERROR] Compilation failed.
            pause
            goto MAIN_MENU
        )
    ) else (
        goto MAIN_MENU
    )
)

:: ============================================================================
:: FLASH FIRMWARE
:: ============================================================================
:START_FLASH
cls
echo ===============================================================================
echo   Flashing Firmware (Version v%VERSION%)
echo ===============================================================================
echo.
echo   - Target Board   : %BOARD_NAME%
echo   - Port           : %PORT%
echo   - Firmware File  : %TARGET_BIN%
echo   - Flash Offset   : %OFFSET%
echo.
echo [INFO] Connecting to microcontroller and writing flash...
echo     (If stuck on Connecting..., hold down the BOOT button on the ESP board)
echo.
echo -------------------------------------------------------------------------------

%PY_CMD% -m esptool --chip %CHIP% --port %PORT% --baud 460800 write_flash -z %OFFSET% "%TARGET_BIN%"

if %errorlevel% equ 0 (
    echo.
    echo ===============================================================================
    echo   [SUCCESS] Firmware flashed successfully 100%% (v%VERSION%)!
    echo   You can now unplug the board and connect it to your TV HDMI port.
    echo ===============================================================================
    echo.
    pause
    goto MAIN_MENU
)

echo.
echo [WARNING] High-speed flashing failed. Retrying at stable speed (115200 baud)...
echo     (Hold down the BOOT button on the ESP board now)
echo.
timeout /t 2 >nul

%PY_CMD% -m esptool --chip %CHIP% --port %PORT% --baud 115200 write_flash -z %OFFSET% "%TARGET_BIN%"

if %errorlevel% equ 0 (
    echo.
    echo ===============================================================================
    echo   [SUCCESS] Firmware flashed successfully 100%% (v%VERSION%)!
    echo ===============================================================================
    echo.
    pause
    goto MAIN_MENU
) else (
    echo.
    echo [ERROR] Could not connect to chip. Please check:
    echo   1. Hold the BOOT button while connecting.
    echo   2. Ensure the USB cable supports data.
    echo   3. Verify the correct COM port is selected.
    echo.
    pause
    goto MAIN_MENU
)

:: ============================================================================
:: ERASE FLASH
:: ============================================================================
:ERASE_MENU
cls
echo ===============================================================================
echo   Full Chip Erase
echo ===============================================================================
echo.
call :LIST_ALL_PORTS
if "%PORT_COUNT%"=="0" (
    echo [WARNING] No COM ports detected.
    pause
    goto MAIN_MENU
)

echo.
set /p "ERASE_PORT_SEL=Select port to erase [1-%PORT_COUNT%]: "
if defined PORT_NAME_%ERASE_PORT_SEL% (
    set "ERASE_PORT=!PORT_NAME_%ERASE_PORT_SEL%!"
) else (
    set "ERASE_PORT=%ERASE_PORT_SEL%"
)

if "%ERASE_PORT%"=="" (
    echo [ERROR] Invalid port selection.
    pause
    goto MAIN_MENU
)

call :ENSURE_PYTHON_READY
if %errorlevel% neq 0 goto MAIN_MENU

echo.
echo [INFO] Erasing entire flash on %ERASE_PORT%...
%PY_CMD% -m esptool --port %ERASE_PORT% erase_flash
echo.
echo [SUCCESS] Flash erased successfully.
pause
goto MAIN_MENU

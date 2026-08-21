@echo off
chcp 65001 >nul
title Universal TV Power Restore Flasher v1.2.0
color 0B
setlocal enabledelayedexpansion

set "VERSION=1.2.0"

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
echo     Universal TV Power Restore Flasher - Tool v%VERSION%
echo ===============================================================================
echo.
echo  --- ESP Microcontrollers ---
echo  [1] Auto-detect COM port and Flash
echo  [2] Flash ESP32 WROOM / DevKit v1
echo  [3] Flash ESP32-C3 Super Mini
echo  [4] Flash ESP32-S2
echo  [5] Flash ESP32-S3
echo  [6] Flash ESP8266 (NodeMCU / Wemos)
echo.
echo  --- Arduino and Raspberry Pi ---
echo  [7] Flash Arduino Uno (ATmega328P .hex)
echo  [8] Flash Arduino Nano (ATmega328P .hex)
echo  [9] Flash Raspberry Pi Pico (RP2040 .uf2)
echo.
echo  --- Online Updates and Maintenance ---
echo  [10] Check for Updates / Download Latest Firmware
echo  [11] Read ESP Chip Info / MAC Address
echo  [12] Full Chip Erase (ESP only)
echo  [13] Exit
echo.
echo ===============================================================================
set "CHOICE="
set /p "CHOICE=Select an option [1-13]: "

if "%CHOICE%"=="1" goto AUTO_DETECT_AND_FLASH
if "%CHOICE%"=="2" goto SELECT_ESP32
if "%CHOICE%"=="3" goto SELECT_ESP32C3
if "%CHOICE%"=="4" goto SELECT_ESP32S2
if "%CHOICE%"=="5" goto SELECT_ESP32S3
if "%CHOICE%"=="6" goto SELECT_ESP8266
if "%CHOICE%"=="7" goto SELECT_ARDUINO_UNO
if "%CHOICE%"=="8" goto SELECT_ARDUINO_NANO
if "%CHOICE%"=="9" goto SELECT_RPI_PICO
if "%CHOICE%"=="10" goto CHECK_FOR_UPDATES
if "%CHOICE%"=="11" goto READ_CHIP_INFO
if "%CHOICE%"=="12" goto ERASE_MENU
if "%CHOICE%"=="13" goto EXIT_SCRIPT

echo [WARNING] Invalid option. Please enter a number from 1 to 13.
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

:SELECT_ARDUINO_UNO
set "BOARD_NAME=Arduino Uno (ATmega328P)"
set "HEX_FILE=Arduino_Uno_Firmware.hex"
set "ALT_HEX=.pio\build\uno\firmware.hex"
set "ENV_NAME=uno"
set "BAUD=115200"
goto FLASH_ARDUINO_FLOW

:SELECT_ARDUINO_NANO
set "BOARD_NAME=Arduino Nano (ATmega328P)"
set "HEX_FILE=Arduino_Nano_Firmware.hex"
set "ALT_HEX=.pio\build\nanoatmega328\firmware.hex"
set "ENV_NAME=nanoatmega328"
set "BAUD=115200"
goto FLASH_ARDUINO_FLOW

:SELECT_RPI_PICO
set "BOARD_NAME=Raspberry Pi Pico (RP2040)"
set "UF2_FILE=RaspberryPi_Pico_Firmware.uf2"
set "ALT_UF2=.pio\build\pico\firmware.uf2"
set "ENV_NAME=pico"
goto FLASH_PICO_FLOW

:EXIT_SCRIPT
echo.
echo Thank you for using Universal TV Power Restore Flasher. Goodbye.
exit /b 0

:: ============================================================================
:: 10. CHECK FOR UPDATES & DOWNLOAD LATEST FIRMWARE FROM GITHUB
:: ============================================================================
:CHECK_FOR_UPDATES
cls
echo ===============================================================================
echo     Checking for Updates on GitHub...
echo ===============================================================================
echo.
echo [*] Current Local Version: v%VERSION%
echo [*] Connecting to GitHub API...
echo.

set "LATEST_TAG="
for /f "usebackq delims=" %%V in (`powershell -NoProfile -Command "$r = Invoke-RestMethod -Uri 'https://api.github.com/repos/HAY2023/tv-power-restore/releases/latest' -Headers @{'User-Agent'='BatchUpdater'} -TimeoutSec 10; Write-Output $r.tag_name" 2^>nul`) do (
    set "LATEST_TAG=%%V"
)

if "%LATEST_TAG%"=="" (
    echo [WARNING] Could not connect to GitHub API or no releases published yet.
    echo           Please check your internet connection or visit:
    echo           https://github.com/HAY2023/tv-power-restore/releases
    echo.
    pause
    goto MAIN_MENU
)

echo [INFO] Latest GitHub Release available: !LATEST_TAG!
echo.

if /i "!LATEST_TAG!"=="v%VERSION%" (
    echo [SUCCESS] You are already using the latest version (v%VERSION%).
    echo.
    set /p "FORCE_DL=Would you like to re-download all latest firmware files? (Y/N): "
    if /i not "!FORCE_DL!"=="Y" goto MAIN_MENU
) else (
    echo [INFO] A new release (!LATEST_TAG!) is available!
    echo.
    set /p "DL_CONFIRM=Download all latest firmware binaries now? (Y/N): "
    if /i not "!DL_CONFIRM!"=="Y" goto MAIN_MENU
)

echo.
echo [*] Downloading latest firmware files from GitHub into binaries folder...

if not exist "binaries" mkdir binaries

powershell -NoProfile -Command "$r = Invoke-RestMethod -Uri 'https://api.github.com/repos/HAY2023/tv-power-restore/releases/latest' -Headers @{'User-Agent'='BatchUpdater'}; foreach ($a in $r.assets) { Write-Host ('[*] Downloading ' + $a.name + '...'); Invoke-WebRequest -Uri $a.browser_download_url -OutFile ('binaries/' + $a.name) }"

echo.
echo [SUCCESS] All firmware files downloaded successfully into binaries folder!
echo.
pause
goto MAIN_MENU

:: ============================================================================
:: 1. AUTO DETECT AND FLASH (ESP)
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
echo  [6] Arduino Uno (ATmega328P)
echo  [7] Arduino Nano (ATmega328P)
echo  [8] Cancel and return to main menu
echo.
set /p "BOARD_SEL=Select board [1-8]: "

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
if "%BOARD_SEL%"=="6" (
    set "BOARD_NAME=Arduino Uno (ATmega328P)"
    set "HEX_FILE=Arduino_Uno_Firmware.hex"
    set "ALT_HEX=.pio\build\uno\firmware.hex"
    set "ENV_NAME=uno"
    set "PORT=%SELECTED_PORT%"
    set "BAUD=115200"
    goto START_ARDUINO_FLASH
)
if "%BOARD_SEL%"=="7" (
    set "BOARD_NAME=Arduino Nano (ATmega328P)"
    set "HEX_FILE=Arduino_Nano_Firmware.hex"
    set "ALT_HEX=.pio\build\nanoatmega328\firmware.hex"
    set "ENV_NAME=nanoatmega328"
    set "PORT=%SELECTED_PORT%"
    set "BAUD=115200"
    goto START_ARDUINO_FLASH
)
goto MAIN_MENU

:: ============================================================================
:: ARDUINO FLASH FLOW
:: ============================================================================
:FLASH_ARDUINO_FLOW
cls
echo ===============================================================================
echo     Select Port for: %BOARD_NAME%
echo ===============================================================================
echo.

call :LIST_ALL_PORTS

if "%PORT_COUNT%"=="0" (
    echo.
    echo [WARNING] No Arduino boards detected on COM ports.
    echo     Please connect your Arduino board via USB.
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
) else (
    set /p "PORT_SEL=Select port [1-%PORT_COUNT%] or type port directly: "
    if defined PORT_NAME_!PORT_SEL! (
        set "PORT=!PORT_NAME_%PORT_SEL%!"
    ) else (
        set "PORT=!PORT_SEL!"
    )
)

:START_ARDUINO_FLASH
cls
echo ===============================================================================
echo   Flashing Arduino (%BOARD_NAME%)
echo ===============================================================================
echo.

:: Locate Hex file
set "TARGET_HEX="
if exist "binaries\%HEX_FILE%" set "TARGET_HEX=binaries\%HEX_FILE%"
if "%TARGET_HEX%"=="" (
    if exist "%HEX_FILE%" set "TARGET_HEX=%HEX_FILE%"
)
if "%TARGET_HEX%"=="" (
    if exist "release_binaries\%HEX_FILE%" set "TARGET_HEX=release_binaries\%HEX_FILE%"
)
if "%TARGET_HEX%"=="" (
    if exist "%ALT_HEX%" set "TARGET_HEX=%ALT_HEX%"
)

if "%TARGET_HEX%"=="" (
    echo [WARNING] Hex file (%HEX_FILE%) was not found locally.
    echo.
    echo  [1] Download %HEX_FILE% directly from GitHub Releases
    echo  [2] Compile locally using PlatformIO
    echo  [3] Return to main menu
    echo.
    set /p "DL_OR_BUILD=Choose option [1-3]: "
    if "!DL_OR_BUILD!"=="1" (
        echo [*] Downloading %HEX_FILE% from GitHub...
        if not exist "binaries" mkdir binaries
        powershell -NoProfile -Command "Invoke-WebRequest -Uri 'https://github.com/HAY2023/tv-power-restore/releases/latest/download/%HEX_FILE%' -OutFile 'binaries/%HEX_FILE%'"
        if exist "binaries\%HEX_FILE%" (
            set "TARGET_HEX=binaries\%HEX_FILE%"
            echo [SUCCESS] Download complete!
        ) else (
            echo [ERROR] Download failed. Please check your internet connection.
            pause
            goto MAIN_MENU
        )
    ) else if "!DL_OR_BUILD!"=="2" (
        echo [INFO] Compiling firmware for %BOARD_NAME%...
        pio run -e %ENV_NAME%
        if exist "%ALT_HEX%" (
            set "TARGET_HEX=%ALT_HEX%"
        ) else (
            echo [ERROR] Compilation failed.
            pause
            goto MAIN_MENU
        )
    ) else (
        goto MAIN_MENU
    )
)

echo   - Target Board : %BOARD_NAME%
echo   - COM Port     : %PORT%
echo   - Hex File     : %TARGET_HEX%
echo.

:: Check for avrdude in PATH
where avrdude >nul 2>&1
if %errorlevel% equ 0 (
    echo [*] Using avrdude to flash %PORT%...
    avrdude -c arduino -p m328p -P %PORT% -b %BAUD% -D -U flash:w:"%TARGET_HEX%":i
    if !errorlevel! equ 0 (
        echo.
        echo [SUCCESS] Arduino flashed successfully!
        pause
        goto MAIN_MENU
    )
    echo [WARNING] Retrying with 57600 baud (Nano Old Bootloader)...
    avrdude -c arduino -p m328p -P %PORT% -b 57600 -D -U flash:w:"%TARGET_HEX%":i
    if !errorlevel! equ 0 (
        echo.
        echo [SUCCESS] Arduino flashed successfully!
        pause
        goto MAIN_MENU
    )
)

echo.
echo ===============================================================================
echo [INFO] Firmware file is ready: %TARGET_HEX%
echo To flash your Arduino:
echo   1. Use XLoader / AVRDUDESS to upload "%TARGET_HEX%" to %PORT%.
echo   2. Or install PlatformIO and run: pio run -e %ENV_NAME% -t upload
echo ===============================================================================
echo.
pause
goto MAIN_MENU

:: ============================================================================
:: RASPBERRY PI PICO FLOW
:: ============================================================================
:FLASH_PICO_FLOW
cls
echo ===============================================================================
echo   Flashing Raspberry Pi Pico (RP2040)
echo ===============================================================================
echo.

:: Locate UF2 file
set "TARGET_UF2="
if exist "binaries\%UF2_FILE%" set "TARGET_UF2=binaries\%UF2_FILE%"
if "%TARGET_UF2%"=="" (
    if exist "%UF2_FILE%" set "TARGET_UF2=%UF2_FILE%"
)
if "%TARGET_UF2%"=="" (
    if exist "release_binaries\%UF2_FILE%" set "TARGET_UF2=release_binaries\%UF2_FILE%"
)
if "%TARGET_UF2%"=="" (
    if exist "%ALT_UF2%" set "TARGET_UF2=%ALT_UF2%"
)

if "%TARGET_UF2%"=="" (
    echo [WARNING] UF2 file (%UF2_FILE%) was not found locally.
    echo.
    echo  [1] Download %UF2_FILE% directly from GitHub Releases
    echo  [2] Compile locally using PlatformIO
    echo  [3] Return to main menu
    echo.
    set /p "DL_OR_BUILD=Choose option [1-3]: "
    if "!DL_OR_BUILD!"=="1" (
        echo [*] Downloading %UF2_FILE% from GitHub...
        if not exist "binaries" mkdir binaries
        powershell -NoProfile -Command "Invoke-WebRequest -Uri 'https://github.com/HAY2023/tv-power-restore/releases/latest/download/%UF2_FILE%' -OutFile 'binaries/%UF2_FILE%'"
        if exist "binaries\%UF2_FILE%" (
            set "TARGET_UF2=binaries\%UF2_FILE%"
            echo [SUCCESS] Download complete!
        ) else (
            echo [ERROR] Download failed. Please check your internet connection.
            pause
            goto MAIN_MENU
        )
    ) else if "!DL_OR_BUILD!"=="2" (
        echo [INFO] Compiling firmware for Raspberry Pi Pico...
        pio run -e pico
        if exist "%ALT_UF2%" (
            set "TARGET_UF2=%ALT_UF2%"
        ) else (
            echo [ERROR] Compilation failed.
            pause
            goto MAIN_MENU
        )
    ) else (
        goto MAIN_MENU
    )
)

echo [INFO] Searching for Raspberry Pi Pico in BOOTSEL mode (RPI-RP2 drive)...
set "PICO_DRIVE="
for /f "usebackq" %%D in (`powershell -NoProfile -Command "Get-Volume ^| Where-Object { $_.FileSystemLabel -eq 'RPI-RP2' } ^| Select-Object -ExpandProperty DriveLetter" 2^>nul`) do (
    set "PICO_DRIVE=%%D"
)

if not "%PICO_DRIVE%"=="" (
    echo [INFO] Detected Pico storage drive at: %PICO_DRIVE%:\
    echo [*] Copying %TARGET_UF2% to %PICO_DRIVE%:\ ...
    copy /Y "%TARGET_UF2%" "%PICO_DRIVE%:\" >nul
    if !errorlevel! equ 0 (
        echo.
        echo ===============================================================================
        echo   [SUCCESS] Raspberry Pi Pico flashed successfully (UF2 transferred)!
        echo   The Pico will now reboot and run the TV Autostart firmware.
        echo ===============================================================================
        echo.
        pause
        goto MAIN_MENU
    )
)

echo.
echo [INFO] Pico was not found in BOOTSEL storage mode.
echo How to flash:
echo   1. Hold the BOOTSEL button on your Pico while plugging the USB cable into PC.
echo   2. A new drive named 'RPI-RP2' will appear in File Explorer.
echo   3. Drag and drop "%TARGET_UF2%" into the 'RPI-RP2' drive!
echo.
pause
goto MAIN_MENU

:: ============================================================================
:: PORT SELECTION HELPER (ESP)
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
:: READ CHIP INFO (ESP)
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
:: LOCATE BINARY (ESP)
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
    echo.
    echo  [1] Download %BIN_FILE% directly from GitHub Releases
    echo  [2] Compile locally using PlatformIO
    echo  [3] Return to main menu
    echo.
    set /p "DL_OR_BUILD=Choose option [1-3]: "
    if "!DL_OR_BUILD!"=="1" (
        echo [*] Downloading %BIN_FILE% from GitHub...
        if not exist "binaries" mkdir binaries
        powershell -NoProfile -Command "Invoke-WebRequest -Uri 'https://github.com/HAY2023/tv-power-restore/releases/latest/download/%BIN_FILE%' -OutFile 'binaries/%BIN_FILE%'"
        if exist "binaries\%BIN_FILE%" (
            set "TARGET_BIN=binaries\%BIN_FILE%"
            echo [SUCCESS] Download complete!
        ) else (
            echo [ERROR] Download failed. Please check your internet connection.
            pause
            goto MAIN_MENU
        )
    ) else if "!DL_OR_BUILD!"=="2" (
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
:: FLASH FIRMWARE (ESP)
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
:: ERASE FLASH (ESP)
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

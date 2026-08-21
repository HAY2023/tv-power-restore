#pragma once
#include <Arduino.h>

// =============================================================================
// Project Configuration & Pin Definitions
// =============================================================================
// PRIMARY TARGET BOARD: ESP32 WROOM (DevKit v1) - Default
// SECONDARY TARGET (Optional): ESP32-C3 Super Mini / DevKitM-1
// =============================================================================

#define FIRMWARE_VERSION "1.1.0"

#ifdef BOARD_NAME
#undef BOARD_NAME
#endif

#if defined(BOARD_ESP32_C3)
    // Secondary Target: ESP32-C3 Super Mini
    #define DEFAULT_CEC_PIN      3   // GPIO3
    #define DEFAULT_I2C_SDA_PIN  8   // GPIO8
    #define DEFAULT_I2C_SCL_PIN  9   // GPIO9
    #define BOARD_NAME           "ESP32-C3 Super Mini"
#elif defined(BOARD_ESP32_S2)
    #define DEFAULT_CEC_PIN      4
    #define DEFAULT_I2C_SDA_PIN  8
    #define DEFAULT_I2C_SCL_PIN  9
    #define BOARD_NAME           "ESP32-S2"
#elif defined(BOARD_ESP32_S3)
    #define DEFAULT_CEC_PIN      4
    #define DEFAULT_I2C_SDA_PIN  8
    #define DEFAULT_I2C_SCL_PIN  9
    #define BOARD_NAME           "ESP32-S3"
#elif defined(BOARD_ESP8266)
    #define DEFAULT_CEC_PIN      14  // D5
    #define DEFAULT_I2C_SDA_PIN  4   // D2
    #define DEFAULT_I2C_SCL_PIN  5   // D1
    #define BOARD_NAME           "ESP8266"
#elif defined(BOARD_ARDUINO_AVR)
    #define DEFAULT_CEC_PIN      2   // D2
    #define DEFAULT_I2C_SDA_PIN  SDA // A4 (Uno/Nano)
    #define DEFAULT_I2C_SCL_PIN  SCL // A5 (Uno/Nano)
    #define BOARD_NAME           "Arduino AVR (Uno/Nano)"
#elif defined(BOARD_RPI_PICO)
    #define DEFAULT_CEC_PIN      2   // GP2
    #define DEFAULT_I2C_SDA_PIN  4   // GP4
    #define DEFAULT_I2C_SCL_PIN  5   // GP5
    #define BOARD_NAME           "Raspberry Pi Pico"
#else
    // Primary Target: Standard ESP32 WROOM (DevKit v1) - DEFAULT
    #define DEFAULT_CEC_PIN      4   // GPIO4
    #define DEFAULT_I2C_SDA_PIN  21  // GPIO21
    #define DEFAULT_I2C_SCL_PIN  22  // GPIO22
    #define BOARD_NAME           "ESP32 WROOM DevKit v1"
#endif

// HDMI-CEC Line GPIO Pin
constexpr uint8_t PIN_CEC = DEFAULT_CEC_PIN;

// I2C Bus Pins for DS3231 RTC Module
constexpr uint8_t PIN_SDA = DEFAULT_I2C_SDA_PIN;
constexpr uint8_t PIN_SCL = DEFAULT_I2C_SCL_PIN;

// Startup delay before transmitting CEC wake-up commands (in seconds)
// Allows the TV mainboard and standby power supply to fully stabilize and listen for CEC.
constexpr uint32_t WAIT_SECONDS = 15;

// HDMI Physical Address:
// Port 1 = 0x1000, Port 2 = 0x2000, Port 3 = 0x3000, Port 4 = 0x4000
// Default: 0x1000 (HDMI Port 1 directly on TV)
constexpr uint16_t HDMI_PHYSICAL_ADDRESS = 0x1000;

// CEC Logical Addresses according to HDMI 1.4 specification
// Initiator: 0x04 = Playback Device 1 (e.g. Media Player / ESP32)
// Destination: 0x00 = TV Display
// Destination: 0x0F = Broadcast (all devices on CEC bus)
constexpr uint8_t CEC_LOGICAL_PLAYBACK_1 = 0x04;
constexpr uint8_t CEC_LOGICAL_TV         = 0x00;
constexpr uint8_t CEC_LOGICAL_BROADCAST  = 0x0F;

// AT24C32 EEPROM I2C Address (commonly mounted alongside DS3231 on RTC modules)
constexpr uint8_t AT24C32_I2C_ADDRESS = 0x57;

// Non-volatile storage memory layout for last power-on timestamp
constexpr uint16_t EEPROM_MAGIC_ADDR    = 0x0000; // 4 bytes magic key (0x54564345 = "TVCE")
constexpr uint16_t EEPROM_TIMESTAMP_ADDR = 0x0004; // 4 bytes UNIX timestamp
constexpr uint32_t EEPROM_MAGIC_KEY     = 0x54564345;

// Serial Monitor Diagnostics Baud Rate
constexpr uint32_t SERIAL_BAUD_RATE = 115200;

// -------------------------------------------------------------
// Debug Print Wrapper (AVR does not support Serial.printf natively)
// -------------------------------------------------------------
#if defined(ESP32) || defined(ESP8266)
  #define DEBUG_PRINTF(fmt, ...) Serial.printf(fmt, ##__VA_ARGS__)
#else
  #define DEBUG_PRINTF(fmt, ...) do { \
      char _buf[128]; \
      snprintf(_buf, sizeof(_buf), (fmt), ##__VA_ARGS__); \
      Serial.print(_buf); \
  } while(0)
#endif

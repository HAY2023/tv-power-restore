#include "rtc_storage.h"
#include "config.h"
#include <Wire.h>
#if defined(ESP32)
#include <Preferences.h>
static Preferences preferences;
#endif

RtcStorage::RtcStorage(uint8_t sdaPin, uint8_t sclPin)
    : _sdaPin(sdaPin), _sclPin(sclPin), _rtcOnline(false), _eepromOnline(false) {}

bool RtcStorage::begin() {
    Serial.printf("[RTC] Initializing I2C bus (SDA: GPIO%d, SCL: GPIO%d)...\n", _sdaPin, _sclPin);
    Wire.begin(_sdaPin, _sclPin);
    delay(50);

    // 1. Initialize DS3231 RTC
    if (!_rtc.begin()) {
        Serial.println(F("[RTC] ERROR: Could not find DS3231 RTC module! Check I2C wiring and pull-ups."));
        _rtcOnline = false;
    } else {
        _rtcOnline = true;
        Serial.println(F("[RTC] DS3231 RTC module connected successfully."));

        if (_rtc.lostPower()) {
            Serial.println(F("[RTC] WARNING: DS3231 lost power! The CR2032 battery may be missing or depleted."));
            Serial.println(F("[RTC] Setting initial default RTC time to compilation time."));
            _rtc.adjust(DateTime(F(__DATE__), F(__TIME__)));
        }
    }

    // 2. Test AT24C32 EEPROM presence at I2C address 0x57
    Wire.beginTransmission(AT24C32_I2C_ADDRESS);
    if (Wire.endTransmission() == 0) {
        _eepromOnline = true;
        Serial.printf("[RTC] AT24C32 EEPROM detected at 0x%02X.\n", AT24C32_I2C_ADDRESS);
    } else {
        _eepromOnline = false;
        Serial.println(F("[RTC] AT24C32 EEPROM not found at 0x57. Using ESP32 internal NVS as fallback storage."));
    }

    return _rtcOnline;
}

bool RtcStorage::lostPower() {
    if (!_rtcOnline) return true;
    return _rtc.lostPower();
}

bool RtcStorage::getCurrentTime(DateTime& outTime) {
    if (!_rtcOnline) {
        return false;
    }
    outTime = _rtc.now();
    return outTime.isValid();
}

bool RtcStorage::writeEepromBytes(uint16_t memoryAddress, const uint8_t* data, size_t length) {
    if (!_eepromOnline) return false;

    Wire.beginTransmission(AT24C32_I2C_ADDRESS);
    Wire.write((uint8_t)(memoryAddress >> 8));   // High memory address byte
    Wire.write((uint8_t)(memoryAddress & 0xFF));  // Low memory address byte
    for (size_t i = 0; i < length; ++i) {
        Wire.write(data[i]);
    }
    uint8_t result = Wire.endTransmission();
    delay(10); // Standard EEPROM self-timed write cycle (max 10ms)
    return (result == 0);
}

bool RtcStorage::readEepromBytes(uint16_t memoryAddress, uint8_t* data, size_t length) {
    if (!_eepromOnline) return false;

    Wire.beginTransmission(AT24C32_I2C_ADDRESS);
    Wire.write((uint8_t)(memoryAddress >> 8));   // High memory address byte
    Wire.write((uint8_t)(memoryAddress & 0xFF));  // Low memory address byte
    if (Wire.endTransmission() != 0) {
        return false;
    }

    size_t received = Wire.requestFrom(static_cast<uint8_t>(AT24C32_I2C_ADDRESS), static_cast<uint8_t>(length));
    if (received != length) {
        return false;
    }

    for (size_t i = 0; i < length; ++i) {
        data[i] = Wire.read();
    }
    return true;
}

bool RtcStorage::saveTimestampToNvs(uint32_t timestamp) {
#if defined(ESP32)
    preferences.begin("tv-autostart", false);
    preferences.putUInt("magic", EEPROM_MAGIC_KEY);
    preferences.putUInt("last_boot", timestamp);
    preferences.end();
    return true;
#else
    return false;
#endif
}

bool RtcStorage::readTimestampFromNvs(uint32_t& timestamp) {
#if defined(ESP32)
    preferences.begin("tv-autostart", true);
    uint32_t magic = preferences.getUInt("magic", 0);
    if (magic != EEPROM_MAGIC_KEY) {
        preferences.end();
        return false;
    }
    timestamp = preferences.getUInt("last_boot", 0);
    preferences.end();
    return (timestamp > 0);
#else
    return false;
#endif
}

bool RtcStorage::calculateOutage(OutageInfo& outInfo) {
    outInfo.validPreviousBoot = false;
    outInfo.previousBootTime = 0;
    outInfo.currentBootTime = 0;
    outInfo.outageDurationSec = 0;
    outInfo.days = 0;
    outInfo.hours = 0;
    outInfo.minutes = 0;
    outInfo.seconds = 0;

    if (!_rtcOnline) {
        Serial.println(F("[RTC] Cannot calculate outage: RTC offline."));
        return false;
    }

    DateTime now = _rtc.now();
    outInfo.currentBootTime = now.unixtime();

    // Attempt to read from AT24C32 EEPROM first
    bool foundValidTimestamp = false;
    uint32_t storedTimestamp = 0;

    if (_eepromOnline) {
        uint32_t storedMagic = 0;
        if (readEepromBytes(EEPROM_MAGIC_ADDR, reinterpret_cast<uint8_t*>(&storedMagic), sizeof(storedMagic))) {
            if (storedMagic == EEPROM_MAGIC_KEY) {
                if (readEepromBytes(EEPROM_TIMESTAMP_ADDR, reinterpret_cast<uint8_t*>(&storedTimestamp), sizeof(storedTimestamp))) {
                    foundValidTimestamp = true;
                }
            }
        }
    }

    // If external EEPROM was not available or empty, check internal NVS
    if (!foundValidTimestamp) {
        if (readTimestampFromNvs(storedTimestamp)) {
            foundValidTimestamp = true;
        }
    }

    if (foundValidTimestamp && storedTimestamp > 0) {
        outInfo.validPreviousBoot = true;
        outInfo.previousBootTime = storedTimestamp;

        if (outInfo.currentBootTime >= outInfo.previousBootTime) {
            outInfo.outageDurationSec = outInfo.currentBootTime - outInfo.previousBootTime;
        } else {
            // Clock was adjusted backward or battery glitch
            outInfo.outageDurationSec = 0;
        }

        uint32_t rem = outInfo.outageDurationSec;
        outInfo.days = rem / 86400;
        rem %= 86400;
        outInfo.hours = rem / 3600;
        rem %= 3600;
        outInfo.minutes = rem / 60;
        outInfo.seconds = rem % 60;
    }

    return true;
}

bool RtcStorage::saveBootTimestamp(uint32_t currentTimestamp) {
    bool eepromSuccess = false;

    if (_eepromOnline) {
        uint32_t magic = EEPROM_MAGIC_KEY;
        bool magicOk = writeEepromBytes(EEPROM_MAGIC_ADDR, reinterpret_cast<const uint8_t*>(&magic), sizeof(magic));
        bool tsOk = writeEepromBytes(EEPROM_TIMESTAMP_ADDR, reinterpret_cast<const uint8_t*>(&currentTimestamp), sizeof(currentTimestamp));
        eepromSuccess = (magicOk && tsOk);
    }

    // Always mirror to NVS for maximum redundancy
    bool nvsSuccess = saveTimestampToNvs(currentTimestamp);

    if (eepromSuccess || nvsSuccess) {
        Serial.printf("[RTC] Boot timestamp [%u] saved successfully to %s.\n", 
                      currentTimestamp, 
                      eepromSuccess ? "AT24C32 EEPROM & NVS" : "Internal NVS");
        return true;
    } else {
        Serial.println(F("[RTC] ERROR: Failed to persist boot timestamp!"));
        return false;
    }
}

void RtcStorage::printDateTime(const DateTime& dt) {
    char buf[32];
    snprintf(buf, sizeof(buf), "%04d-%02d-%02d %02d:%02d:%02d", 
             dt.year(), dt.month(), dt.day(), 
             dt.hour(), dt.minute(), dt.second());
    Serial.print(buf);
}

void RtcStorage::printOutageReport(const OutageInfo& info) {
    Serial.println(F("=================================================="));
    Serial.println(F("            POWER & OUTAGE DIAGNOSTICS            "));
    Serial.println(F("=================================================="));

    DateTime nowDt(info.currentBootTime);
    Serial.print(F("Current Power-On Time : "));
    printDateTime(nowDt);
    Serial.printf(" (UNIX: %u)\n", info.currentBootTime);

    if (info.validPreviousBoot) {
        DateTime prevDt(info.previousBootTime);
        Serial.print(F("Last Recorded Boot    : "));
        printDateTime(prevDt);
        Serial.printf(" (UNIX: %u)\n", info.previousBootTime);

        Serial.println(F("--------------------------------------------------"));
        Serial.printf("Calculated Outage     : %d days, %02d hrs, %02d min, %02d sec\n",
                      info.days, info.hours, info.minutes, info.seconds);
        Serial.printf("Total Duration        : %u seconds\n", info.outageDurationSec);
    } else {
        Serial.println(F("Last Recorded Boot    : [None / First Run / Storage Cleared]"));
        Serial.println(F("Calculated Outage     : First boot detected."));
    }
    Serial.println(F("=================================================="));
}

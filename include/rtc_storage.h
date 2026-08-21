#pragma once
#include <Arduino.h>
#include <RTClib.h>

/**
 * @brief Outage Information Result Structure
 */
struct OutageInfo {
    bool validPreviousBoot;       // True if a valid prior timestamp was found
    uint32_t previousBootTime;    // UNIX timestamp of previous power-on
    uint32_t currentBootTime;     // UNIX timestamp of current power-on
    uint32_t outageDurationSec;   // Outage duration in seconds
    int days;
    int hours;
    int minutes;
    int seconds;
};

class RtcStorage {
public:
    RtcStorage(uint8_t sdaPin, uint8_t sclPin);

    /**
     * @brief Initialize I2C bus, DS3231 RTC, and AT24C32 EEPROM
     * @return true if RTC initialized and valid, false otherwise
     */
    bool begin();

    /**
     * @brief Read current time from DS3231
     * @param outTime Output DateTime object
     * @return true on success, false on I2C/RTC error
     */
    bool getCurrentTime(DateTime& outTime);

    /**
     * @brief Calculate the outage duration by comparing current RTC time with stored previous boot time
     * @param outInfo Populated OutageInfo structure
     * @return true if calculation succeeded
     */
    bool calculateOutage(OutageInfo& outInfo);

    /**
     * @brief Save the current boot timestamp to non-volatile storage (AT24C32 EEPROM / NVS)
     * @param currentTimestamp UNIX timestamp to persist
     * @return true on success, false on write error
     */
    bool saveBootTimestamp(uint32_t currentTimestamp);

    /**
     * @brief Print human-readable time and outage diagnostics to Serial
     * @param dt DateTime to format
     */
    void printDateTime(const DateTime& dt);
    void printOutageReport(const OutageInfo& info);

    /**
     * @brief Check if RTC lost power (e.g. dead or missing CR2032 coin battery)
     */
    bool lostPower();

private:
    uint8_t _sdaPin;
    uint8_t _sclPin;
    RTC_DS3231 _rtc;
    bool _rtcOnline;
    bool _eepromOnline;

    // Low-level AT24C32 EEPROM operations
    bool writeEepromBytes(uint16_t memoryAddress, const uint8_t* data, size_t length);
    bool readEepromBytes(uint16_t memoryAddress, uint8_t* data, size_t length);

    // Fallback using ESP32 NVS (Non-Volatile Storage) if external EEPROM not mounted
    bool saveTimestampToNvs(uint32_t timestamp);
    bool readTimestampFromNvs(uint32_t& timestamp);
};

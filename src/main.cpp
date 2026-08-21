#include <Arduino.h>
#include "config.h"
#include "cec_engine.h"
#include "rtc_storage.h"

// Instantiate driver objects
static CecEngine cec(PIN_CEC);
static RtcStorage rtcStore(PIN_SDA, PIN_SCL);

void setup() {
    // 1. Initialize Serial for diagnostics
    Serial.begin(SERIAL_BAUD_RATE);
    delay(1000); // Allow USB CDC / UART to stabilize

    Serial.println();
    Serial.println(F("##################################################"));
    Serial.println(F("#       ESP32 HDMI-CEC TV AUTOSTART SYSTEM       #"));
    Serial.println(F("#      Standalone Power-Restoration Trigger      #"));
    Serial.println(F("##################################################"));
    Serial.printf("[SYSTEM] Firmware build: %s %s\n", __DATE__, __TIME__);
    Serial.printf("[SYSTEM] Configured CEC Pin: GPIO%d | SDA: GPIO%d | SCL: GPIO%d\n", PIN_CEC, PIN_SDA, PIN_SCL);
    Serial.printf("[SYSTEM] Wait delay before CEC trigger: %u seconds\n", WAIT_SECONDS);
    Serial.printf("[SYSTEM] Target HDMI Physical Address: 0x%04X\n", HDMI_PHYSICAL_ADDRESS);
    Serial.println(F("--------------------------------------------------"));

    // 2. Initialize CEC line hardware
    cec.begin();

    // 3. Initialize RTC & EEPROM / NVS Storage
    bool rtcReady = rtcStore.begin();
    if (!rtcReady) {
        Serial.println(F("[ERROR] RTC module initialization failed! Continuing with CEC sequence anyway..."));
    }

    // 4. Calculate and log outage duration
    OutageInfo outage{};
    if (rtcReady) {
        if (rtcStore.calculateOutage(outage)) {
            rtcStore.printOutageReport(outage);
        } else {
            Serial.println(F("[ERROR] Failed to compute power outage duration."));
        }
    }

    // 5. Wait for TV motherboard & HDMI subsystem to power on
    // Google TVs and Smart TVs typically require 10-15 seconds after AC power is restored
    // to boot their standby microcontroller and enable HDMI-CEC bus listening.
    Serial.printf("\n[TIMING] Waiting %u seconds for TV HDMI-CEC subsystem readiness...\n", WAIT_SECONDS);
    for (uint32_t sec = WAIT_SECONDS; sec > 0; --sec) {
        Serial.printf("[TIMING] Ready in %2u seconds...\r", sec);
        delay(1000);
    }
    Serial.println(F("\n[TIMING] Wait period completed. Initiating HDMI-CEC sequence."));
    Serial.println(F("--------------------------------------------------"));

    // 6. Step A: Send <Image View On> (0x04) to wake up the TV display
    Serial.println(F("[SEQUENCE 1/2] Sending <Image View On> (Opcode 0x04) to TV (0x00)..."));
    bool ivOk = cec.sendImageViewOn(CEC_LOGICAL_TV);
    if (!ivOk) {
        Serial.println(F("[WARNING] <Image View On> unacknowledged or bus was busy. Retrying with <Text View On>..."));
        delay(500); // Bus recovery pause
        cec.sendTextViewOn(CEC_LOGICAL_TV);
    }

    // Inter-frame gap: HDMI-CEC requires at least 3-7 bit times of signal free time (~15-30ms),
    // but giving 800ms allows the TV firmware state machine to transition into active mode.
    delay(800);

    // 7. Step B: Send <Active Source> (0x82) to route TV input to our HDMI port
    Serial.println(F("[SEQUENCE 2/2] Sending <Active Source> (Opcode 0x82) broadcast..."));
    bool asOk = cec.sendActiveSource(HDMI_PHYSICAL_ADDRESS);
    if (!asOk) {
        Serial.println(F("[ERROR] <Active Source> transmission encountered an error."));
    }

    // 8. Save the current boot timestamp to RTC for subsequent outage calculations
    if (rtcReady) {
        DateTime now;
        if (rtcStore.getCurrentTime(now)) {
            rtcStore.saveBootTimestamp(now.unixtime());
        }
    }

    Serial.println(F("--------------------------------------------------"));
    Serial.println(F("[SUCCESS] All startup triggers sent. Device entering idle monitoring."));
    Serial.println(F("##################################################\n"));
}

void loop() {
    // Keep power consumption minimal on HDMI Pin 18 5V rail (~50mA max spec).
    // ESP32 remains in low-duty idle.
    delay(10000);
}

#pragma once
#include <Arduino.h>

/**
 * @brief Standalone HDMI-CEC Protocol Driver for ESP32
 * 
 * HDMI-CEC (Consumer Electronics Control) is a single-wire, bidirectional, 
 * open-drain bus running at 3.3V with a bit rate of approximately 417 bits/sec.
 * 
 * TIMING SPECIFICATION (HDMI 1.4 CEC Spec / Section Supplement 1):
 * - Idle State: HIGH (pulled up to 3.3V)
 * - Start Bit: LOW for 3.7ms, HIGH for 0.8ms (Total 4.5ms)
 * - Logic '0': LOW for 1.5ms, HIGH for 0.9ms (Total 2.4ms)
 * - Logic '1': LOW for 0.6ms, HIGH for 1.8ms (Total 2.4ms)
 * - Bit Sampling point: ~1.05ms from falling edge
 * 
 * KNOWN LIMITATIONS & DESIGN NOTES:
 * 1. Bit-banging vs Interrupts: Microsecond bit-banging is rock-solid for 
 *    transmitting short CEC wake-up burst sequences on startup. During transmission, 
 *    interrupts are temporarily masked or high-priority delays are used to avoid 
 *    FreeRTOS task preemption jitter.
 * 2. Pull-up: HDMI CEC specification requires a ~27kΩ pull-up resistor to +3.3V 
 *    on the TV side. Connecting a 2.7kΩ series/protective resistor between the 
 *    ESP32 GPIO and HDMI Pin 13 ensures safe current limiting and impedance matching.
 * 3. ACK Handling: When broadcasting (<Active Source>), ACK bit is inverted by spec 
 *    (NACK=0, ACK=1). For direct messages (<Image View On>), the TV pulls the line 
 *    LOW during the ACK window to acknowledge receipt.
 */

struct CecPacket {
    uint8_t initiator;          // 4-bit logical address of source (e.g. 0x04)
    uint8_t destination;        // 4-bit logical address of target (e.g. 0x00 for TV, 0x0F for Broadcast)
    uint8_t opcode;             // CEC Opcode (e.g. 0x04 for Image View On, 0x82 for Active Source)
    uint8_t paramCount;         // Number of parameter bytes
    uint8_t params[14];         // Up to 14 parameter bytes
};

class CecEngine {
public:
    explicit CecEngine(uint8_t cecPin);

    /**
     * @brief Initialize GPIO pin for CEC open-drain operation
     */
    void begin();

    /**
     * @brief Sends <Image View On> (0x04) to turn on the TV display
     * @param dest Target logical address (default: 0x00 = TV)
     * @return true if transmitted and acknowledged, false otherwise
     */
    bool sendImageViewOn(uint8_t dest = 0x00);

    /**
     * @brief Sends <Text View On> (0x0D) to wake up display with OSD text support
     * @param dest Target logical address (default: 0x00 = TV)
     * @return true if transmitted and acknowledged, false otherwise
     */
    bool sendTextViewOn(uint8_t dest = 0x00);

    /**
     * @brief Sends <Active Source> (0x82) broadcast with 2-byte physical address
     * @param physicalAddress HDMI physical address (e.g. 0x1000 for HDMI 1)
     * @return true if transmitted successfully
     */
    bool sendActiveSource(uint16_t physicalAddress);

    /**
     * @brief Sends a generic structured CEC packet
     * @param packet CEC packet containing initiator, destination, opcode, and params
     * @return true on success
     */
    bool transmitPacket(const CecPacket& packet);

    /**
     * @brief Check if the CEC line is currently idle (HIGH)
     */
    bool isLineIdle();

    /**
     * @brief Wait for the bus to be free for at least minIdleMs
     */
    bool waitForIdleBus(uint32_t timeoutMs = 100, uint32_t minIdleMs = 20);

private:
    uint8_t _pin;

    // Low-level open-drain control
    inline void lineLow() {
        pinMode(_pin, OUTPUT);
        digitalWrite(_pin, LOW);
    }

    inline void lineRelease() {
        pinMode(_pin, INPUT_PULLUP);
    }

    inline int lineRead() {
        return digitalRead(_pin);
    }

    // Bit-level transmission functions
    void sendStartBit();
    bool sendDataByte(uint8_t data, bool isLastByte);
    void sendBit(bool bitVal);
    bool readAckBit();
};

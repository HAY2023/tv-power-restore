#include "cec_engine.h"
#include "config.h"

CecEngine::CecEngine(uint8_t cecPin) : _pin(cecPin) {}

void CecEngine::begin() {
    // Open-drain idle: pin configured as INPUT with internal pullup
    lineRelease();
    delay(10);
}

bool CecEngine::isLineIdle() {
    return lineRead() == HIGH;
}

bool CecEngine::waitForIdleBus(uint32_t timeoutMs, uint32_t minIdleMs) {
    uint32_t start = millis();
    uint32_t idleStart = 0;
    bool countingIdle = false;

    while (millis() - start < timeoutMs) {
        if (isLineIdle()) {
            if (!countingIdle) {
                countingIdle = true;
                idleStart = millis();
            } else if (millis() - idleStart >= minIdleMs) {
                return true; // Bus has been consistently idle
            }
        } else {
            countingIdle = false; // Activity detected, reset idle counter
        }
        delayMicroseconds(500);
    }
    return false;
}

/**
 * @brief CEC Start Bit
 * Specification:
 * - Low period: 3.7ms ± 0.2ms (3500 - 3900 µs)
 * - High period: 0.8ms ± 0.2ms (600 - 1000 µs)
 * - Total duration: 4.5ms ± 0.2ms
 */
void CecEngine::sendStartBit() {
    lineLow();
    delayMicroseconds(3700); // 3.7ms Low
    lineRelease();
    delayMicroseconds(800);  // 0.8ms High (total 4.5ms)
}

/**
 * @brief Sends a single data bit (0 or 1)
 * Specification:
 * - Logical '0': Low for 1500 µs, High for 900 µs (Total 2400 µs)
 * - Logical '1': Low for 600 µs,  High for 1800 µs (Total 2400 µs)
 */
void CecEngine::sendBit(bool bitVal) {
    if (bitVal) {
        // Logical '1'
        lineLow();
        delayMicroseconds(600);  // 0.6ms Low
        lineRelease();
        delayMicroseconds(1800); // 1.8ms High (total 2.4ms)
    } else {
        // Logical '0'
        lineLow();
        delayMicroseconds(1500); // 1.5ms Low
        lineRelease();
        delayMicroseconds(900);  // 0.9ms High (total 2.4ms)
    }
}

/**
 * @brief Transmit ACK bit slot and sample the line for receiver acknowledgement.
 * 
 * In HDMI-CEC:
 * - The transmitter drives the line LOW for 600 µs (like a bit 1) and releases.
 * - The receiver pulls the line LOW if it acknowledges the block.
 * - Sampling point is at 1050 µs from the falling edge (450 µs after release).
 * - Total duration must be 2400 µs.
 * 
 * @return true if line was pulled LOW (ACK received), false if line remained HIGH (NACK).
 */
bool CecEngine::readAckBit() {
    lineLow();
    delayMicroseconds(600); // Initiate bit slot
    lineRelease();
    
    // Wait until the 1050 µs sample point (600 + 450 = 1050 µs)
    delayMicroseconds(450);
    
    // Sample receiver state
    bool ack = (lineRead() == LOW);
    
    // Wait out the remainder of the 2400 µs bit period (2400 - 1050 = 1350 µs)
    delayMicroseconds(1350);
    
    return ack;
}

/**
 * @brief Sends an 8-bit data block followed by EOM and ACK bit
 * 
 * @param data 8-bit byte (MSB first)
 * @param isLastByte End-Of-Message (EOM) flag: true if this is the final block in packet
 * @return true if ACK received, false if NACK
 */
bool CecEngine::sendDataByte(uint8_t data, bool isLastByte) {
    // Send 8 data bits, MSB first
    for (int8_t i = 7; i >= 0; --i) {
        bool bit = (data >> i) & 0x01;
        sendBit(bit);
    }

    // Send EOM bit (1 = Final block, 0 = More blocks follow)
    sendBit(isLastByte);

    // Read ACK from bus
    return readAckBit();
}

/**
 * @brief Transmits a complete HDMI-CEC frame
 */
bool CecEngine::transmitPacket(const CecPacket& packet) {
    // 1. Wait for bus idle (signal free time: minimum ~20ms)
    if (!waitForIdleBus(150, 20)) {
        Serial.println(F("[CEC] Warning: Bus busy, attempting forced transmission..."));
    }

    // Disable interrupts temporarily during critical transmission timing
    portMUX_TYPE mux = portMUX_INITIALIZER_UNLOCKED;
    portENTER_CRITICAL(&mux);

    // 2. Transmit Start Bit
    sendStartBit();

    // 3. Header Block: (Initiator 4 bits) + (Destination 4 bits)
    uint8_t header = ((packet.initiator & 0x0F) << 4) | (packet.destination & 0x0F);
    bool isHeaderOnly = (packet.opcode == 0x00 && packet.paramCount == 0);
    bool headerAck = sendDataByte(header, isHeaderOnly);

    // If packet only had a header (ping), finish here
    if (isHeaderOnly) {
        portEXIT_CRITICAL(&mux);
        return headerAck;
    }

    // 4. Opcode Block
    bool isOpcodeLast = (packet.paramCount == 0);
    bool opcodeAck = sendDataByte(packet.opcode, isOpcodeLast);

    // 5. Parameter Blocks
    bool paramAck = true;
    for (uint8_t i = 0; i < packet.paramCount; ++i) {
        bool isLast = (i == packet.paramCount - 1);
        bool ack = sendDataByte(packet.params[i], isLast);
        if (!ack) {
            paramAck = false;
        }
    }

    portEXIT_CRITICAL(&mux);

    // Broadcast messages (dest = 0x0F) do not require direct ACK
    if (packet.destination == CEC_LOGICAL_BROADCAST) {
        return true;
    }

    return headerAck && opcodeAck && paramAck;
}

bool CecEngine::sendImageViewOn(uint8_t dest) {
    Serial.printf("[CEC] Sending <Image View On> (0x04) to Destination [0x%02X]...\n", dest);
    
    CecPacket pkt{};
    pkt.initiator = CEC_LOGICAL_PLAYBACK_1; // 0x04
    pkt.destination = dest;                  // 0x00 (TV)
    pkt.opcode = 0x04;                      // <Image View On>
    pkt.paramCount = 0;

    bool success = transmitPacket(pkt);
    if (success) {
        Serial.println(F("[CEC] <Image View On> sent and ACK received successfully."));
    } else {
        Serial.println(F("[CEC] <Image View On> sent (No ACK or broadcast response)."));
    }
    return success;
}

bool CecEngine::sendTextViewOn(uint8_t dest) {
    Serial.printf("[CEC] Sending <Text View On> (0x0D) to Destination [0x%02X]...\n", dest);
    
    CecPacket pkt{};
    pkt.initiator = CEC_LOGICAL_PLAYBACK_1; // 0x04
    pkt.destination = dest;                  // 0x00 (TV)
    pkt.opcode = 0x0D;                      // <Text View On>
    pkt.paramCount = 0;

    bool success = transmitPacket(pkt);
    if (success) {
        Serial.println(F("[CEC] <Text View On> sent and ACK received."));
    } else {
        Serial.println(F("[CEC] <Text View On> sent."));
    }
    return success;
}

bool CecEngine::sendActiveSource(uint16_t physicalAddress) {
    Serial.printf("[CEC] Sending <Active Source> (0x82) with Physical Address [0x%04X]...\n", physicalAddress);
    
    CecPacket pkt{};
    pkt.initiator = CEC_LOGICAL_PLAYBACK_1; // 0x04 (Playback 1)
    pkt.destination = CEC_LOGICAL_BROADCAST;// 0x0F (Broadcast to all)
    pkt.opcode = 0x82;                      // <Active Source>
    pkt.paramCount = 2;
    pkt.params[0] = static_cast<uint8_t>((physicalAddress >> 8) & 0xFF); // e.g. 0x10
    pkt.params[1] = static_cast<uint8_t>(physicalAddress & 0xFF);        // e.g. 0x00

    bool success = transmitPacket(pkt);
    if (success) {
        Serial.println(F("[CEC] <Active Source> broadcast completed successfully."));
    } else {
        Serial.println(F("[CEC] <Active Source> broadcast encountered an issue."));
    }
    return success;
}

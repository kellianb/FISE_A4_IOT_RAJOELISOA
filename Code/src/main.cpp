/*******************************************************************************
 * ZigBee_TX.ino - Émetteur ZigBee (XBee S2C)
 * Uses: andrewrapp/xbee-arduino library (install via Library Manager: "XBee")
 *
 * XCTU config:
 *   - This module : Router or End Device, AP=2 (API mode with escaping)
 *   - Other module: Coordinator, AP=2
 *   - Same PAN ID, same channel, baudrate 9600
 *   - Set DH/DL to the coordinator's SH/SL (or use broadcast 0x000000000000FFFF)
 *
 * Serial  = USB debug (PC)
 * Serial1 = XBee (D0/D1)
 ******************************************************************************/

#include <XBee.h>

// ---- Destination address ----
// Replace with the SH+SL of your coordinator, or use broadcast:
#define DEST_ADDR_HIGH  0x00000000
#define DEST_ADDR_LOW   0x0000FFFF   // broadcast; replace with real coord address

#define NODE_ID    1
#define PERIOD_MS  2500
#define LED_PIN    LED_BUILTIN

// ---- Packet struct ----
struct __attribute__((packed)) Packet {
  uint8_t  id;
  uint32_t seq;
  uint32_t ts;
};

// ---- XBee objects ----
XBee xbee = XBee();
XBeeAddress64 addr64 = XBeeAddress64(DEST_ADDR_HIGH, DEST_ADDR_LOW);
ZBTxStatusResponse txStatus = ZBTxStatusResponse();

uint8_t     payloadBuf[sizeof(Packet)];
ZBTxRequest zbTx = ZBTxRequest(addr64, payloadBuf, sizeof(payloadBuf));

// ---- Globals ----
uint32_t packetSeq    = 0;
uint32_t lastSendTime = 0;
uint32_t totalSent    = 0;

void blinkLED(uint8_t n, uint16_t ms) {
  for (uint8_t i = 0; i < n; i++) {
    digitalWrite(LED_PIN, HIGH); delay(ms);
    digitalWrite(LED_PIN, LOW);  delay(ms);
  }
}

void sendPacket() {
  Packet pkt;
  pkt.id  = NODE_ID;
  pkt.seq = packetSeq++;
  pkt.ts  = millis();

  // Copy struct into payload buffer
  memcpy(payloadBuf, &pkt, sizeof(Packet));

  // Send via library
  xbee.send(zbTx);

  // Wait up to 500ms for TX status response
  if (xbee.readPacket(500)) {
    if (xbee.getResponse().getApiId() == ZB_TX_STATUS_RESPONSE) {
      xbee.getResponse().getZBTxStatusResponse(txStatus);
      if (txStatus.getDeliveryStatus() == SUCCESS) {
        Serial.print(F("TX OK | id="));
      } else {
        Serial.print(F("TX FAIL | id="));
      }
    }
  } else {
    Serial.print(F("TX TIMEOUT | id="));
  }

  Serial.print(pkt.id);
  Serial.print(F(" | seq="));  Serial.print(pkt.seq);
  Serial.print(F(" | ts="));   Serial.print(pkt.ts);
  Serial.print(F(" | sent=")); Serial.println(++totalSent);

  blinkLED(1, 50);
}

void setup() {
  Serial.begin(9600);     // USB serial to PC
  Serial1.begin(9600);    // D0/D1 to XBee

  xbee.setSerial(Serial1);

  pinMode(LED_PIN, OUTPUT);
  digitalWrite(LED_PIN, LOW);

  Serial.println(F("=== ZigBee TX (xbee-arduino lib) ==="));
  Serial.println(F("XBee must be set to AP=2 in XCTU"));
  blinkLED(3, 150);
  Serial.println(F("Ready.\n"));
}

void loop() {
  // Keep base bridge: forward any XBee frames/debug back to PC
  if (Serial1.available()) {
    Serial.write(Serial1.read());
  }

  if (millis() - lastSendTime >= PERIOD_MS) {
    lastSendTime = millis();
    sendPacket();
  }
}

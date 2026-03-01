#include <main.hpp>
#include <endpoint/endpoint.hpp>

/* === XBee Configuration === */
XBee xbeeCoordinator = XBee();

// SH + SL Address of receiving XBee
XBeeAddress64 addr64 = XBeeAddress64(0, 0);
ZBTxStatusResponse txStatus = ZBTxStatusResponse();
/* ========================== */

/* === LED Pins === */
int statusLed = 13;
int errorLed = 13;
/* ================ */

/* === Ultrasonic Sensor Pins === */
#define RESET_DURATION 3000
#define DISTANCE_THRESHOLD 30
const int trigPinA = 8, echoPinA = 9;  
const int trigPinB = 6, echoPinB = 5;
#define SENSOR_A trigPinA, echoPinA
#define SENSOR_B trigPinB, echoPinB
long objectDetectedBySensorATimestamp = 0;
long objectDetectedBySensorBTimestamp = 0;
bool objectWasDetectedBySensorA = false;
bool objectWasDetectedBySensorB = false;
/* ============================== */

/* === Endpoint Information === */
#define SITE_ID 1
#define ROOM_ID 101
#define ENDPOINT_ID 1
/* ============================ */

void setupEndpoint() {
  pinMode(statusLed, OUTPUT);
  pinMode(errorLed, OUTPUT);
  pinMode(trigPinA, OUTPUT);  
	pinMode(echoPinA, INPUT);  
	pinMode(trigPinB, OUTPUT);  
	pinMode(echoPinB, INPUT);
  Serial.begin(9600);
  Serial1.begin(9600);
  xbeeCoordinator.setSerial(Serial1);
}

void loopEndpoint() {
  doDetection();

  if(objectWasDetectedBySensorA && (millis() - objectDetectedBySensorATimestamp > RESET_DURATION)) {
    objectWasDetectedBySensorA = false; // Reset if no detection for 5 seconds
  }

  if(objectWasDetectedBySensorB && (millis() - objectDetectedBySensorBTimestamp > RESET_DURATION)) {
    objectWasDetectedBySensorB = false; // Reset if no detection for 5 seconds
  }
}

void doDetection() {
  float distA = fetchDistanceFromSensor(SENSOR_A);
  float distB = fetchDistanceFromSensor(SENSOR_B);

  if(distA < DISTANCE_THRESHOLD) {
    if(objectWasDetectedBySensorB) {
      objectDetectedBySensorATimestamp = 0;
      objectDetectedBySensorBTimestamp = 0;
      objectWasDetectedBySensorB = false;
      sendPacket(-1); // Person leaving
      return;
    }
    objectDetectedBySensorATimestamp = millis();
    objectWasDetectedBySensorA = true;
  } else if (distB < DISTANCE_THRESHOLD) {
    if(objectWasDetectedBySensorA) {
      objectDetectedBySensorATimestamp = 0;
      objectDetectedBySensorBTimestamp = 0;
      objectWasDetectedBySensorA = false;
      sendPacket(1); // Person entering
      return;
    }
    objectDetectedBySensorBTimestamp = millis();
    objectWasDetectedBySensorB = true;
  }
}

float fetchDistanceFromSensor(int trigPin, int echoPin) {
  digitalWrite(trigPin, LOW);
  delayMicroseconds(2);

  digitalWrite(trigPin, HIGH);
  delayMicroseconds(10);
  digitalWrite(trigPin, LOW);

  long duration = pulseIn(echoPin, HIGH, 30000);
  float distance = duration * 0.0343 / 2.0; // Speed of sound is approximately 343 m/s, which is 0.0343 cm/µs. Divide by 2 for the round trip.

  return distance;
}

void sendPacket(int peopleCountDelta) {
  Packet packet;
  packet.siteId = SITE_ID;
  packet.roomId = ROOM_ID;
  packet.endpointId = ENDPOINT_ID;
  packet.peopleCountDelta = peopleCountDelta;

  Serial.print("Sending packet: ");
  printPacket(packet);
  Serial.println();

  ZBTxRequest zbTx = ZBTxRequest(addr64, (uint8_t*)&packet, sizeof(packet));
  xbeeCoordinator.send(zbTx);
  
  if (xbeeCoordinator.readPacket(500)) {
    if (xbeeCoordinator.getResponse().getApiId() == ZB_TX_STATUS_RESPONSE) {
      xbeeCoordinator.getResponse().getZBTxStatusResponse(txStatus);

      if (txStatus.getDeliveryStatus() == SUCCESS) {
        digitalWrite(statusLed, HIGH);
      } else {
        digitalWrite(errorLed, HIGH);
      }
    }
  }
}
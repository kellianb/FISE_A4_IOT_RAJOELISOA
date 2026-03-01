#include <main.hpp>
#include <sender.hpp>
#include <Arduino.h>
#include <XBee.h>

// create the XBee object
XBee xbeeCoordinator = XBee();

// SH + SL Address of receiving XBee
XBeeAddress64 addr64 = XBeeAddress64(0, 0);
ZBTxStatusResponse txStatus = ZBTxStatusResponse();


int statusLed = 13;
int errorLed = 13;

const int trigPinA = 8;  
const int echoPinA = 9;

const int trigPinB = 6;  
const int echoPinB = 5;

float readSensor(int trigPin, int echoPin) {
  digitalWrite(trigPin, LOW);
  delayMicroseconds(2);

  digitalWrite(trigPin, HIGH);
  delayMicroseconds(10);
  digitalWrite(trigPin, LOW);

  long duration = pulseIn(echoPin, HIGH, 30000);
  float distance = duration * 0.0343 / 2.0;     

  return distance;
}

void setupSender() {
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

void loopSender() {   

  float distA = readSensor(trigPinA, echoPinA);
  float distB = readSensor(trigPinB, echoPinB);
  
  String message = String(distA) + "," + String(distB);

  uint8_t payload[message.length()];
  message.getBytes(payload, message.length() + 1);

  ZBTxRequest zbTx = ZBTxRequest(addr64, payload, message.length());

  Serial.println(message);

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

  delay(1000);
}
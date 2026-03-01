#include <Arduino.h>
#include <XBee.h>
#include <packet/packet.hpp>

void setupEndpoint();
void loopEndpoint();

void doDetection();
float fetchDistanceFromSensor(int trigPin, int echoPin);
void sendPacket(int peopleCountDelta);
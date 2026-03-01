#pragma once
#include <Arduino.h>
#include <RTClib.h>
#include <XBee.h>
#include <WiFi.h>
#include <PubSubClient.h>
#include <packet/packet.hpp>
#include <UUID.h>

void setupCoordinator();
void loopCoordinator();

void setupNetwork();
void publishToMQTT(const Packet& packet);
void connectMQTT();
String constructMQTTPath(const Packet& packet);
void processPacket(const Packet& packet, const DateTime& now);
String formatDate(const DateTime& dt);
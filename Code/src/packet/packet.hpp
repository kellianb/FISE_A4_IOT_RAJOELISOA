#pragma once
#include <Arduino.h>

struct __attribute__((packed)) Packet {
    int16_t siteId;
    int16_t roomId;
    int16_t endpointId;
    int8_t peopleCountDelta;
};

void printPacket(const Packet& packet);
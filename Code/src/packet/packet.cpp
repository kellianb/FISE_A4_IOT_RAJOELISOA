#pragma once
#include <packet/packet.hpp>

/** Print the contents of a Packet structure to the Serial monitor */
void printPacket(const Packet& packet) {
    Serial.print("siteId=");
    Serial.print(packet.siteId);
    Serial.print(",roomId=");
    Serial.print(packet.roomId);
    Serial.print(",endpointId=");
    Serial.print(packet.endpointId);
    Serial.print(",peopleCountDelta=");
    Serial.print(packet.peopleCountDelta);
}
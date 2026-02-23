#include <main.hpp>
#include <Arduino.h>

#if IS_ENDPOINT
  #include <receiver.hpp>
#else
  #include <sender.hpp>
#endif

void setup() {

  #if IS_XCTU_PROGRAM
    Serial.begin(9600);      // USB serial to PC
    Serial1.begin(9600);     // D0/D1 to XBee
    return;
  #endif

  #if IS_ENDPOINT
    setupReceiver();
  #else
    setupSender();
  #endif
}

void loop() {

  #if IS_XCTU_PROGRAM
    if (Serial.available()) {
    Serial1.write(Serial.read());
    }
    if (Serial1.available()) {
      Serial.write(Serial1.read());
    }
    return;
  #endif

  #if IS_ENDPOINT
    loopReceiver();
  #else
    loopSender();
  #endif
}
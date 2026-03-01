#include <main.hpp>
#include <Arduino.h>

#if IS_ENDPOINT
  #include <receiver.hpp>
#else
  #include <sender.hpp>
#endif

void setup() {

  #if IS_XCTU_PROGRAM
    setupXTCU();
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
    loopXTCU();
    return;
  #endif

  #if IS_ENDPOINT
    loopReceiver();
  #else
    loopSender();
  #endif
}

void setupXTCU() {
  Serial.begin(9600);
  Serial1.begin(9600);
}

void loopXTCU() {
  if (Serial.available()) {
    Serial1.write(Serial.read());
  }
  if (Serial1.available()) {
    Serial.write(Serial1.read());
  }
}
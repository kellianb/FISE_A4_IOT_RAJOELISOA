#include <main.hpp>

#if IS_ENDPOINT
  #include <endpoint/endpoint.hpp>
#else
  #include <coordinator/coordinator.hpp>
#endif

void setup() {
  #if IS_XCTU_PROGRAM
    setupXTCU();
    return;
  #endif

  #if IS_ENDPOINT
    setupEndpoint();
  #else
    setupCoordinator();
  #endif
}

void loop() {
  #if IS_XCTU_PROGRAM
    loopXTCU();
    return;
  #endif

  #if IS_ENDPOINT
    loopEndpoint();
  #else
    loopCoordinator();
  #endif
}

/* === XCTU Methods === */
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
/* ==================== */
#include <main.hpp>

#if IS_ENDPOINT
#include <receiver.hpp>
#include <Arduino.h>
#include <XBee.h>
#include <RTClib.h>

RTC_DS3231 rtc;
XBee xbee = XBee();

void showDate(const char* txt, const DateTime& dt) {
    Serial.print(txt);
    Serial.print(' ');
    Serial.print(dt.year(), DEC);
    Serial.print('/');
    Serial.print(dt.month(), DEC);
    Serial.print('/');
    Serial.print(dt.day(), DEC);
    Serial.print(' ');
    Serial.print(dt.hour(), DEC);
    Serial.print(':');
    Serial.print(dt.minute(), DEC);
    Serial.print(':');
    Serial.print(dt.second(), DEC);

    Serial.print(" = ");
    Serial.print(dt.unixtime());
    Serial.print("s / ");
    Serial.print(dt.unixtime() / 86400L);
    Serial.print("d since 1970");

    Serial.println();
}

void setupReceiver() {
  Serial.begin(9600);
  xbee.setSerial(Serial);
  if (! rtc.begin()) {
    Serial.println("Couldn't find RTC");
    while (1);
  } 

  // sets the RTC to the date & time on PC this sketch was compiled
  rtc.adjust(DateTime(F(__DATE__), F(__TIME__)));
}

void loopReceiver() {
  DateTime now = rtc.now();
}
#endif
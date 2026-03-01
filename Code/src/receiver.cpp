#include <main.hpp>

#include <receiver.hpp>
#include <Arduino.h>
#include <XBee.h>
#include <RTClib.h>

RTC_DS3231 rtc;

XBee xbee = XBee();
XBeeResponse response = XBeeResponse();

ZBRxResponse rx = ZBRxResponse();
ModemStatusResponse msr = ModemStatusResponse();

String rawData = "";

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

  Serial.println("RTC is here baby");

  // sets the RTC to the date & time on PC this sketch was compiled
  rtc.adjust(DateTime(F(__DATE__), F(__TIME__)));
}

void loopReceiver() {
  DateTime now = rtc.now();

  xbee.readPacket();

  if (xbee.getResponse().isAvailable()) {
    if (xbee.getResponse().getApiId() == ZB_RX_RESPONSE) {
      xbee.getResponse().getZBExplicitRxResponse(rx);

      if (rx.getOption() == ZB_PACKET_ACKNOWLEDGED) {
        Serial.println("Sender got the acknowledgement");

        String payload = "";

        for (int i = 0; i < rx.getDataLength(); i++) {
          char c = rx.getData(i);

          payload += c;
        }
      } else {
        Serial.println("Sender didn't get an acknowledgement");
      }
    } else if (xbee.getResponse().getApiId() == MODEM_STATUS_RESPONSE) {
      xbee.getResponse().getModemStatusResponse(msr);

      // the local XBee sends this response on certain events, like association/dissociation
      if (msr.getStatus() == ASSOCIATED) {
        Serial.println("Associated Modem");
      } else if (msr.getStatus() == DISASSOCIATED) {
        Serial.println("Disassociated Modem");
      } else {
        Serial.println("Other status");
      }
    } else {
      Serial.println("Unexpected Error");
    }
  } else if (xbee.getResponse().isError()) {
    Serial.print("Error reading packet. Error code:");
    Serial.println(xbee.getResponse().getErrorCode());
  }
}
#include <main.hpp>
#include <coordinator/coordinator.hpp>

// RTC object
RTC_DS3231 rtc;

/* === WiFi Configuration === */
#define LOCAL_IP        192,168,1,50
#define GATEWAY         192,168,1,1
#define SUBNET          255,255,255,0
#define WIFI_SSID       "SFR_524F"
#define WIFI_PASSWORD   "qhdsqkaykwcj9422f8at"

int wifiStatus = WL_IDLE_STATUS;
/* ========================== */

/* === MQTT Configuration === */
#define MQTT_SERVER     "192.168.1.218"
#define MQTT_PORT       1883
UUID uuid;

WiFiClient espClient;
PubSubClient mqttClient(espClient);
/* ========================== */


/* === XBee Configuration === */
XBee xbeeReceiver = XBee();
XBeeResponse response = XBeeResponse();

ZBRxResponse rx = ZBRxResponse();
ModemStatusResponse msr = ModemStatusResponse();
/* ========================== */

void setupCoordinator() {
  Serial.begin(9600); // Begin serial communication for debugging
  Serial1.begin(9600); // Begin serial communication with XBee module
  xbeeReceiver.setSerial(Serial1);

  if (!rtc.begin()) {
    Serial.println("Couldn't find RTC");
    while (1);
  }

  Serial.println("RTC is ready");

  setupNetwork();

  // sets the RTC to the date & time on PC this sketch was compiled
  rtc.adjust(DateTime(F(__DATE__), F(__TIME__)));
}

void loopCoordinator() {
  DateTime now = rtc.now();

  mqttClient.loop();

  xbeeReceiver.readPacket();

  response = xbeeReceiver.getResponse();

  if (response.isError()) {
    Serial.print("Error reading packet. Error code: ");
    Serial.println(response.getErrorCode());
    return;
  }

  if (!response.isAvailable()) {
    return;
  }

  switch (response.getApiId())
  {
    case ZB_RX_RESPONSE:
      response.getZBExplicitRxResponse(rx);

      if (rx.getOption() == ZB_PACKET_ACKNOWLEDGED) {
        Serial.println("Sender got the acknowledgement");

        if (rx.getDataLength() != sizeof(Packet)) {
          Serial.println("Invalid packet size");
          break;
        }

        Packet packet;
        memcpy(&packet, rx.getData(), sizeof(Packet));

        processPacket(packet, now);
      } else {
        Serial.println("Sender didn't get an acknowledgement");
      }
      break;
    case MODEM_STATUS_RESPONSE:
      response.getModemStatusResponse(msr);

      // the local XBee sends this response on certain events, like association/dissociation
      if (msr.getStatus() == ASSOCIATED) {
        Serial.println("Associated Modem");
      } else if (msr.getStatus() == DISASSOCIATED) {
        Serial.println("Disassociated Modem");
      } else {
        Serial.println("Other status");
      }
      break;
    default:
      Serial.println("Unexpected Error");
      break;
  }
}

/**
 * Setup the WiFi connection and MQTT client
 */
void setupNetwork() {
  if (WiFi.status() == WL_NO_MODULE) {
    Serial.println("Communication with WiFi module failed!");
    wifiStatus = WL_NO_MODULE;
    while (1);
  }

  String fv = WiFi.firmwareVersion();
  if (fv < WIFI_FIRMWARE_LATEST_VERSION) {
      Serial.println("Please upgrade the firmware");
  } else {
    Serial.println("WiFi module is ready");
  }
  
  WiFi.config(IPAddress(LOCAL_IP), IPAddress(GATEWAY), IPAddress(SUBNET));

  while (wifiStatus != WL_CONNECTED) {
    Serial.print("Attempting to connect to Wifi: ");
    Serial.println(WIFI_SSID);
    // Connect to WPA/WPA2 network:
    wifiStatus = WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

    // wait 10 seconds for connection:
    delay(5000);
  }

  Serial.print("Connected to ");
  Serial.println(String(WIFI_SSID));

  mqttClient.setServer(MQTT_SERVER, MQTT_PORT);
  connectMQTT();
}

/**
 * Process the received payload and publish it to MQTT
 */
void processPacket(const Packet& packet, const DateTime& now) {
  Serial.print("Received payload: ");
  Serial.print(packet.peopleCountDelta);
  Serial.print(" people at ");
  Serial.print(formatDate(now));
  Serial.print(" from endpoint ");
  Serial.println(packet.endpointId);

  publishToMQTT(packet);
}

/**
 * Publish the sensor value to the MQTT broker
 */
void publishToMQTT(const Packet& packet) {
  if (!mqttClient.connected()) connectMQTT();

  uuid.generate(); // Generate a new UUID for this message

  // Publish sensor value
  char payload[100]; // 100 chars should be enough for our JSON payload
  snprintf(payload,
    sizeof(payload),
    "{\"delta\":%d,\"timestamp\":\"%s\",\"uuid\":\"%s\"}",
    packet.peopleCountDelta, formatDate(rtc.now()), uuid.toCharArray());
  
  // For testing, publish to a fixed topic.
  // In final deliverable, use constructMQTTPath to create dynamic topics based on packet content
  mqttClient.publish("sensors/1", payload);
  // mqttClient.publish(constructMQTTPath(packet).c_str(), payload);
}

void connectMQTT() {
  while (!mqttClient.connected()) {
    if (mqttClient.connect("ArduinoClient")) {
      Serial.println("MQTT connected");
    } else {
      delay(1000);
    }
  }
}

/**
 * Construct the MQTT topic path based on the packet content
 * Example path: "sites/1/rooms/2/endpoints/3/measures"
 */
String constructMQTTPath(const Packet& packet) {
  return "sites/" + String(packet.siteId)
                  + "/rooms/" + String(packet.roomId)
                  + "/endpoints/" + String(packet.endpointId)
                  + "/measures";
}

/**
 * Format a DateTime object using ISO 8601 format
 */
String formatDate(const DateTime& dt) {
  char buffer[20];
  snprintf(buffer,
    sizeof(buffer),
    "%04d-%02d-%02dT%02d:%02d:%02d",
    dt.year(),
    dt.month(),
    dt.day(),
    dt.hour(),
    dt.minute(),
    dt.second());
  return String(buffer);
}
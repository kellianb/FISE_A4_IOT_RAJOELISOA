#import "../style.typ" : deliverable

#show: deliverable

#title[
  IoT Project - Deliverable 3
]

#align(center)[ #box(width: 70%)[ #align(center)[
  Matteo Heidelberger, Johan Rinaldi, Enorian Rajoelisoa, Joel-Stephane Yankam Ngueguim, Kellian Bechtel
]]]

#outline(
  title: [Table of contents],
)

#outline(
  title: [Table of figures],
  target: figure
)

#pagebreak()

= Operational PoC

See attached video: #link("https://viacesifr-my.sharepoint.com/:v:/g/personal/enorian_rajoelisoa_viacesi_fr/IQCwIY69Q52eQ4gt5tha5XavARnML9Ytczz7jyC6IxhwwN0?nav=eyJyZWZlcnJhbEluZm8iOnsicmVmZXJyYWxBcHAiOiJPbmVEcml2ZUZvckJ1c2luZXNzIiwicmVmZXJyYWxBcHBQbGF0Zm9ybSI6IldlYiIsInJlZmVycmFsTW9kZSI6InZpZXciLCJyZWZlcnJhbFZpZXciOiJNeUZpbGVzTGlua0NvcHkifX0&e=NxDawd")[PoC]

= Communication architecture diagram

Before presenting the communication architecture, we remind the 2 constraints, linked to latency and energy consumption, that guided our design choices. These constraints directly influence how data is processed, where decisions are taken, and how the different layers of the system communicate.

#quote(block: true)[
- *Latency/local criticality*: The system must provide occupancy updates with a maximum delay of 2 seconds to ensure near real-time information for students outside the coworking space. It must remain operational even in case of temporary network failure; therefore, data processing and decision-making are handled locally using an edge computing approach.
- *Energy/autonomy*: Devices must operate autonomously for at least six month, with a target autonomy of a year. To reduce energy consumption, devices operate only during opening hours (8:00 AM - 6:00 PM), use low-power communication protocols, and transmit data only when occupancy status changes.
]


#figure(
  image("Images/Architecture schematic.svg"),
  caption: "Communication architecture diagram"
)

Our project uses an edge‑based architecture without cloud storage. This choice fits our needs because we do not require long‑term redundant storage or the advanced features offered by cloud or hybrid systems. Processing data locally also reduces latency, avoids dependency on external services, and removes recurring operational costs.

For communication between the sensor units and the gateway, we selected Zigbee. This protocol is well adapted to a dense deployment of low‑power devices. Zigbee offers a good balance between energy consumption, bandwidth, and range. By configuring the sensor units as Zigbee end devices, we ensure long autonomy and reliable communication. The mesh capability allows us to extend coverage by adding routers if needed. Finally, Zigbee operates on a private network, which means there are no subscription or usage fees.


= Protocol note

We decided to use MQTT because for you project, since our Arduino gateway has sufficient computational resources to handle the protocol and because we can benefit from the additional features it offers. Additionally, MQTT provides additional flexibility, and a cleaner separation between publishing and subscribing services.
This enables easier scalability and the simplifies the addition of new subscribed services as our system grows. Moreover, its message delivery guarantees ensure reliable communication, which is essential for maintaining consistency and integrity across all connected devices and subscribers.

In this section we will detail and justify the technical choices we made when implementing MQTT in our system.

== MQTT topics

Our system uses dedicated MQTT topics for each deployed sensor unit (or endpoint). Topics are structured hierarchically by site ID, room ID, endpoint ID and information type.

This structure allows subscribing services to filter the events they listen to by site, room, specific endpoints and information type.

=== Measures <sec:mqtt_topics_measures>

Measurement data reported by endpoints is published using the following topic structure:

#align(center)[
```
sites/{site_id}/rooms/{room_id}/endpoints/{endpoint_id}/measures
```
]

=== Telemetry <sec:mqtt_topics_telemetry>

If endpoints emit operational telemetry (e.g., status, diagnostics, battery level), it is published under a separate topic:

#align(center)[
```
sites/{site_id}/rooms/{room_id}/endpoints/{endpoint_id}/telemetry
```
]

== MQTT QoS levels

#figure(
  table(
    columns: 4,
    table.header(
      [*Criteria*], [*At Most Once (QoS 0)*], [*At Least Once (QoS 1)*], [*Exactly Once (QoS 2)*]
    ),
    [*Delivery Guarantee*],
    "No guarantee (message may be lost)",
    "Guaranteed delivery (messages may arrive multiple times)",
    "Guaranteed delivery (no duplication)",

    [*Acknowledgment*], "No", "Yes (PUBACK)", "Yes (4-step handshake)",

    [*Risk of Message Loss*], "High",	"None",	"None",

    [*Risk of Duplication*], "None", "Possible", "None",

    [*Network Overhead*], "Lowest",	"Moderate",	"Highest",

    [*Latency*], "Lowest", "Moderate", "Highest",

    [*Energy Consumption*],	"Lowest",	"Moderate",	"Highest",
  ),
  caption: [MQTT QoS level comparison]
)

=== Analysis for Our Project <sec:mqtt_qos_analysis>

- Our system sends messages when students enter or leave the co-working space
- Messages represent a change to the number of students in the co-working space (delta temporality #footnote[
Metrics in the *delta temporality* report changes over time by comparing two points in a dataset or system, helping to identify trends or shifts. On the other hand, cumulative metrics track the total value over a set period, adding up all values from the start of that period until now (e.g., "total sales since the beginning of the year").
])
- Lost messages will therefore affect the correctness of our count
- Duplicate messages can also affect the correctness of our count, but this can be mitigated by applying deduplication on the edge
- Devices operate under energy and budget constraints.


*QoS 0* is therefore too unreliable for our system, since a lost message would throw off our count of students in the co-working space for the rest of the day. However, it could be suitable for collecting telemetry from our system.

*QoS 1* is potentially suitable for our system. While duplicate messages could throw off our count as well, this can be mitigated by having our gateway or endpoints generate and attach a unique ID to each message. Message can then be deduplicated on the edge by looking for duplicate IDs.

*QoS 2* provides the highest level of reliability and would simplify the implementation of the backend on our edge compute, since we would not have to deal with duplicate messages. However it also introduces additional overhead and energy consumption.

=== Final decision

Our system uses *QoS 1* for measures, because this level has the smallest possible overhead while still providing sufficient delivery guarantees for our system to ensure correct tracking of occupancy.

*QoS 0* could however be suitable for our telemetry, if we deem its consistent delivery non-critical.

== MQTT sessions

#figure(
  table(
    columns: 3,
    table.header(
    [*Feature*],
    [*Clean Session*],
    [*Persistent Session*]),

    [*Session Storage*],
    [Broker does not store session state after disconnect],
    [Broker stores session state after disconnect],

    [*Subscriptions*],
    [Deleted when client disconnects],
    [Retained across reconnects],

    [*Queued Messages*],
    [Discarded if client is offline],
    [Stored and delivered when client reconnects],

    [*Client State (in-flight messages)*],
    [Cleared on disconnect],
    [Preserved across reconnect],

    [*Message Reliability*],
    [Lower (offline messages lost)],
    [Higher (offline messages delivered)],

    [*Broker Memory Usage*],
    [Lower],
    [Higher (broker stores session data)],

    [*Reconnect Behavior*],
    [Client must resubscribe every time],
    [No need to resubscribe],
  ),
  caption: [Comparison of MQTT clean session and persistent session]
)

=== Analysis for Our Project

As mentioned in @sec:mqtt_qos_analysis, messages emitted by our system represent updates to the number of students in the co-working space. Missing a message would therefore lead to an incorrect count, it is therefore vital that our occupancy tracking system receives every message emitted by our endpoints.

*Clean session* is therefore too unreliable, since a temporary disconnection of our occupancy tracking system could mean missed messages, leading to an incorrect count.

*Persistent session* is suitable for our use-case, since it guarantees that every message is relayed to our occupancy tracking system, even in case of temporary disconnections, ensuring our count remains accurate.

=== Final decision <sec:mqtt_session_final_decision>

Our system uses *persistent sessions* to ensure that services listening to occupancy updates do not miss any messages.

*Clean sessions* might, however, be appropriate for services listening to endpoint telemetry, such as reporting current battery level.

== MQTT retain

The retain flag is used to ensure that the broker keeps the last message sent on an MQTT topic, even after it has been delivered. When a message is published with the retain flag set to true, the broker stores it and automatically sends it to any new client that subscribes to that topic.

=== Analysis for Our Project

Since the metrics transmitted by our system are in the delta temporality (see @sec:mqtt_qos_analysis), individual measurements do not offer meaningful insights. Additionally, clients subscribing to metrics will use persistent sessions (@sec:mqtt_session_final_decision), which means the broker will already store any missed messages. As a result, new subscriptions are expected to be infrequent.

=== Final decision

Our system will not enable the retain flag for metrics, as it is made redundant by our usage of persistent storage.

The setting might however be useful for telemetry which is in the cumulative temporality and where only the last message is relevant (e.g. battery percentage).

= Baseline security

== Security requirements <sec:security_requirements>

As presented in the previous deliverable (Deliverable 2, Section 4 "Minimum safety trace"), ETSI EN 303 645 provides several security guidelines. Considering the limited time available to us for this project, we decided to focus on only the most relevant and important ones. This section will therefore detail 6 of the 14 guidelines.

#figure(
  table(
    columns: 3,
    table.header(
      [*Provision of ETSI EN 303 645 v3.1.3 (2024/09)*],
      [*Security baseline implemented*],
      [*Security actions*]),

    "5.1 No universal default passwords",
    "ZigBee and MQTT technologies require passwords for authentication. They will use separate passwords created by a secure password generator.",
    "SA1",

    "5.2 Implement a means to manage reports of vulnerabilities",
    "We will maintain an internal database of internal vulnerabilities, their severity and the status of their mitigation.",
    "SA2",

    "5.5 Communicate securely",
    "As defined in our minimum-security requirements, we implement TLS (Arduino) encryption and AES-128 (ZigBee).",
    "SA3",

    "5.6 Minimize exposed attack surfaces",
    "We choose ZigBee over BLE to reduce the attack surface. Separate sub-networks will be used for segmentation. Our systems don’t have any physical protection, however we can disable physical port on the Arduino's.",
    "SA4",

    "5.9 Make systems resilient to outages",
    "We will have a buffer that stores the data locally if we face network issues (as Wi-Fi not reachable).",
    "SA5",

    "5.10 Examine system telemetry data",
    "We gather additional information such as: device health data (sensor state), network data (timeouts) and security data (fail check authentication).",
    "SA6",
  ),
  caption: "Security measures implemented in compliance with ETSI EN 303 645"
)

== Attack scenario <sec:security_attack>

We now compare our selected security measures against the STRIDE threat model. The following table maps each STRIDE category to the implemented baseline security actions (SA1-SA6) and explains how they mitigate the corresponding threats.

STRIDE is a structured threat‑modelling framework originally developed by Microsoft to help identify and classify security threats in distributed systems. It decomposes potential attacks into six categories:

#quote(block: true)[
-  S (Spoofing): impersonation of identities or devices

-  T (Tampering): modification of data or messages

-  R (Repudiation): denial of actions without reliable logging

-  I (Information Disclosure): unauthorized access to confidential data

-  D (Denial of Service): disruption or exhaustion of system resources

-  E (Elevation of Privilege): gaining higher rights than intended
]

We use the STRIDE model because it is a common and well‑known method for identifying security threats in connected systems. It is also used in the recent European cybersecurity standard EN 18031, which shows that STRIDE is considered reliable and suitable for modern IoT evaluations. STRIDE helps us cover all the main types of threats in a simple and structured way, which makes it easier to check if our security measures answer each risk.

#figure(
  table(
    columns: 4,
    table.header(
      [*STRIDE Category*],
      [*Threat Description*],
      [*Security Actions (SA)*],
      [*Justification*]
    ),

    [*Spoofing (S)*],
    "An attacker impersonates a ZigBee node, a sensor, or an MQTT client.",
    "SA1, SA3",
    align(left)[
    - Unique passwords
    - TLS and AES-128 encryption
    ],

    [*Tampering (T)*],
    "Modification of data in transit or alteration of ZigBee/MQTT messages.",
    "SA3, SA4",
    align(left)[
    - Encrypted communication
    - Network segmentation
    ],

    [*Repudiation (R)*],
    "A malicious actor denies having sent a command or message.",
    "SA6, SA2",
    align(left)[
    - Telemetry/Audit logs
    - Vulnerability tracking
    ],

    [*Information Disclosure (I)*],
    "Interception of sensitive data such as sensor states or MQTT messages.",
    "SA3, SA4",
    align(left)[
    - Encrypted communication
    - Segmented network
    ],

    [*Denial of Service (D)*],
    "Network saturation or unavailability of Wi-Fi/ZigBee.",
    "SA5, SA4",
    align(left)[
    - Local buffering
    - Reduced exposed interfaces
    ],

    [*Elevation of Privilege (E)*],
    "An attacker gains higher privileges.",
    "SA1, SA4, SA2",
    align(left)[
    - Unique passwords
    - Disabled physical ports
    - Vulnerability tracking
    ],
  ),
  caption: "STRIDE analysis"
)

In conclusion, the six security measures we selected from ETSI EN 303 645 form a coherent and balanced baseline for our system. The STRIDE analysis conducted above shows that each major threat category is covered by at least one of our mitigations.

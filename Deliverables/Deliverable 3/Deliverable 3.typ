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

= Communication architecture diagram

= Protocol note

We decided to use MQTT because for you project, since our Arduino gateway has sufficient computational resources to handle the protocol and because we can benefit from the additional features it offers. Additionally, MQTT provides additional flexibility, and a cleaner separation between publishing and subscribing services.
This enables easier scalability and the simplifies the addition of new subscribed services as our system grows. Moreover, its message delivery guarantees ensure reliable communication, which is essential for maintaining consistency and integrity across all connected devices and subscribers.

In this section we will detail and justify the technical choices we made when implementing MQTT in our system.

== MQTT topics

Our system will use dedicated MQTT topics for each deployed sensor unit. Topics will be structured hierarchically by site ID, room, sensor ID and information type.

This structure will allow subscribing services to filter the events they listen to by site, room, specific sensors and information type.

=== Measures <sec:mqtt_topics_measures>

Sensor measurement data will be published using the following topic structure:

#align(center)[
```
sites/{site_id}/room/{room_id}/sensors/{sensor_id}/measures
```
]

=== Telemetry <sec:mqtt_topics_telemetry>

If sensors emit operational telemetry (e.g., status, diagnostics, battery level), it will be published under a separate topic:

#align(center)[
```
sites/{site_id}/room/{room_id}/sensors/{sensor_id}/telemetry
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

    [*Implementation Complexity*], "Simple", "Moderate", "Complex",
  ),
  caption: [MQTT QoS level comparison]
)

=== Analysis for Our Project <sec:mqtt_qos_analysis>

- Our system sends payloads when students enter or leave the co-working space
- Messages represent a change to the number of students in the co-working space
- Lost messages will therefore affect the correctness of our count
- Duplicate messages can also affect the correctnes of our count, but this can be mitigated by applying deduplication on the edge
- Devices operate under energy and budget constraints.

*QoS 0* is therefore too unreliable for our system, since a lost message would throw off our count of students in the co-working space for the rest of the day. However, it could be suitable for collecting telemetry from our system.

*QoS 1* is potentially suitable for our system. While duplicate messages could throw off our count as well, this can be mitigated by having our gateway or sensors generate and attach a unique ID to each message. Message can then be deduplicated on the edge by looking for duplicate IDs.

*QoS 2* provides the highest level of reliability and would simplify the implementation of the backend on our edge compute, since we would not have to deal with duplicate messages. However it also introduces additional overhead and energy consumption.

=== Final decision

Our system will use *QoS 1* for measures (@sec:mqtt_topics_measures), because this level has the smallest possible overhead while still providing sufficient delivery guarantees for our system to ensure correct tracking of occupancy.

*QoS 0* could however be suitable for our telemetry (@sec:mqtt_topics_telemetry), if we deem its consistent delivery non-critical.

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
  caption: [Comparaison of MQTT clean session and persistent session]
)

=== Analysis for Our Project

As mentioned in @sec:mqtt_qos_analysis, messages emitted by our system represent updates to the number of students in the co-working space. Missing a message would therefore lead to an incorrect count, it is therefore vital that our occupancy tracking system receives every message emitted by our sensors.

*Clean session* is therefore too unreliable, since a temporary disconnection of our occupancy tracking system could mean missed messages, leading to an incorrect count.

*Persistent session* is suitable for our use-case, since it guarantees that every message is relayed to our occupancy tracking system, even in case of temporary disconnections, ensuring our count remains accurate.

=== Final decision

Our system will use persistent sessions to ensure our occupancy tracking system receives every message, even if it is intermittently offline.

= Baseline security

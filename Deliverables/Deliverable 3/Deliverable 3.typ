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

#figure(
  image("Images/Architecture schematic.svg"),
  caption: "Communication architecture diagram"
)

Our project uses an edge architecture, without any cloud storage. This decision is mainly motivated by the fact that we do not require the performance or additional features a cloud or hybrid architecture would bring. Additionally, not relying on cloud services lowers the ongoing costs of our project and reduces latency.

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
- Duplicate messages can also affect the correctnes of our count, but this can be mitigated by applying deduplication on the edge
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
  caption: [Comparaison of MQTT clean session and persistent session]
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

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

We decided to use MQTT because for you project, since our Arduino gateway has sufficient computational resources to handle the protocol and because we can benefit from the additional features it offers. Additionally, MQTT provides additional flexibility, supporting scalable architectures and the easy addition of new subscribed services as our system grows. Moreover, its message delivery guarantees ensure reliable communication, which is essential for maintaining consistency and integrity across all connected devices and subscribers.

In this section we will detail and justify the technical choices we made when implementing MQTT in our system.

== MQTT QoS levels


#figure(
  table(
    columns: 4,
    inset: 10pt,
    align: horizon,
    table.header(
      [*Criteria*], [*At Most Once (QoS 0)*], [*At Least Once (QoS 1)*], [*Exactly Once (QoS 2)*]
    ),
    [*Delivery Guarantee*], "No guarantee (message may be lost)", "Guaranteed delivery (messages may arrive multiple times)", "Guaranteed delivery (no duplication)",
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
== Analysis for Our Project
- Our system sends payloads when students enter or leave the co-working space
- Messages represent a change to the number of students in the co-working space
- Lost messages will affect the correctness of our count
- Duplicate messages can also affect the correctnes of our count, but this can be mitigated by using deduplication on the edge
- Devices operate under energy and budget constraints.

*QoS 0* is therefore too unreliable for our system, since a lost message would throw off our count of students in the co-working space for the rest of the day. However, it could be suitable for collecting telemetry from our system.

*QoS 1* is potentially suitable for our system. While duplicate messages could throw off our count as well, this can be mitigated by having our gateway generate and attach a unique ID to each message. Messages can then be deduplicated on the edge by looking for duplicate IDs.

*QoS 2* provides the highest level of reliability and would simplify the implementation of the backend on our edge compute, since we would not have to deal with duplicate messages. However it also introduces additional overhead and energy consumption.

== Final decision

Our system will use *QoS 1*, because this level has the smallest possible overhead while still providing sufficient delivery guarantees for our system to work correctly.


= Baseline security

#set heading(numbering: "1.")
#set par(leading: 1.2em)

#show link: set text(fill: blue, weight: 700)
#show link: underline

#show title: set text(size: 20pt)
#show title: set align(center)

#title[
  IoT Project - Deliverable 2
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

= Operator vs Private communications

= Minimum safety trace

= Communication architecture

== MQTT vs COAP

#figure(
  table(
    columns: (auto, auto, auto),
    table.header([],
      [#align(center)[*Constrained Application Protocol (CoAP)*]],
      [#align(center)[*Message Queuing Telemetry Transport (MQTT)*]]),
    "Model", "Publish-Subscribe", "Request-Response (REST-like)",
    "Target", "API service", "MQTT broker (Mosquitto, RabbitMQ, ...)",
    "Transport", "UDP", "TCP",
    "Reliability", "Lower", "Higher",
    "Overhead", "Lower", "Higher",
  ),
  caption: "Comparaison of CoAP and MQTT"
)

*CoAP* provides a simple and lightweight REST-like communication rotocol,
similar to regular HTTP. CoAP is well suited for simple device-to-device communicationand interaction with internet-based systems. It also supports features such as multicast, allowing it to broadcast messages to multiple destinations simultaneously.

*MQTT* is a lightweight messaging protocol designed for devices with limited bandwidth, power, or processing capabilities. It operates on a publish–subscribe model, in which devices (called clients) send messages to a central broker rather than communicating directly with one another. Other devices or services (called subscribers) can subscribe to specific categories of incoming data, known as topics, and are notified whenever new messages are published.

This architecture makes MQTT especially efficient for Internet of Things (IoT) applications, as devices receive only the data that is relevant to them. In addition, devices need to send each message to only a single destination, the broker, which then handles distributing it to all subscribed parties and ensures reliable delivery.

== Communication protocol choice

We decided to use MQTT because our Arduino gateway has sufficient computational resources to handle its lightweight protocol and because we can benefit from the additional features it offers. MQTT provides additional flexibility, supporting scalable architectures and the easy addition of new services as our system grows. Moreover, its message delivery guarantees ensure reliable communication, which is essential for maintaining consistency and integrity across all connected devices and subscribers.

== Diagram

#figure(
  image("Images/Architecture schematic.drawio.svg"),
  caption: "Architecture overview"
)

= Multi-criteria matrix

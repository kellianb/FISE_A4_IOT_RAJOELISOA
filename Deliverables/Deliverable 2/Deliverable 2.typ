#import "style.typ" : deliverable

#show: deliverable

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
*Context:* Campus coworking space with 3 door motion sensors (currently using Zigbee/Arduino)

== Network comparison overview

#figure(
  table(
    columns: (auto, auto, auto),
    table.header([Aspect],
      [*Operator Networks (Sigfox/NB-IoT)*],
      [*Private Networks (LoRaWAN)*]),
    "Deployment Model", "Subscription-based, managed infrastructure", "Self-deployed gateways and network server",
    "Initial Cost", "Low (no infrastructure)", "Medium-High (gateway + server setup)",
    "Operational Cost", "€1-10/device/year subscription", "Minimal (electricity, maintenance)",
    "Coverage", "Depends on operator deployment", "Full control within campus range ",
    "Control & Flexibility", "Limited configuration options", "Complete network control",
  ),
  caption: "Comparaison of operator and private networks"
)

== Detailed Analysis for Campus Constraints

=== Operator Networks (Sigfox/NB-IoT)

==== Advantages
- Zero infrastructure investment — No gateways or servers to purchase
- Immediate deployment — Works if operator coverage exists on campus
- No maintenance burden — Operator handles network upgrades and troubleshooting
- Scalability — Easy to add devices across multiple buildings

==== Disadvantages
- Dependency risk — Coverage gaps or operator service discontinuation
- Recurring costs — Subscription fees multiply with device count (3+ doors)
- Limited data control — Data routes through operator infrastructure
- Campus firewall issues — May require special network policies for external connectivity
- Vendor lock-in — Difficult to migrate between operators
- Educational limitation — Less hands-on learning about network architecture

==== Campus-Specific Considerations

- Verify Sigfox/NB-IoT coverage actually exists on campus premises
- IT department approval needed for external data transmission
- Subscription model less suitable for academic learning environments

=== Private Networks (LoRaWAN)

==== Advantages

- Complete autonomy — No external dependencies or subscriptions
- Educational value — Hands-on experience with gateway setup, network server configuration
- Data sovereignty — All data remains on campus network
- Customization — Full control over parameters (spreading factor, bandwidth, encryption)
- One-time cost — Single gateway can cover entire campus (1-2km range)
- Integration flexibility — Direct integration with campus systems

==== Disadvantages

- Initial setup complexity — Requires gateway installation and network server configuration
- Upfront investment — Gateway (€50-300) + potential server costs
- Maintenance responsibility — Team manages troubleshooting and updates
- Technical expertise required — Steeper learning curve than plug-and-play solutions

==== Campus-Specific Considerations

- Single LoRaWAN gateway likely covers entire coworking space and surrounding buildings
- Can leverage existing campus network infrastructure for backhaul
- Aligns with educational objectives (learning network protocols)
- Easier IT approval (internal network only)

== Recommendation for your Project

=== LoRaWAN Private Deployment is more suitable because:

1. Educational Alignment — You mentioned "it is more about study than the project itself." Private LoRaWAN offers deep technical learning: RF propagation, network architecture, security. Hands-on gateway configuration and network server management.
2. Scale Appropriateness — 3-door deployment is small-scale. Operator subscriptions don't make economic sense for \<10 devices. Single gateway investment provides room for expansion.
3. Campus Environment — Controlled environment favors private deployment. Known coverage area (single building or small campus). Access to power and network infrastructure. No roaming or wide-area coverage needed.
4. Technical Control — Academic projects benefit from flexibility. Experiment with different configurations. Direct access to all network layers for debugging. No artificial restrictions from operator SLAs.

== Migration Path from Current Zigbee Setup:

Your current Arduino + Zigbee architecture could transition to LoRaWAN with:
- Replace Zigbee modules with LoRa transceivers (e.g., RFM95W, SX1276)
- Deploy LoRaWAN gateway (e.g., RAK7248, Dragino LPS8)
- Setup network server (ChirpStack open-source or The Things Network)
- Maintain Arduino sensor logic with minimal changes

== Conclusion

For a campus educational project with 3 doors, LoRaWAN private deployment offers superior learning outcomes, long-term cost efficiency, and technical flexibility. The initial setup effort becomes part of the educational value, while operator networks would abstract away the very networking concepts you're trying to study.

=== Next Steps

1. Survey campus for optimal gateway placement (roof access ideal)
2. Select gateway hardware based on budget (€100-200 recommended)
3. Choose network server platform (ChirpStack for learning, TTN for quick start)
4. Plan LoRa module integration with existing Arduino sensors

= Minimum safety trace

*ETSI 303 645 Overview*

This standard _“specifies high-level security and data protection provisions for consumer IoT devices that are connected to network infrastructure (such as the Internet or home network) and their interactions with associated services.”_

As listed in the section _“1 – Scope”_ of the ETSI 303 645, we can figure out that our system is correlated with the definition below:

#align(center)[- _“IoT gateways, base stations and hubs to which multiple devices connect;”._]

By the way, we can apply the security baseline of this standard to our IoT systems.

In the section _“5 - Cyber security provisions for consumer IoT”_, which is composed of 14 provisions, several security requirements can be found and linked to our IoT system.

So, in the table below, we identify which provision could apply to our project:

#figure(
  table(
    columns: (auto, auto),
    table.header(
      [*Provision of ETSI EN 303 645 v3.1.3 (2024/09)*],
      [*Actions implementation*]),
    "5.0 Reporting implementation", "No CVD needed, this is the responsibility of the IT infrastructure",
    "5.1 No universal default passwords", "Our systems will use password defining in our password policy. ZigBee and MQTT technologies required passwords for authentication.",
    "5.2 Implement a means to manage reports of vulnerabilities", "All events are reported through our Grafana dashboard which we can implement alert messaging.",
    "5.3 Keep software updated", "Our Arduinos won’t be updated for new features; we will upload potentially update linked to system vulnerability through a serial cable (no OTA).",
    "5.4 Securely store sensitive security parameters", "For our ZigBee and our Arduino, we don’t have any secure chip. We could add a secure element for our Arduino (the one who send MQTT messages) as the ATECC608A.",
    "5.5 Communicate securely", "As defined in our minimum-security requirements, we implement TLS (Arduino) encryption and AES-128 (ZigBee).",
    "5.6 Minimize exposed attack surfaces", "We choose ZigBee over BLE to also reduce the attack surfaces. Specific sub-networks will be used. Our systems don’t have any physical protection and we can disable physical port (Arduino).",
    "5.7 Ensure software integrity", "We don’t have any secure boot.",
    "5.8 Ensure that personal data is secure", "No personal data will be processed.",
    "5.9 Make systems resilient to outages", "We still have a buffer that stores the data locally if we face network issues (as Wi-Fi not reachable).",
    "5.10 Examine system telemetry data", "We can gather additional information as: device health data (sensor state), network data (timeouts) and security data (fail check authentication).",
    "5.11 Make it easy for users to delete user data", "We have a data retention policy of 30 days for our data stored in our database.",
    "5.12 Make installation and maintenance of devices easy", "No plan defined for deployment phase; we won’t go deeper than prototype phase.",
    "5.13 Validate input data", "Each data sent will be checked with pre-defined criterion as data rate, data value, etc.",
  ),
  caption: "ETSI Cybersecurity provision within our project"
)

The different secure technical choices that we defined are mostly related to the ETSI cybersecurity guidelines. Thanks to this standard, we can determine and design an entire IoT project with complete cyber consideration.

= Communication architecture

== MQTT vs COAP

#figure(
  table(
    columns: (auto, auto, auto),
    table.header([Aspect],
      [*Constrained Application Protocol (CoAP)*],
      [*Message Queuing Telemetry Transport (MQTT)*]),
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

We decided to use MQTT because our Arduino gateway has sufficient computational resources to handle the protocol and because we can benefit from the additional features it offers. MQTT provides additional flexibility, supporting scalable architectures and the easy addition of new services as our system grows. Moreover, its message delivery guarantees ensure reliable communication, which is essential for maintaining consistency and integrity across all connected devices and subscribers.

== Diagram

#figure(
  image("Images/Architecture schematic.drawio.svg"),
  caption: "Architecture overview"
)

= Multi-criteria matrix

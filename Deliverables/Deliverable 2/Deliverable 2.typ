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

= Multi-criteria matrix <matrix>

== Initial Scope <scope>

Our project has multiple requirements, which fall into these categories:

*Latency/local criticality*: The system must provide occupancy updates with a maximum delay of 2 seconds to ensure near real-time information for students outside the coworking space. It must remain operational even in case of temporary network failure; therefore, data processing and decision-making are handled locally using an edge computing approach.

*Energy/autonomy*: Devices must operate autonomously for at least one month, with a target autonomy of a year. To reduce energy consumption, devices operate only during opening hours (8:00 AM - 6:00 PM), use low-power communication protocols, and transmit data only when occupancy status changes.
Due to budget constraints in the initial design phase, battery-powered devices are selected to reduce installation costs and simplify deployment.

*Network/coverage*: The system must cover the entire coworking space and remain accessible.

*Criteria*: Ensure electrical and operational safety in compliance with building regulations.

*Interoperability*: The system supports open communication protocols such as MQTT or CoAP to ensure interoperability and future scalability.

*Security (baseline)*: The system follows baseline IoT security principles inspired by ETSI EN 303 645. No personal data is stored. Occupancy measurement is anonymous and processed locally to ensure privacy protection.

*Assumptions (what we assume to be true at this stage)*: At this stage, we assume that students may attempt to tamper with the system, the campus Wi-Fi is stable, devices operate on battery power due to budget constraints, the project budget is limited, and the IT department approves network integration.

== Criteria & Weight <weight>

In order to compare our long-range protocols we will use a set of criteria, chosen based on our needs and weighted according to their relevancy to our project.

Those criteria are:

#figure(
  table(
    columns: (auto, auto, auto),
    inset: 10pt,
    align: horizon,
    table.header(
      [*Criteria*], [*Description*], [*Weight*],
    ),
    [*Power Consumption*],
    [Power consumption in IoT refers to the amount of electrical energy used by Internet of Things devices during their operation.], $ 0.25 $,
    [*Cost*],
    [This one is self-explanatory. We need to amount every possible costs though such as operator prices if we need third-party provider.], $ 0.20 $,
    [*Range*],
    [Range in IoT refers to the maximum distance over which devices can communicate wirelessly.], $ 0.15 $,
    [*Operator Dependency*],
    [Self-explanatory], $ 0.15 $,
    [*Interoperability*],
    [Interoperability in IoT refers to the ability of different devices and systems to communicate and work together effectively, allowing for seamless data exchange and functionality.], $ 0.10 $,
    [*Density*],
    [IoT Device Density is a critical KPI that reflects the concentration of connected devices within a defined area, influencing operational efficiency and data-driven decision-making.], $ 0.10 $,
    [*Throughput*],
    [Throughput in IoT refers to the amount of data successfully transmitted and received by IoT devices over a network within a specific time period. It is crucial for evaluating the performance and efficiency of IoT systems, especially as the number of connected devices increases.], $ 0.05 $
  ),
  caption: [Criteria and their weights]
)

=== Justification

Throughput has a low weight because we need to:

- Send data only on status change
- Transmits small payloads
- Process data locally

Therefore, high bandwidth is unnecessary.

In the contrary, we need to have a high weight for power consumption. There are multiple reasons:

- Battery operation
- Month to a year of autonomy
- Low power transmission

If we have a low power consumption, our project is feasible.

Furthermore, we have a high cost weight because of our project and context limitations (School).

We must reliably cover the whole coworking space hence, range is pretty important.

We would prefer if we are independent, if we rely on telecom operators this increases our cost and risk.

Then for the interoperability and the density, we need to support MQTT and future scalability and we have multiple sensors in one space so the scale need to be local.

#figure(
  caption:[Criteria Tech Overview]
)[
  #{
    show table.cell: set text(size: 9pt)

    table(
      columns: (100pt, auto, auto, auto, auto, auto, auto),
      inset: 10pt,
      align: horizon,
      table.header(
        [Criteria], [*BLE*], [*ZigBee*], [*Wi-Fi*], [*LoRaWAN*], [*NB-IoT*], [*Sigfox*]
      ),
      [*Power*], [Very low], [Very low], [High], [Very low], [Low to moderate], [Very low],
      [*Cost*], [Very low], [Low], [Medium], [Low], [Medium], [Medium],
      [*Range*], $ 10"m"-50"m" $, $ 10"m"-100"m" $, $ 30"m"-50"m" $, $ 200"m"-400"m" $, $ 1"km"-10"km" $, $ 3"km"-10"km" $,
      [*Operator Dependency*], [None], [None], [None], [Low], [High], [High],
      [*Interoperability*], [High], [Medium], [Very High], [Medium], [Medium], [Low]
    )
  }
]

#figure(
  image("Images/technologiesLayer.png"),
  caption:[IoT technology layers]
)

== Multi-criteria matrix
Now, thanks to this information we can fill out the multi-criteria matrix:

#figure(
  caption:[Multi-criteria matrix],

  table(
    columns: (100pt, auto, auto, auto, auto, auto, auto),
    inset: 10pt,
    align: horizon,
    table.header(
      [Criteria], [*BLE*], [*ZigBee*], [*Wi-Fi*], [*LoRaWAN*], [*NB-IoT*], [*Sigfox*]
    ),
      [*Power*], [5], [5], [1], [5], [3], [5],
      [*Cost*], [5], [4], [5], [3], [2], [3],
      [*Range*], [2], [4], [3], [5], [5], [5],
      [*Operator Dependency*],  [5], [5], [5], [4], [1], [1],
      [*Interoperability*], [4], [4], [3], [4], [4], [2]
    )
)

And use this formula to compute a score for each technology : $ sum "value" times "weight" $

#figure(
  caption: [Final result and ranking],
  table(
    columns: 3,
    table.header(
      [Technology], [*Final Score*], [*Rank*]
    ),

    [ZigBee], [4.41], [1],
    [BLE], [4.29], [2],
    [LoRaWAN], [3.94], [3],
    [Wi-Fi], [3.41], [4],
    [Sigfox], [3.29], [5],
    [NB-IoT], [2.71], [6],
  )
)

= Communication architecture

== MQTT vs COAP

#figure(
  table(
    columns: (auto, auto, auto),
    table.header([Aspect],
      [*Constrained Application Protocol (CoAP)*],
      [*Message Queuing Telemetry Transport (MQTT)*]),
    "Model", "Request-Response (REST-like)", "Publish-Subscribe",
    "Target", "API service", "MQTT broker (Mosquitto, RabbitMQ, ...)",
    "Transport", "UDP", "TCP",
    "Reliability", "Lower", "Higher",
    "Overhead", "Lower", "Higher",
  ),
  caption: "Comparison of CoAP and MQTT"
)

*CoAP* provides a simple and lightweight REST-like communication protocol, similar to regular HTTP. CoAP is well suited for simple device-to-device communication and interaction with internet-based systems. It also supports features such as multicast, allowing it to broadcast messages to multiple destinations simultaneously.

*MQTT* is a lightweight messaging protocol designed for devices with limited bandwidth, power, or processing capabilities. It operates on a publish–subscribe model, in which devices (called clients) send messages to a central broker rather than communicating directly with one another. Other devices or services (called subscribers) can subscribe to specific categories of incoming data, known as topics, and are notified whenever new messages are published.

This architecture makes MQTT especially efficient for Internet of Things (IoT) applications, as devices receive only the data that is relevant to them. In addition, devices need to send each message to only a single destination, the broker, which then handles distributing it to all subscribed parties and ensures reliable delivery.

== Communication protocol choice

We decided to use MQTT because our Arduino gateway has sufficient computational resources to handle the protocol and because we can benefit from the additional features it offers. MQTT provides additional flexibility, supporting scalable architectures and the easy addition of new services as our system grows. Moreover, its message delivery guarantees ensure reliable communication, which is essential for maintaining consistency and integrity across all connected devices and subscribers.

== Diagram

#figure(
  image("Images/Architecture schematic.drawio.svg"),
  caption: "Architecture overview"
)

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
  caption: "Comparison of operator and private networks"
)

== Operator Networks (Sigfox/NB-IoT)

=== Advantages

- Zero infrastructure investment: No gateways or servers to purchase
- Immediate deployment: Works if operator coverage exists on campus
- No maintenance burden: Operator handles network upgrades and troubleshooting
- Scalability: Easy to add devices across multiple buildings

=== Disadvantages
- Dependency risk: Coverage gaps or operator service discontinuation (e.g. Sigfox in 2021)
- Recurring costs: Subscription fees multiply with device count (3+ doors)
- Limited data control: Data routes through operator infrastructure
- Campus firewall issues: May require special network policies for external connectivity
- Vendor lock-in: Difficult to migrate between operators

=== Campus-Specific Considerations

- Verify Sigfox/NB-IoT coverage actually exists on campus premises
- IT department approval needed for external data transmission
- Subscription models are very expensive

== Private Networks (LoRaWAN)

=== Advantages

- Complete autonomy: No external dependencies or subscriptions
- Data sovereignty: All data remains on campus network
- Customization: Full control over parameters (spreading factor, bandwidth, encryption)
- One-time cost: Single gateway can cover entire campus (1-2km range)
- Integration flexibility: Direct integration with campus systems

=== Disadvantages

- Initial setup complexity: Requires gateway installation and network server configuration
- Upfront investment: Gateway (€50-300) + potential server costs
- Maintenance responsibility: Team manages troubleshooting and updates
- Technical expertise required: Steeper learning curve than plug-and-play solutions

=== Campus-Specific Considerations

- Single LoRaWAN gateway likely covers entire coworking space and surrounding buildings
- Can leverage existing campus network infrastructure for backhaul
- Easier IT approval (internal network only)

= Minimum safety trace

*ETSI 303 645 Overview*

This standard _“specifies high-level security and data protection provisions for consumer IoT devices that are connected to network infrastructure (such as the Internet or home network) and their interactions with associated services.”_

As listed in the section _“1 – Scope”_ of the ETSI 303 645, we can figure out that our system is correlated with the definition below:

#align(center)[- _“IoT gateways, base stations and hubs to which multiple devices connect;”._]

By the way, we can apply the security baseline of this standard to our IoT systems.

In the section _“5 - Cyber security provisions for consumer IoT”_, which is composed of 14 provisions, several security requirements can be found and linked to our IoT system.

So, in the table below, we identify which provisions could apply to our project:

#figure(
  table(
    columns: (auto, auto),
    table.header(
      [*Provision of ETSI EN 303 645 v3.1.3 (2024/09)*],
      [*Implementation measures*]),
    "5.0 Reporting implementation", "We will provide an email address to send in reports and print it onto our devices.",
    "5.1 No universal default passwords", " ZigBee and MQTT technologies require passwords for authentication. They will use separate passwords created by a secure password generator.",
    "5.2 Implement a means to manage reports of vulnerabilities", "We will maintain an internal database of internal vulnerabilities, their severity and the status of their mitigation.",
    "5.3 Keep software updated", "We will install security updates within 24h using a serial cable (no OTA).",
    "5.4 Securely store sensitive security parameters", "Our Arduino's do not have any secure means of storing secrets. We could add a secure element to them, such as the ATECC608A. We will use separate credentials for each device and rotate them regularly to limit exposure.",
    "5.5 Communicate securely", "As defined in our minimum-security requirements, we implement TLS (Arduino) encryption and AES-128 (ZigBee).",
    "5.6 Minimize exposed attack surfaces", "We choose ZigBee over BLE to reduce the attack surface. Separate sub-networks will be used for segmentation. Our systems don’t have any physical protection, however we can disable physical port on the Arduino's.",
    "5.7 Ensure software integrity", "We don’t have any way to ensure software integrity with the hardware at hand, beyond placing it in a secure container.",
    "5.8 Ensure that personal data is secure", "No personal data will be gathered or processed.",
    "5.9 Make systems resilient to outages", "We will have a buffer that stores the data locally if we face network issues (as Wi-Fi not reachable).",
    "5.10 Examine system telemetry data", "We can gather additional information such as: device health data (sensor state), network data (timeouts) and security data (fail check authentication).",
    "5.11 Make it easy for users to delete user data", "We have a data retention policy of 30 days for the data stored in our database.",
    "5.12 Make installation and maintenance of devices easy", "No plan defined for deployment phase; we won’t go deeper than the prototype phase.",
    "5.13 Validate input data", "Collected data will be automatically checked for irregularities, such as unusual data rates, unusual values, etc. Parsing will be done in a memory-safe language.",
  ),
  caption: "ETSI Cybersecurity provision within our project"
)

The different technical choices around security which we made are mostly due to the ETSI cybersecurity guidelines. Using this standard, we can determine potential security risks and design our IoT project to mitigate them.

# IoT Protocols

> MQTT, CoAP, LwM2M, BLE, LoRaWAN, Zigbee, Thread — the application-layer protocols that turn an embedded device into a connected device, and the constraints that determine which one fits your problem.

## Overview

Connectivity is rarely "just add WiFi." The choice between MQTT and CoAP depends on whether you need reliable delivery or low overhead. LoRaWAN vs. cellular depends on power budget and range. BLE vs. Thread depends on whether you control both ends. Picking wrong is a multi-month project mistake. This plugin gives you the agent expertise to choose well, design the protocol layer correctly, and ship a connected device that actually stays connected.

## Contents

### Agents

- **iot-protocol-engineer** -- IoT protocol specialist who matches problem characteristics (power budget, data rate, latency, range, reliability) to protocol choice, then designs the protocol layer correctly. Knows MQTT QoS levels deeply, CoAP semantics, LwM2M device management, BLE GATT design, LoRaWAN class A/B/C trade-offs.

### Commands

- **/iot** -- Protocol selection + protocol layer design. Hand it the problem (power budget, data rate, range, reliability) and it returns a protocol recommendation with the reasoning, plus a draft of the protocol-layer code.

### Skills

- **iot-protocols** -- Reference library: protocol comparison matrix, MQTT QoS state machines, CoAP observe pattern, BLE GATT characteristic design, LoRaWAN bandwidth planning, common-mistakes catalog.

## Key Capabilities

- **Protocol selection** based on power, data rate, latency, range, reliability, and ecosystem constraints
- **MQTT design** — QoS levels with state machines, retained messages, Last Will and Testament, topic hierarchy design, broker scaling
- **CoAP design** — RESTful semantics, observe pattern, block-wise transfer, DTLS for security
- **LwM2M device management** — registration, object model, firmware over-the-air via LwM2M
- **BLE GATT** — service + characteristic design, MTU negotiation, notification vs. indication, connection parameters tuning for power
- **LoRaWAN** — class A/B/C trade-offs, ADR (adaptive data rate), duty cycle compliance, gateway considerations, regional band selection
- **Thread + Zigbee** — when the IoT device is part of a mesh; comparison vs. point-to-point

## When to use this plugin

- Choosing a connectivity stack for a new IoT product
- Designing the application protocol layer (which topics? what QoS? what payload format?)
- Debugging "device keeps disconnecting" or "messages take too long to arrive"
- Adding security (TLS / DTLS) to an existing IoT stack
- Power-optimizing an existing connected device
- Adding firmware over-the-air (FOTA) capability

## Compatibility

- **Stacks**: lwIP + mbedTLS (Cortex-M), ESP-IDF networking, Nordic Connect SDK + nRF Connect (BLE + Thread + LoRaWAN), Zephyr networking, Mongoose Library, Paho MQTT, libcoap, LwM2M wakaama
- **Brokers / cloud**: AWS IoT Core, Azure IoT Hub, Google Cloud IoT (sunset), Mosquitto, HiveMQ, ThingsBoard, generic LwM2M servers
- **LoRaWAN**: TTN, ChirpStack, Senet, KPN LoRa
- **BLE central**: iOS + Android (CoreBluetooth + Android BLE API); supported and discussed
- **OS scope**: bare-metal, FreeRTOS, Zephyr, Linux (less depth)

## Limitations the agent will tell you about

- Cellular protocol detail (NB-IoT, LTE-M) is supported at the application layer but the modem AT command interfaces are not deeply covered
- 5G + IoT is too early to have settled patterns; the agent will tell you that
- Custom application protocols over BLE GATT vs. standardized (HID, Battery, etc.) — the agent helps you decide which to use

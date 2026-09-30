# IoT protocols pattern library

Reference patterns for MQTT, CoAP, LwM2M, BLE GATT, LoRaWAN, Thread, and Zigbee.

## Protocol selection matrix

| Constraint | MQTT (TCP) | CoAP (UDP) | LoRaWAN | BLE GATT | NB-IoT / LTE-M | Thread |
|---|---|---|---|---|---|---|
| 10-year battery target | No | Maybe | Yes | Yes (peripheral) | Maybe | Maybe |
| Internet reach | Yes | Yes | Yes (via gateway) | No | Yes | Maybe (via border router) |
| > 100 m range | Yes (via WiFi) | Yes (via WiFi) | Yes (up to 10 km) | No | Yes | Yes (mesh) |
| > 1 kbps throughput | Yes | Yes | No | Yes | Yes | Yes |
| At-least-once delivery | Yes (QoS ≥ 1) | Yes (CON) | Yes (confirmed) | Yes (indications) | Yes | Yes |
| Standard cloud ecosystem | Yes | Yes (less mature) | Yes (TTN, etc.) | No | Yes | Maybe |

## MQTT state machines

### QoS 1 publish flow

```
PUBLISHER                   BROKER                    SUBSCRIBER
    |                          |                          |
    |─ PUBLISH (msg_id=N) ────→|                          |
    |                          |─ PUBLISH (msg_id=M) ───→|
    |                          |←── PUBACK (M) ──────────|
    |←─ PUBACK (N) ────────────|                          |
```

Retransmit logic:
- If PUBACK not received within timeout (default 5-30s), publisher retransmits with DUP=1.
- Subscriber may receive duplicate; deduplicate on app-side via msg_id.

### QoS 2 publish flow

```
PUBLISHER                   BROKER
    |                          |
    |─ PUBLISH (id=N) ────────→|
    |←─ PUBREC (N) ────────────|
    |─ PUBREL (N) ────────────→|
    |←─ PUBCOMP (N) ───────────|
```

State persisted at publisher between PUBLISH and PUBCOMP. Retransmit PUBLISH if PUBREC times out; retransmit PUBREL if PUBCOMP times out.

### LWT setup

In the CONNECT packet:
```
will_topic: /devices/${id}/status
will_payload: {"online": false}
will_qos: 1
will_retain: true
```

When broker detects ungraceful disconnect (TCP RST, keep-alive timeout), it publishes the will message. Subscribers see "device offline" without explicit signaling.

### Topic design

Hierarchical with predictable structure:

```
/{tenant}/{device_class}/{device_id}/{stream}
```

Examples:
- `/acme/sensor/dev-abc-123/temperature`
- `/acme/sensor/dev-abc-123/cmd/+` (subscribe with wildcard)
- `/acme/+/+/alerts` (subscribe to all alerts across all device types)

Wildcards:
- `+`: matches exactly one level
- `#`: matches all remaining levels (must be last)

## CoAP semantics

### Observe pattern

```
Client                              Server
   |                                   |
   |─ GET /sensor Observe: 0 ─────────→|
   |←─ 2.05 Content (value=23) ────────|  (current value, Observe: N)
   |                                   |
   |   ... time passes, value changes ...
   |                                   |
   |←─ 2.05 Content (value=25) ────────|  (notification, Observe: N+1)
   |                                   |
   |─ GET /sensor Observe: 1 ─────────→|  (deregister)
   |←─ 2.05 Content (last value) ──────|
```

Server-side state: list of observers per resource. Each notification increments the Observe number.

### Block-wise transfer

For payloads > MTU (~ 1100 bytes over Ethernet, less over LoRaWAN):

Request blocks 0, 1, 2, ... until M (more-blocks) flag is 0.

```
GET /firmware Block2: 0/0/512    ─→  request first 512-byte block
2.05 Content Block2: 0/1/512     ←─  block 0, more=1, size=512

GET /firmware Block2: 1/0/512    ─→  next
2.05 Content Block2: 1/1/512     ←─  block 1, more=1

...

GET /firmware Block2: N/0/512    ─→  last
2.05 Content Block2: N/0/512     ←─  block N, more=0 (done)
```

## LwM2M object model

Standard objects (URN style: `/object_id/instance_id/resource_id`):

```
/3                Device
  /3/0/0          Manufacturer
  /3/0/1          Model number
  /3/0/2          Serial number
  /3/0/3          Firmware version
  /3/0/9          Battery level

/5                Firmware Update
  /5/0/0          Package (or)
  /5/0/1          Package URI
  /5/0/2          Update (execute)
  /5/0/3          State (idle/downloading/downloaded/updating)
  /5/0/5          Update Result

/3303             Temperature
  /3303/0/5700    Sensor Value
  /3303/0/5601    Min Measured
  /3303/0/5602    Max Measured
  /3303/0/5603    Min Range
  /3303/0/5604    Max Range
  /3303/0/5701    Sensor Units
```

OMA LwM2M standardizes the IDs. Custom objects use object IDs ≥ 26241 (vendor range).

### Firmware update flow

```
1. Server: PUT /5/0/1 with firmware URL
2. Device: state /5/0/3 transitions Idle → Downloading
3. Device: HTTP/CoAP/MQTT download of firmware
4. Device: state /5/0/3 transitions Downloading → Downloaded
5. Server: POST /5/0/2 (execute Update)
6. Device: state /5/0/3 transitions Downloaded → Updating
7. Device: applies update, reboots
8. Device: re-registers, /5/0/3 = Idle, /5/0/5 = Success
9. Device: /3/0/3 (firmware version) now reflects new version
```

If anything fails, /5/0/5 (Update Result) is set to the appropriate code (1=success, 2=insufficient storage, 3=insufficient memory, 4=connection lost, 5=integrity check failure, 6=unsupported package type, 7=invalid URI, 8=firmware update failed, 9=unsupported protocol).

## BLE GATT design

### Service + characteristic tree

```
Service (UUID: 0xFEED, vendor-defined)
├─ Characteristic A (UUID: 0xFEE1, read/notify)
│  └─ CCCD descriptor (0x2902) — enables notifications
├─ Characteristic B (UUID: 0xFEE2, write)
└─ Characteristic C (UUID: 0xFEE3, read)
```

Standard services (use when possible — phones auto-recognize):

| UUID | Service |
|---|---|
| 0x180A | Device Information |
| 0x180F | Battery |
| 0x180D | Heart Rate |
| 0x1812 | HID |
| 0x181C | User Data |
| 0x181D | Weight Scale |

### Connection parameter tuning

For power on the peripheral:

| Param | Low power | Low latency |
|---|---|---|
| Min connection interval | 1000 ms | 7.5 ms |
| Max connection interval | 2000 ms | 15 ms |
| Slave latency | 4 | 0 |
| Supervision timeout | 6000 ms | 1000 ms |

iOS overrides these. Aim for 30-50 ms connection interval if iOS support matters.

### MTU negotiation

Default MTU: 23 bytes (20 bytes payload after ATT overhead).

Negotiated MTU: up to 247 (most stacks) or 517 (BLE 5.x).

Larger MTU = fewer fragments = lower latency for large transfers. Request MTU during connection setup.

## LoRaWAN bandwidth planning

### Air time table (EU 868 MHz, SF7-SF12)

For a 13-byte payload:

| SF | Time on air | Sensitivity | Range |
|---|---|---|---|
| 7 | 56 ms | -123 dBm | ~2 km open field |
| 8 | 103 ms | -126 dBm | ~3 km |
| 9 | 185 ms | -129 dBm | ~5 km |
| 10 | 329 ms | -132 dBm | ~7 km |
| 11 | 660 ms | -134.5 dBm | ~10 km |
| 12 | 1318 ms | -137 dBm | ~15 km |

EU 868 1% duty cycle means at SF12 a device can send 36 × 1318 ms = 47 seconds per hour = once every ~100 seconds at the lowest data rate. ADR is essential.

### Class trade-offs

| Class | Downlink latency | Power | Use case |
|---|---|---|---|
| A | Up to next uplink | Lowest | Sensors, infrequent transmitters |
| B | Up to beacon period (e.g., 128 s) | Medium | Scheduled control |
| C | < 1 second | Highest | Actuators, always-on receive |

## Common mistakes catalog

### "MQTT client reconnects every few minutes"

NAT timeout. The router between the device and broker closes the TCP connection after idle period. Solutions:
- Reduce MQTT keep-alive below the NAT timeout (often 60s is safe)
- Use TCP keep-alive at OS level

### "BLE device disconnects randomly"

Supervision timeout too short, or peer requesting incompatible connection params. Check:
- Supervision timeout ≥ (1 + slave_latency) × max_conn_interval × 4
- Peer (e.g., iOS) accepts your requested intervals

### "LoRaWAN device works in lab, fails in field"

Lab probably had clear line of sight to gateway. Field has obstacles. ADR will adapt SF up but may not be enough; check signal margin and consider repositioning gateway.

### "Device occasionally sends garbled payloads"

CRC isn't catching corruption. Check:
- Stack handles all framing errors (UART parity / CAN CRC / radio CRC)
- Payload is properly framed at application layer
- Endianness is consistent across MCU + cloud

### "Cloud sees device as offline immediately after deploy"

LWT was published because graceful disconnect didn't happen. Common causes:
- Power glitch during firmware boot
- Bug in disconnect sequence
- Reset before MQTT graceful disconnect

### "Battery drops to 80% on Day 1 then stable"

Lithium battery passivation layer. Not a real drain — the chemistry recovers. Expect this.

## Code patterns

IoT protocol patterns for constrained MCUs and embedded Linux.

### MQTT Topic Structure

Well-structured topic hierarchy enables flexible filtering and routing:

```
device/{device_id}/telemetry     ← sensor data (QoS 0, no retain)
device/{device_id}/status        ← online/offline (QoS 1, retained)
device/{device_id}/cmd           ← commands to device (QoS 1)
device/{device_id}/cmd/ack       ← command acknowledgment
device/{device_id}/ota/cmd       ← OTA start/control
device/{device_id}/ota/data      ← firmware chunks
fleet/+/telemetry                ← subscribe to all device telemetry
```

LWT (Last Will and Testament) configuration:
```c
esp_mqtt_client_config_t cfg = {
    .session.last_will = {
        .topic  = "device/" DEVICE_ID "/status",
        .msg    = "{\"online\":false}",
        .qos    = 1,
        .retain = true,   /* Retained: new subscribers see last status immediately */
    },
};
```

On connect, publish: `device/{id}/status` = `{"online":true}` retained.

### Paho MQTT C Client (Linux/RTOS)

```c
#include "MQTTClient.h"

#define BROKER_URI    "ssl://broker.example.com:8883"
#define DEVICE_ID     "device-001"
#define KEEPALIVE_SEC 60

static MQTTClient     s_client;
static MQTTClient_connectOptions s_conn_opts = MQTTClient_connectOptions_initializer;

void mqtt_message_arrived(void *ctx, char *topic, int topic_len,
                           MQTTClient_message *msg)
{
    /* Process command from broker */
    handle_command(topic, msg->payload, msg->payloadlen);
    MQTTClient_freeMessage(&msg);
    MQTTClient_free(topic);
}

int mqtt_init(void)
{
    MQTTClient_create(&s_client, BROKER_URI, DEVICE_ID,
                      MQTTCLIENT_PERSISTENCE_NONE, NULL);

    s_conn_opts.keepAliveInterval = KEEPALIVE_SEC;
    s_conn_opts.cleansession      = 1;
    s_conn_opts.username          = "devices";
    s_conn_opts.password          = "secret";

    MQTTClient_SSLOptions ssl = MQTTClient_SSLOptions_initializer;
    ssl.trustStore = "/etc/ssl/mqtt-ca.pem";
    s_conn_opts.ssl = &ssl;

    MQTTClient_setCallbacks(s_client, NULL, NULL, mqtt_message_arrived, NULL);

    int rc = MQTTClient_connect(s_client, &s_conn_opts);
    if (rc != MQTTCLIENT_SUCCESS) { return rc; }

    MQTTClient_subscribe(s_client, "device/" DEVICE_ID "/cmd", 1);
    return 0;
}
```

### BLE Advertising (nRF52840, nRF Connect SDK)

```c
#include <bluetooth/bluetooth.h>

/* Connectable advertising with device name + service UUID in AD */
static const struct bt_data ad[] = {
    BT_DATA_BYTES(BT_DATA_FLAGS, (BT_LE_AD_GENERAL | BT_LE_AD_NO_BREDR)),
    BT_DATA_BYTES(BT_DATA_UUID16_ALL,
                  BT_UUID_16_ENCODE(0x181A)),   /* Environmental Sensing */
};

static const struct bt_data sd[] = {
    BT_DATA(BT_DATA_NAME_COMPLETE, CONFIG_BT_DEVICE_NAME,
            sizeof(CONFIG_BT_DEVICE_NAME) - 1),
};

void ble_start_advertising(void)
{
    bt_enable(NULL);
    bt_le_adv_start(BT_LE_ADV_CONN, ad, ARRAY_SIZE(ad), sd, ARRAY_SIZE(sd));
}

/* Notify connected client on temperature change */
void ble_notify_temperature(int16_t temp_centidegrees)
{
    bt_gatt_notify(NULL, &my_service.attrs[2], /* Characteristic value attr */
                   &temp_centidegrees, sizeof(temp_centidegrees));
}
```

### LoRaWAN Duty Cycle Calculator

EU868 regulations: 1% duty cycle on most sub-bands.

```python
# Calculate LoRaWAN airtime and maximum transmission rate

import math

def lorawan_airtime_ms(payload_bytes, sf, bw_khz=125, cr=1, explicit_header=True):
    """Semtech SX1276 airtime formula"""
    t_sym = (2**sf) / (bw_khz * 1000) * 1000  # ms per symbol
    n_preamble = 8 + 4.25  # preamble symbols
    t_preamble = n_preamble * t_sym

    header = 0 if not explicit_header else 1
    payload_symb = 8 + max(
        math.ceil((8 * payload_bytes - 4*sf + 28 + 16 - 20*header) / (4*(sf-2))) * (cr+4),
        0
    )
    t_payload = payload_symb * t_sym
    return t_preamble + t_payload

# SF7, 125kHz, 10 bytes payload
at_ms = lorawan_airtime_ms(10, 7)
print(f"SF7: {at_ms:.0f}ms airtime")                    # ~46ms
print(f"Max rate (1% duty): {1000/at_ms:.1f} msg/min") # ~1300/hr

# SF12, 125kHz, 10 bytes
at_ms = lorawan_airtime_ms(10, 12)
print(f"SF12: {at_ms:.0f}ms airtime")                   # ~1810ms
print(f"Max rate (1% duty): {60/at_ms*1000:.1f} msg/hr") # ~33/hr
```

### MQTT Over TLS with Client Certificate

```c
/* Embed server CA, device certificate and private key as C arrays */
/* Generated with: xxd -i ca.pem > ca_pem.h */

extern const uint8_t mqtt_ca_pem[]     asm("_binary_ca_pem_start");
extern const uint8_t mqtt_cert_pem[]   asm("_binary_cert_pem_start");
extern const uint8_t mqtt_key_pem[]    asm("_binary_privkey_pem_start");

/* ESP-IDF client cert auth */
esp_mqtt_client_config_t cfg = {
    .broker.address.uri = "mqtts://broker.example.com:8883",
    .broker.verification = {
        .certificate = (const char *)mqtt_ca_pem,
    },
    .credentials = {
        .authentication = {
            .certificate = (const char *)mqtt_cert_pem,
            .key         = (const char *)mqtt_key_pem,
        },
    },
};
```

## Anti-patterns

- **QoS 2 for sensor telemetry**: the 4-way handshake costs ~100ms and battery. Use QoS 0 or 1.
- **Publishing without QoS 1 for commands**: commands must not be lost. Use QoS 1 + retained for the latest state.
- **LoRaWAN without ADR**: fixed SF12 when SF7 would work wastes battery and airtime.
- **BLE advertising at 20ms**: burns ~5mA continuously. Use 1000ms for background beacon, switch to 100ms on button press.

## References

- MQTT 5.0 specification: OASIS
- BLE GATT specification: Bluetooth SIG Core 5.3
- LoRaWAN 1.0.3 specification: lora-alliance.org
- Semtech SX1276 datasheet: airtime formula in section 4.1.1.7

## Cross-references

- **bootloader-design** plugin: secure boot + firmware update integration with LwM2M Object 5
- **rtos-patterns** plugin: protocol stack typically runs as one or more RTOS tasks
- **power-management** plugin: deep sleep + protocol wake patterns
- **debug-trace** plugin: when you need to capture the actual radio traffic (logic analyzer + radio sniffer)

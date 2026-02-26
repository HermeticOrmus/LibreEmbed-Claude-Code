# iot-protocol-patterns

## Knowledge Base

IoT protocol patterns for constrained MCUs and embedded Linux.

---

## Pattern 1: MQTT Topic Structure

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

---

## Pattern 2: Paho MQTT C Client (Linux/RTOS)

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

---

## Pattern 3: BLE Advertising (nRF52840, nRF Connect SDK)

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

---

## Pattern 4: LoRaWAN Duty Cycle Calculator

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

---

## Pattern 5: MQTT Over TLS with Client Certificate

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

---

## Anti-Patterns

- **QoS 2 for sensor telemetry**: the 4-way handshake costs ~100ms and battery. Use QoS 0 or 1.
- **Publishing without QoS 1 for commands**: commands must not be lost. Use QoS 1 + retained for the latest state.
- **LoRaWAN without ADR**: fixed SF12 when SF7 would work wastes battery and airtime.
- **BLE advertising at 20ms**: burns ~5mA continuously. Use 1000ms for background beacon, switch to 100ms on button press.

## References

- MQTT 5.0 specification: OASIS
- BLE GATT specification: Bluetooth SIG Core 5.3
- LoRaWAN 1.0.3 specification: lora-alliance.org
- Semtech SX1276 datasheet: airtime formula in section 4.1.1.7

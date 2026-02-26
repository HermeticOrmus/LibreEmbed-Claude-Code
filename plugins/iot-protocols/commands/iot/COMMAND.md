# /iot

IoT protocol configuration command: MQTT, BLE GATT, LoRaWAN, CoAP setup and testing.

## Trigger

`/iot <action> [options]`

## Actions

### `configure`
Generate IoT protocol configuration for a target platform.

```
/iot configure --protocol mqtt --platform esp32 --broker hivemq --tls
/iot configure --protocol ble-gatt --platform nrf52840 --service environment
/iot configure --protocol lorawan --platform stm32 --modem sx1276 --region eu868
/iot configure --protocol coap --platform linux --server coap.example.com
```

### `connect`
Generate connection test code.

```
/iot connect --protocol mqtt --test-publish --test-subscribe
/iot connect --protocol ble --scan --connect-device "MySensor"
```

### `test`
Generate protocol test scripts (host side).

```
/iot test --protocol mqtt --python --broker localhost --topic test/#
/iot test --protocol coap --get coap://coap.me/test
```

### `monitor`
Generate monitoring/debug commands.

```
/iot monitor --protocol mqtt --broker localhost --all-topics
/iot monitor --protocol ble --sniff --channel 37
```

## Process

1. Select protocol based on range, power, bandwidth, and connectivity requirements.
2. Configure security: TLS certificates for MQTT, pairing for BLE, EUI/keys for LoRaWAN.
3. Define topic/characteristic structure before writing code.
4. Test connectivity with a simple publish/subscribe before adding application logic.

## Output Examples

### Mosquitto test (Linux)
```bash
# Broker on localhost:
mosquitto -c /etc/mosquitto/mosquitto.conf -v

# Subscribe (terminal 1):
mosquitto_sub -h localhost -t "device/#" -v

# Publish (terminal 2):
mosquitto_pub -h localhost -t "device/001/telemetry" \
  -m '{"temp":23.5,"hum":65.2}' -q 1

# TLS test:
mosquitto_pub -h broker.example.com -p 8883 \
  --cafile ca.pem --cert device.pem --key device.key \
  -t "device/001/status" -m '{"online":true}' --retain
```

### Python paho subscriber
```python
import paho.mqtt.client as mqtt

def on_message(client, userdata, msg):
    print(f"{msg.topic}: {msg.payload.decode()}")

client = mqtt.Client()
client.tls_set(ca_certs="ca.pem")
client.username_pw_set("user", "pass")
client.on_message = on_message
client.connect("broker.example.com", 8883, 60)
client.subscribe("device/#", qos=1)
client.loop_forever()
```

### LoRaWAN airtime check
```python
# Before deployment: verify duty cycle compliance
# 10-byte payload, SF9, EU868
airtime_ms = lorawan_airtime_ms(10, sf=9)
# SF9: ~329ms → max ~110 uplinks/hour at 1% duty cycle
```

## Error Handling

- "MQTT CONNACK refused" — check credentials; broker logs show exact rejection reason
- "TLS handshake failed" — certificate CN mismatch, expired cert, or wrong CA bundle
- "BLE: no device found" — check advertising is running; verify UUID in scan filter matches
- "LoRaWAN join failed" — verify DEVEUI/APPEUI/APPKEY match network server registration (LSB/MSB byte order)

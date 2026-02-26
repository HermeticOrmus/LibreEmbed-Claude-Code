# /firmware-update

Firmware OTA command: image packaging, distribution, flash write, verification, rollback.

## Trigger

`/firmware-update <action> [options]`

## Actions

### `package`
Package a raw firmware binary with header and signature.

```
/firmware-update package --tool imgtool --key ecdsa-p256.pem --version 2.1.0 --slot-size 0x70000
/firmware-update package --custom-header --magic 0xDEADBEEF --crc32
```

### `distribute`
Generate OTA distribution scripts or server configurations.

```
/firmware-update distribute --transport mqtt --broker mosquitto --topic-prefix device/fw
/firmware-update distribute --transport aws-iot-jobs --thing-group my-devices
/firmware-update distribute --transport http --server nginx --tls
```

### `apply`
Generate MCU-side OTA write and verify code.

```
/firmware-update apply --mcu stm32f407 --banks dual --transport uart-ymodem
/firmware-update apply --mcu esp32 --sdk esp-idf --transport https
/firmware-update apply --mcu nrf52840 --bootloader mcuboot --transport ble-smp
```

### `verify`
Generate post-write verification code.

```
/firmware-update verify --method crc32
/firmware-update verify --method sha256+ecdsa --curve p256
```

## Process

1. Define flash layout: bootloader size, bank A/B addresses, NVM region.
2. Choose transport: MQTT for IoT, HTTPS for large payloads, BLE SMP for local.
3. Implement write → verify → set-boot-flag → reset sequence.
4. Implement confirm sequence with application-level self-test.
5. Test power-loss simulation at each step.

## Output Examples

### imgtool sign and flash
```bash
# Package
imgtool sign \
  --key signing-key.pem --header-size 0x20 --align 4 \
  --version 2.1.0+0 --slot-size 0x70000 \
  build/firmware.bin build/firmware_signed.bin

# Verify signed image
imgtool verify --key signing-key.pem build/firmware_signed.bin

# Flash bootloader + signed app
openocd -f interface/stlink.cfg -f target/stm32f4x.cfg \
  -c "program mcuboot.bin 0x08000000 verify" \
  -c "program firmware_signed.bin 0x08010000 verify reset exit"
```

### MQTT OTA state machine (pseudocode)
```
IDLE:
  on(topic "ota/start", {size, sha256}):
    erase_bank_b()
    start_sha256_context()
    state = DOWNLOADING
    offset = 0

DOWNLOADING:
  on(topic "ota/chunk", {offset, data}):
    if offset != expected: send NAK, return
    write_to_bank_b(offset, data)
    sha256_update(data)
    expected += len(data)
    if expected == size: state = VERIFYING

VERIFYING:
  sha256_final() == sha256 ? state = REBOOTING : state = ERROR

REBOOTING:
  set_boot_flag(BANK_B)
  reset()
```

## Error Handling

- "Image too large for slot" — check `--slot-size` matches your flash layout
- "Signature verification failed" — key mismatch between signing tool and bootloader public key
- "OTA abort: CRC mismatch" — corruption during transfer; request retransmit from offset
- "Stuck in rollback loop" — self-test always fails; check peripheral init before calling confirm

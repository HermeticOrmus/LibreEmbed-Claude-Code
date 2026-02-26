# /bootloader

Bootloader design and firmware update command: flash layout, image packaging, CRC/signature, YMODEM.

## Trigger

`/bootloader <action> [options]`

## Actions

### `design`
Generate a complete bootloader architecture for a target MCU.

```
/bootloader design --mcu stm32f407 --banks dual --transport uart
/bootloader design --mcu nrf52840 --banks dual --transport ble
/bootloader design --security ecdsa-p256 --rollback otp
```

Generates:
- Flash layout diagram with sector addresses
- Boot decision state machine pseudocode
- Image header C struct definition
- Jump-to-application function

### `flash`
Implement the flash programming driver.

```
/bootloader flash --mcu stm32f407 --sector-erase --page-write --verify
/bootloader flash --mcu samd21 --nvmctrl-page-write
```

Output: erase, write, verify C functions using direct register access.

### `verify`
Generate image verification code.

```
/bootloader verify --method crc32
/bootloader verify --method crc32+ecdsa --curve p256
/bootloader verify --method crc32+rsa --bits 2048
```

### `sign`
Generate image packaging and signing pipeline.

```
/bootloader sign --tool imgtool --key ecdsa-p256.pem --version 1.2.0
/bootloader sign --custom-header --magic 0xDEADBEEF
```

Output: imgtool or custom Python script to package and sign firmware binary.

## Process

1. Confirm flash layout: total flash size, sector sizes, bootloader size constraint (<32KB typical).
2. Verify transport: UART YMODEM, USB DFU, CAN, or OTA (BLE/WiFi).
3. Define image header format and magic number.
4. Implement CRC first, add signature verification as second layer.
5. Implement and test the rollback/recovery path before the happy path.
6. Write-protect bootloader sectors using FLASH_OPTCR or equivalent.

## Output Examples

### imgtool sign command (mcuboot compatible)
```bash
# Install: pip install imgtool
imgtool sign \
  --key ecdsa-p256-signing-key.pem \
  --header-size 0x80 \
  --align 4 \
  --version 1.2.0+0 \
  --slot-size 0x38000 \
  firmware_unsigned.bin \
  firmware_signed.bin
```

### Flash write-protect (STM32F4 option bytes)
```c
/* Protect Sector 0 (bootloader) from write/erase */
void flash_protect_bootloader(void)
{
    FLASH->OPTKEYR = 0x08192A3BUL;
    FLASH->OPTKEYR = 0x4C5D6E7FUL;
    while (FLASH->SR & FLASH_SR_BSY) {}

    /* WRP bits: 0 = protected, 1 = unprotected */
    /* Clear bit 0 to protect sector 0 */
    FLASH->OPTCR &= ~(1U << 16);   /* nWRP[0] = 0: protect sector 0 */
    FLASH->OPTCR |= FLASH_OPTCR_OPTSTRT;
    while (FLASH->SR & FLASH_SR_BSY) {}
}
```

## Error Handling

- "Image magic mismatch" — wrong flash base address in linker script or header not aligned
- "CRC32 mismatch after write" — verify `crc32_compute` polynomial matches packaging tool (0xEDB88320 vs 0x04C11DB7)
- "Jump crashes immediately" — VTOR not updated, or IRQs from bootloader still pending at jump
- "Flash erase hangs" — sector not unlocked; check FLASH->CR LOCK bit and key sequence

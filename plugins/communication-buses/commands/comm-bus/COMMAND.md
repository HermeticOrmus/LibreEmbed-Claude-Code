# /comm-bus

Communication bus configuration and driver command for I2C, SPI, UART, CAN, USB.

## Trigger

`/comm-bus <action> [options]`

## Actions

### `configure`
Generate peripheral init code for a specific bus and MCU.

```
/comm-bus configure --bus i2c --mcu stm32f407 --speed 400kHz --dma
/comm-bus configure --bus spi --mcu stm32f4 --mode 0 --speed 10MHz --dma
/comm-bus configure --bus uart --mcu stm32f4 --baud 115200 --flow rts-cts
/comm-bus configure --bus can --mcu stm32f4 --bitrate 500kbit
```

### `test`
Generate a loopback or scan test for a bus.

```
/comm-bus test --bus i2c --scan-range 0x08-0x77
/comm-bus test --bus spi --loopback --pattern 0xAA55
/comm-bus test --bus uart --echo --baud 115200
```

### `analyze`
Diagnose a bus problem from symptoms.

```
/comm-bus analyze --bus i2c --symptom "BUSY flag stuck"
/comm-bus analyze --bus spi --symptom "data shifted by one byte"
/comm-bus analyze --bus can --symptom "arbitration lost on every frame"
```

### `debug`
Generate debug helper code (bus error logging, stats).

```
/comm-bus debug --bus i2c --log-errors
/comm-bus debug --bus uart --rx-stats
```

## Process

1. Identify bus type and required speed.
2. Calculate peripheral clock and baud/prescaler register value.
3. Configure GPIO alternate functions (check device datasheet for AF number).
4. Enable peripheral clock via RCC.
5. Configure DMA if transfer size > 32 bytes or if CPU must remain free.
6. Add error handler and recovery code.

## Output Examples

### I2C scan (detect all devices on bus)
```c
void i2c_scan(I2C_HandleTypeDef *hi2c)
{
    for (uint8_t addr = 0x08; addr < 0x78; addr++) {
        if (HAL_I2C_IsDeviceReady(hi2c, addr << 1, 2, 2) == HAL_OK) {
            printf("I2C device at 0x%02X\r\n", addr);
        }
    }
}
```

### UART baud rate calculation
```
APB1 clock: 42 MHz
Target baud: 115200

USARTDIV = 42,000,000 / (16 * 115200) = 22.786
BRR mantissa = 22    = 0x16
BRR fraction = 0.786 * 16 = 12.58 ≈ 13 = 0xD
BRR register = 0x16D (22 * 16 + 13 = 365 = 0x16D)
Actual baud  = 42,000,000 / (16 * 22.8125) = 115,107 (-0.08% error)
```

### CAN bit timing at 500 kbit/s (APB1 42 MHz)
```
TQ = 1 / (42 MHz / (BRP+1)) = 1 / (42 MHz / 5) ≈ 119 ns
Bit time = 1 / 500 kbit/s = 2000 ns = 16.8 TQ ≈ 15 TQ with prescaler=6
15 TQ: 1 sync + 12 BS1 + 2 BS2 = 15 TQ → sample point at 86.7%
```

## Error Handling

- "I2C BUSY flag" — previous transaction not completed; call HAL_I2C_DeInit + HAL_I2C_Init + bus recovery (toggle SCL 9x)
- "SPI data garbage" — wrong CPOL/CPHA mode; verify against sensor timing diagram
- "CAN no acknowledge" — check 120Ω termination at both bus ends; verify bitrate matches peer
- "UART framing error" — baud rate mismatch; check clock source and BRR register value

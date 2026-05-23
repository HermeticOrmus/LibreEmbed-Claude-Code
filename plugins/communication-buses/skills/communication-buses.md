# Communication buses pattern library

Reference patterns for I2C, SPI, UART, CAN, and USB driver development. Use as a lookup when designing or reviewing drivers.

## I2C reference

### Address resolution

| Address space | Bits | Range |
|---|---|---|
| 7-bit | bits 7..1 | 0x08–0x77 (0x00-0x07 and 0x78-0x7F reserved) |
| 10-bit | bits 9..0 | 0x000–0x3FF |

Format on the wire (7-bit):
```
S | 7-bit addr | R/W | A | ... | P
```

The R/W bit is bit 0. Many HALs accept the address pre-shifted (`address << 1`); some accept it raw. Confirm against the HAL docs — common bug source.

### Pull-up sizing

For VCC = 3.3V:

| Speed | Recommended pull-up |
|---|---|
| Standard (100 kHz) | 4.7 kΩ |
| Fast (400 kHz) | 4.7 kΩ or 2.2 kΩ |
| Fast Plus (1 MHz) | 2.2 kΩ or 1 kΩ |
| High Speed (3.4 MHz) | 1 kΩ + external buffer |

Bus capacitance matters. Wire capacitance ~ 1 pF/cm. Total bus capacitance (wire + slaves + master) should be < 400 pF for standard, < 200 pF for fast modes.

### Clock stretching

Slave holds SCL low to gain processing time. Master must wait. STM32 hardware I2C handles this. Some software bit-bang implementations don't. If using bit-bang, sample SCL before assuming the master controls it.

### Bus recovery

When SDA is stuck low (slave hung mid-transfer):

```
1. Configure SDA + SCL as GPIO (out of AF)
2. Pulse SCL low → high, 9-16 times
3. Check if SDA released (high)
4. If yes: generate STOP (SCL high, SDA low → high)
5. Restore SDA + SCL to AF
6. Re-init the I2C peripheral
```

## SPI reference

### Mode card

| Mode | CPOL | CPHA | Idle clock | Data captured on |
|---|---|---|---|---|
| 0 | 0 | 0 | Low | Rising edge |
| 1 | 0 | 1 | Low | Falling edge |
| 2 | 1 | 0 | High | Falling edge |
| 3 | 1 | 1 | High | Rising edge |

Most sensors: mode 0 or 3. Always verify against datasheet — wrong mode silently corrupts every byte.

### CS line patterns

**Hardware NSS** (single slave):
- Peripheral toggles NSS automatically
- Faster setup/hold timing
- Limited to one slave

**GPIO CS** (multi-slave):
- Software writes GPIO before/after transfer
- More flexible
- Setup time: typically need a few microseconds CS-low before SCK starts
- Hold time: keep CS low until last bit clocked + a few extra cycles

### DMA buffer alignment

| MCU family | Requirement |
|---|---|
| Cortex-M0/M3/M4 (no cache) | No alignment requirement beyond AHB bus |
| Cortex-M7 with cache | Buffer in non-cacheable region OR explicit cache maintenance |
| ESP32 | DMA-capable memory region only (check linker) |

For Cortex-M7 cache maintenance:
```c
// Before DMA write (CPU → peripheral):
SCB_CleanDCache_by_Addr((uint32_t*)tx_buf, len);

// Before DMA read (peripheral → CPU):
SCB_InvalidateDCache_by_Addr((uint32_t*)rx_buf, len);
```

### Daisy chain

For multiple SPI slaves on one CS:

```
Master MOSI → Slave 1 MOSI
Slave 1 MISO → Slave 2 MOSI
Slave 2 MISO → Master MISO

Common CS to all slaves
Common SCK to all slaves
```

Transfer N×M bytes for N slaves with M-byte registers. Each slave shifts out its previous-cycle data while shifting in new data. Useful for sensor arrays.

## UART reference

### Frame format

```
Start bit | Data bits (5-9) | Parity (optional) | Stop bits (1 / 1.5 / 2)
```

Common configurations:

- 8N1: 8 data, no parity, 1 stop — default for most modern UART
- 7E1: 7 data, even parity, 1 stop — legacy serial
- 8E2: 8 data, even parity, 2 stop — older industrial

### Baud rate selection

Common rates: 9600, 19200, 38400, 57600, 115200, 230400, 460800, 921600, 1500000, 2000000, 3000000

Above 921600, accuracy of the MCU's UART clock matters. STM32 USART_BRR can hit any baud rate; calculate the actual rate and verify it's within ±2% of nominal.

### RX patterns

| Throughput | Pattern |
|---|---|
| < 1 kbps | Polled (rare, debug only) |
| 1 kbps – 100 kbps | Interrupt RX + ring buffer |
| 100 kbps – 1 Mbps | DMA RX + IDLE line detection |
| > 1 Mbps | DMA RX circular + IDLE line + flow control |

### Ring buffer pattern

```c
typedef struct {
    uint8_t buf[256];
    volatile uint16_t head;
    uint16_t tail;
} ringbuf_t;

// ISR
void USART2_IRQHandler(void) {
    if (USART2->SR & USART_SR_RXNE) {
        uint8_t byte = USART2->DR;
        uint16_t next = (rb.head + 1) & 0xFF;
        if (next != rb.tail) {           // Not full
            rb.buf[rb.head] = byte;
            rb.head = next;
        }
        // else: overflow — log it
    }
}

// Task
ssize_t ringbuf_read(uint8_t *out, size_t maxlen) {
    size_t count = 0;
    while (rb.tail != rb.head && count < maxlen) {
        out[count++] = rb.buf[rb.tail];
        rb.tail = (rb.tail + 1) & 0xFF;
    }
    return count;
}
```

### Hardware flow control (RTS/CTS)

When the host can stall:
- MCU asserts RTS = "I have buffer space, send me data"
- MCU deasserts RTS = "stop, my buffer is full"
- MCU checks CTS = "host has buffer space, I can transmit"

For STM32 USART:
- `USART_CR3_CTSE` enables CTS
- `USART_CR3_RTSE` enables RTS
- Hardware handles both — no software signaling needed

## CAN reference

### Bit timing

```
Bit time = sync + propagation + phase1 + phase2
Sample point = (sync + propagation + phase1) / bit time
```

Recommended sample point: 75–87.5% of bit time. Higher sample point gives more margin for bus propagation delay but less margin for resync.

For 500 kbps on 42 MHz APB clock:
- 42 MHz / 0.5 MHz = 84 time quanta — too many, use prescaler
- Prescaler = 6 → 14 time quanta per bit
- 1 sync + 6 prop + 5 phase1 + 2 phase2 → sample point at (1+6+5)/14 = 86% ✓
- SJW = 2

### Filter banks

For STM32 bxCAN:
- 14 filter banks per CAN peripheral
- Each bank: 16-bit list mode (4 IDs) OR 16-bit mask mode (2 ID/mask pairs) OR 32-bit list (2 IDs) OR 32-bit mask (1 ID/mask)

Configure for the IDs you actually consume. Other IDs dropped at the controller (no CPU work).

### Error states

```
Active → Passive (TX error count > 127): sends recessive error frames only
Active → Bus-off (TX error count > 255): controller stops
Bus-off → Active (after 128 × 11 recessive bits): automatic recovery
```

Driver must detect bus-off and either wait for auto-recovery OR explicitly re-init. Auto-recovery is safer for production.

## USB reference

### Descriptor tree

```
Device descriptor
├─ Configuration descriptor (1+)
│  ├─ Interface descriptor (1+)
│  │  └─ Endpoint descriptor (0+)
│  └─ String descriptors (indexed)
└─ Vendor extensions (rare)
```

Total length in configuration descriptor must equal sum of all subordinate descriptor lengths. Off-by-one here causes enumeration to fail at the configuration-read step.

### Endpoint types

- **Control** (EP0) — required, bidirectional, 8/16/32/64 byte packets
- **Bulk** — high throughput, no latency guarantee, packet size 8-512
- **Interrupt** — low latency, periodic polling, packet size 8-1024
- **Isochronous** — guaranteed bandwidth, no error recovery, packet size up to 1024

### Common enumeration failures

| Symptom | Likely cause |
|---|---|
| Host doesn't see device at all | D+ pullup not raised; VBUS detection wrong |
| Host sees device but fails enumeration | Descriptor length mismatch; EP0 size wrong |
| Host enumerates but wrong driver loads | VID/PID conflict with existing driver |
| Enumerates fine but immediate disconnect | Power request > bus can provide |
| Sometimes works, sometimes not | VBUS noise; pullup raised before VBUS stable |

## Common mistakes catalog

### "I2C bus is stuck"

A slave is holding SDA low. Use bus recovery (pulse SCL 9-16 times, then STOP). Common causes:
- Power glitch on slave during transfer
- Master reset mid-transfer
- Slave with buggy firmware

### "SPI reads all 0xFFs"

Slave isn't driving MISO. Check:
- Slave VCC (at the chip, not the regulator)
- Slave reset state
- CS line actually going low during transfer
- Correct SPI mode
- Slave power-up time elapsed

### "UART loses bytes under load"

RX overrun. Either:
- Increase RX FIFO threshold to give software more time
- Switch from interrupt to DMA RX
- Add hardware flow control

### "CAN bus shows messages but receiver doesn't see them"

Filter bank misconfigured. Check the filter bank's ID + mask vs. the actual message ID being broadcast.

### "USB device works on one host, fails on another"

Descriptor issue. Some hosts are stricter than others. Run [USB-IF compliance tool](https://www.usb.org/usbet) on the descriptors.

## Cross-references

- **debug-trace** plugin: when you need to see bus traffic without a logic analyzer (ITM-based UART sniffing, etc.)
- **memory-management** plugin: DMA buffer placement in cacheable vs. non-cacheable regions
- **iot-protocols** plugin: when the bus carries IoT protocol payloads (MQTT over UART, etc.)
- **rtos-patterns** plugin: when driver completion needs to wake a task (ISR-to-task hand-off)

# Communication Buses

> I2C, SPI, UART, CAN, USB — the four-and-a-half buses every embedded system uses, the gotchas every embedded developer hits, and the driver patterns that survive real-world conditions.

## Overview

Bus drivers look simple until you ship one. Then I2C clock stretching kills your timing. SPI mode 0 vs. mode 3 silently corrupts every transfer. UART without flow control loses bytes under load. CAN frame format mismatches make the bus appear hung. USB enumeration fails with descriptors that worked in your last project. This plugin encodes the patterns that turn a bus driver from "works on the desk" into "works in the field."

## Contents

### Agents

- **bus-driver-engineer** -- Communication bus specialist with deep expertise in I2C, SPI, UART, CAN, and USB. Designs drivers with DMA + interrupt + polled fallback strategies, handles error states correctly (NAK, bus stuck, framing errors, CRC failures), and knows the specific quirks of major MCU peripheral implementations (STM32 vs. NXP vs. Nordic vs. ESP32 differences).

### Commands

- **/comm-bus** -- Driver design and debug. Hand it a bus + a problem and it returns a driver structure, init sequence, error-handling pattern, and DMA strategy where appropriate.

### Skills

- **communication-buses** -- Reference library: I2C address resolution, clock stretching handling, SPI mode + polarity reference card, UART ring buffer pattern, CAN frame layout, USB descriptor patterns, common-mistakes catalog.

## Key Capabilities

The communication-buses plugin gives you:

- **I2C driver design** with proper start/stop/repeated-start handling, clock stretching tolerance, multi-master arbitration, 7-bit and 10-bit addressing, bus recovery for stuck slaves (clock-cycle pulse pattern)
- **SPI driver design** with mode selection (0/1/2/3), CS line management (hardware CS vs. GPIO CS), DMA buffer alignment, full-duplex vs. half-duplex, daisy chain patterns, multi-slave selection trees
- **UART driver design** with ring buffer for RX, DMA for high-throughput RX (with IDLE line detection), framing + parity + break error handling, hardware flow control (RTS/CTS), RS-485 half-duplex direction control
- **CAN driver design** with frame format (standard 11-bit + extended 29-bit), bit timing computation, filter banks, error state management (active / passive / bus-off), TX mailboxes vs. FIFO patterns
- **USB CDC + HID** with descriptor patterns that actually enumerate cleanly, EP0 control transfer handling, vendor + product ID selection, multi-interface composite devices

## When to use this plugin

- Writing a new driver for a peripheral or external chip
- Debugging "I'm reading 0xFF from everything" or "bus appears stuck"
- Choosing between DMA, interrupt, and polled modes for a specific use case
- Designing for high bus throughput (> 1 Mbps SPI, multi-Mbps UART, > 1 Mbps I2C)
- Adding flow control, error recovery, or multi-master support to an existing driver
- Migrating a driver between MCU families (STM32 ↔ NXP ↔ Nordic ↔ ESP32)

## Compatibility

- **MCU families**: STM32F0-H7, NXP LPC + Kinetis + i.MX RT, Nordic nRF52/53, Microchip SAM, Renesas RA, ESP32 family, RP2040
- **HALs supported**: STM32 HAL + LL, NXP MCUXpresso SDK, Nordic nRFx + Zephyr drivers, ESP-IDF driver layer
- **Bus speeds**: I2C up to 5 MHz (Ultra Fast), SPI up to 100+ MHz peripheral-permitting, UART up to several Mbps with DMA, CAN at 1 Mbps + CAN FD at higher rates
- **External chips**: the agent knows common chip quirks for popular sensors and peripherals (LSM6DSO IMU, BME280 environmental, MCP2515 CAN controller, FT232 USB-UART bridges, etc.)

## Limitations the agent will tell you about

- It will not write a complete driver from scratch — it generates structure + init + key methods + the reasoning, and you finish the implementation.
- It does not run on your hardware. Signal-level issues (impedance, timing) require an oscilloscope; the agent recommends the measurement approach but can't replace the scope.
- For very high-speed serial (gigabit ethernet, MIPI CSI, MIPI DSI), the patterns shift to PHY + MAC concerns the agent covers more lightly.

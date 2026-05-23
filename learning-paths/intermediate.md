# Intermediate — bring up a custom board

You have a populated PCB on your desk. The crystal is the right frequency. The power rails measure clean. Now you need first firmware that confirms the board works. This is bring-up — the discipline of methodically verifying hardware via software, in the right order, with Claude Code as your bring-up partner.

## What you'll learn

- The bring-up order that catches problems early
- How to write the smallest possible firmware that confirms each subsystem
- How to use the `/cortex-m`, `/comm-bus`, and `/debug-embedded` agents during bring-up
- How to interpret signs from the hardware (LEDs that don't blink, peripherals that don't enumerate, sensors that return 0xFF)

## What you'll need

- Your custom board (designed yourself or by your team)
- A working development host with the toolchain (see [beginner.md](beginner.md) for setup)
- A debugger probe (J-Link, ST-Link, or CMSIS-DAP)
- A multimeter — non-negotiable
- An oscilloscope — almost non-negotiable for bring-up
- A logic analyzer — useful, especially Saleae or Salea-class
- A few hours of focused time

## The bring-up order

Bring-up has a correct order. Doing it out of order means hardware bugs disguised as software bugs disguised as hardware bugs. The order:

1. **Power rails** — measure, don't assume
2. **MCU heartbeat** — toggle one GPIO at a known frequency, scope it
3. **Clock** — verify the actual clock frequency
4. **Debug interface** — get OpenOCD connecting reliably
5. **Console** — UART out so you can printf-debug from here on
6. **Peripherals** — one at a time, simplest first

Skipping any of these is a false economy.

## Step 0 — Before you connect power

With a multimeter, on a powered-OFF board:

- Verify VCC to GND is not a short
- Verify each power rail (3.3V, 1.8V, etc.) input pin to GND is not a short
- Verify the regulator's input matches what the schematic says

If any of these fail, fix the hardware before connecting power. Powering up a short blows components.

## Step 1 — Power rails

Connect power. With the multimeter, measure each rail at the regulator output and at the MCU's VDD pin:

- 3.3V rail: should read 3.25V to 3.35V
- 1.8V rail: should read 1.78V to 1.82V
- VCAP / VCAP_1 / VCAP_2: usually 1.2V on STM32H7

If any rail is wrong:
- Wrong voltage → regulator config error or wrong feedback resistor
- Right voltage but droops under load → regulator can't supply the current
- Oscillating → regulator compensation wrong (cap value, location)

Don't proceed until power is correct.

## Step 2 — MCU heartbeat

Write the smallest possible firmware that toggles a GPIO at a known rate. Don't enable any peripherals beyond what's needed.

```
/cortex-m write the smallest possible bring-up firmware for STM32F411RE (or whatever your MCU is) that toggles PB5 at 1 Hz. Use HSI as the clock source (no external crystal needed). Skip everything else.
```

Flash it. Scope PB5. You should see a clean 1 Hz square wave.

If you don't:
- MCU isn't running — power, reset, or boot mode issue
- MCU is running but GPIO isn't toggling — peripheral clock, GPIO mode config, or wrong pin
- GPIO toggles but at wrong rate — clock isn't what you think it is

This is the most common bring-up failure point. Don't skip the scope verification.

## Step 3 — Clock

Once heartbeat works on HSI (internal RC, ~16 MHz), bring up the external crystal:

```
/cortex-m extend the bring-up firmware to enable HSE (8 MHz external crystal) and configure the PLL for 100 MHz system clock. Verify SystemCoreClock matches.
```

The trick is: after enabling PLL, the firmware must wait for PLL_RDY before switching the clock source. Otherwise the switch silently fails and you're still on HSI.

```c
// Enable HSE
RCC->CR |= RCC_CR_HSEON;
while (!(RCC->CR & RCC_CR_HSERDY));  // Wait for HSE stable

// Configure PLL: HSE 8 MHz × 100 / 4 / 2 = 100 MHz
RCC->PLLCFGR = (8 << 0)                  // PLLM = 8
             | (200 << 6)                // PLLN = 200
             | (0 << 16)                 // PLLP = 0 (divider = 2)
             | (RCC_PLLCFGR_PLLSRC_HSE); // Source = HSE

// Enable PLL
RCC->CR |= RCC_CR_PLLON;
while (!(RCC->CR & RCC_CR_PLLRDY));

// Set flash latency for 100 MHz (3 wait states)
FLASH->ACR = FLASH_ACR_LATENCY_3WS | FLASH_ACR_PRFTEN;

// Switch to PLL as system clock
RCC->CFGR = (RCC->CFGR & ~RCC_CFGR_SW) | RCC_CFGR_SW_PLL;
while ((RCC->CFGR & RCC_CFGR_SWS) != RCC_CFGR_SWS_PLL);
```

Verify by scoping PB5 again — it should now toggle at a different rate (because the delay was tuned to HSI).

If PLL doesn't start: usually the crystal isn't oscillating. Scope OSC_IN — should be ~1 Vpp sine at 8 MHz.

## Step 4 — Debug interface

OpenOCD should already be working from the beginner steps. If your custom board uses a non-standard SWD pinout, verify SWCLK + SWDIO continuity to the MCU.

Common bring-up SWD issues:
- SWO pin not broken out — can't get ITM traces. Plan to add it on the next rev.
- Series resistors on SWD lines too high — can degrade signal. Standard is 22Ω.
- SWCLK + SWDIO on a connector that has bouncing contact — secure the connection.

## Step 5 — Console

You want a UART out so you can printf-debug from here on. This is the single most useful bring-up tool after the scope.

```
/comm-bus add UART2 at 115200 8N1 to my STM32F411RE bring-up firmware. Use PA2 (TX) and PA3 (RX). Make printf go to UART2 via _write retarget.
```

Expected output:
- Init for USART2 on APB1 with 115200 baud
- `_write` syscall implementation that loops `USART2->DR = c; while (!(USART2->SR & USART_SR_TXE));`
- Note about disabling buffering (`setvbuf(stdout, NULL, _IONBF, 0);` in main)

Connect a USB-UART adapter (FTDI, CP2102, CH340) at 3.3V logic level. Hook RX of the adapter to PA2 of the MCU. Open a terminal at 115200.

```c
printf("Bring-up firmware v0.1\r\n");
printf("System clock: %lu Hz\r\n", SystemCoreClock);
```

You should see this in the terminal. If you don't:

- Wrong baud rate — verify USART_BRR calculation
- Wrong pin alternate function — STM32F4 USART2 needs AF7
- TX pin not in alternate function mode — check GPIO MODER for that pin

## Step 6 — One peripheral at a time

Now bring up peripherals one at a time. Order them by criticality:

1. **External crystal RTC** (if any) — provides timekeeping
2. **External flash** (if any) — provides storage
3. **Sensors** — typically I2C or SPI
4. **Radio / communications** — typically SPI or UART
5. **Actuators / outputs** — PWM, DAC

For each:

```
/comm-bus bring up I2C1 on PB6 (SCL) + PB7 (SDA) at 400 kHz for an LSM6DSO IMU at address 0x6B. Just verify WHOAMI returns 0x6C.
```

Then verify the WHOAMI read returns the expected value:

```c
uint8_t whoami;
i2c_read_reg(LSM6DSO_ADDR, LSM6DSO_WHO_AM_I_REG, &whoami, 1);
printf("LSM6DSO WHO_AM_I: 0x%02X (expected 0x6C)\r\n", whoami);
```

If you read 0xFF: slave not responding. Walk the diagnostic tree from `/debug-embedded`.

If you read a wrong value: address wrong, or you accidentally configured the chip into a mode that changed WHO_AM_I.

If you read 0x6C: success. Move to the next peripheral.

## Step 7 — Bring-up report

When all peripherals report green, write a bring-up report. It's not just process — it documents what you tested, what works, what doesn't, and what surprised you.

```
Board: SensorNode rev A, S/N 001
Date: 2026-05-23
Engineer: <name>

Power rails:
  - 3.3V at MCU VDD: 3.31V ✓
  - 1.8V at sensor VCC: 1.79V ✓

Clock:
  - HSE 8 MHz: oscillates correctly, ~1.1 Vpp on OSC_IN ✓
  - PLL at 100 MHz: verified via toggle rate ✓

Debug:
  - SWD connection reliable ✓
  - SWO pin broken out — pending for next rev (open in this rev)

Console:
  - UART2 at 115200 baud working, printf retargeted ✓

Peripherals:
  - LSM6DSO IMU on I2C1 @ 0x6B: WHO_AM_I = 0x6C ✓
  - W25Q128 SPI flash on SPI1: JEDEC ID = 0xEF4018 ✓
  - SX1262 LoRa radio on SPI2: status reg read 0x12 (unexpected — investigate)

Open items:
  - Add SWO breakout in rev B
  - SX1262 status reg returning 0x12 — possibly held in reset; verify NRST line
```

## What you learned

- The bring-up order matters; doing it out of order disguises hardware bugs as software bugs
- Power → heartbeat → clock → debug → console → peripherals is the safe sequence
- Scope verification at each step catches issues before they compound
- Bring-up is iteration: do, measure, decide, next step
- The agents in LibreEmbed are tuned to help — they ask about hardware specifics rather than fabricating

## Common gotchas

1. **Flash latency wrong for higher clock** → MCU runs but accesses to Flash randomly fail. Symptom: hard faults after PLL switch.
2. **VBAT not connected on the board** → some peripherals (RTC) fail mysteriously. Scope VBAT.
3. **Crystal load caps wrong** → crystal doesn't start, or starts and drifts. Match datasheet recommendation, usually 18-22 pF.
4. **Pull-ups missing on I2C** → bus floats; reads return random data, not 0xFF. Add external 4.7 kΩ pull-ups.
5. **Pin conflicts** → two peripherals fighting for the same pin. STM32CubeMX or careful schematic review catches this; bring-up exposes it as one peripheral working only when another is disabled.

## Next: [Advanced — ship firmware that survives the field](advanced.md)

You brought up the board. Next: ship firmware that survives a year in the field — OTA updates that don't brick devices, watchdog patterns that catch real failures, CI/CD for firmware, long-term support patterns.

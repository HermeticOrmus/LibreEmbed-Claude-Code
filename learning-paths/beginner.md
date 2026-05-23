# Beginner — your first MCU project with Claude Code

You've programmed C. Maybe you've blinked an LED on Arduino. You want to graduate to a real MCU with a GCC toolchain, a hardware debugger, and Claude Code as a thinking partner. This path takes you from "I bought a Nucleo" to "blinky over FreeRTOS" with the agent helping at each step.

## What you'll build

A real-board blinky project on an STM32 Nucleo-64 (any flavor — F401, F411, F446, L476, all work). The blinky will run as a FreeRTOS task, with a second task reading a button via interrupt and toggling the LED. By the end you'll have a firmware image you flashed yourself, with code Claude Code helped you write and debug.

Why this matters: the difference between Arduino and "real embedded" is the toolchain, the debugger, the RTOS, and the discipline. This path crosses all four boundaries.

## Prerequisites

- C programming: pointers, structs, function pointers, bit manipulation
- Linux or macOS development host (Windows + WSL2 works, but native is simpler)
- ~$20-30 for hardware: a Nucleo-64 board has the embedded ST-Link debugger built in, so no separate probe needed

## Step 0 — Install the toolchain

```bash
# Linux (Ubuntu / Debian)
sudo apt update
sudo apt install gcc-arm-none-eabi gdb-multiarch openocd

# macOS
brew install --cask gcc-arm-embedded
brew install openocd

# Both
arm-none-eabi-gcc --version   # Should print: arm-none-eabi-gcc (...) 12.x or 13.x or newer
openocd --version             # Should print: Open On-Chip Debugger 0.11 or newer
```

Install Claude Code (if you haven't):
- See https://docs.claude.com/en/docs/claude-code

Install LibreEmbed plugins (if you haven't):
```bash
git clone https://github.com/HermeticOrmus/LibreEmbed-Claude-Code.git ~/projects/LibreEmbed-Claude-Code
cd ~/projects/LibreEmbed-Claude-Code
./setup.sh
```

Restart Claude Code so it picks up the plugins.

## Step 1 — Buy the hardware

Recommended: **STM32 Nucleo-64 (F411RE)** — ~$15 USD from Mouser, Digi-Key, or Adafruit. Has built-in ST-Link debugger via USB.

Alternative: any other Nucleo-64. Code is portable across the family with minor pin adjustments.

Plug the board into USB. The PWR LED (green) should light. Linux + macOS: the embedded ST-Link enumerates as a USB device. Confirm with `lsusb` (Linux) — you should see `STMicroelectronics ST-LINK/V2.1`.

## Step 2 — Use Claude Code to scaffold the project

In a Claude Code session:

```
/cortex-m scaffold a bare-metal project for STM32F411RE using GCC ARM and Make. Include linker script, startup code, vector table, and a simple main that blinks LD2 (PA5).
```

Expected output:
- `Makefile` with `arm-none-eabi-gcc` invocation, optimization flags, output as ELF + HEX + BIN
- `linker.ld` with appropriate memory regions for F411RE (512 KB Flash @ 0x08000000, 128 KB SRAM @ 0x20000000)
- `startup_stm32f411xe.s` with vector table + Reset_Handler + default fault handlers
- `main.c` with RCC clock enable for GPIOA, GPIO mode config for PA5 as output, a loop that toggles PA5 with a busy-wait delay

Don't accept boilerplate. If the linker script is generic ARM Cortex-M without the F411-specific memory map, that's wrong. Ask Claude to revise.

Build:

```bash
make
```

You should see `firmware.elf`, `firmware.hex`, `firmware.bin` in your output directory.

## Step 3 — Flash + run

Connect OpenOCD to the embedded ST-Link:

```bash
openocd -f interface/stlink.cfg -f target/stm32f4x.cfg
```

In another terminal, flash:

```bash
arm-none-eabi-gdb firmware.elf
(gdb) target remote :3333
(gdb) load
(gdb) continue
```

LD2 (the green LED next to PA5) should blink. If it doesn't:

```
/debug-embedded LD2 isn't blinking. I built and flashed STM32F411RE with the scaffolded code. OpenOCD connects fine. What's the diagnosis?
```

The agent will walk a diagnostic tree: is the clock running, is GPIOA enabled, is PA5 actually in output mode, is the delay long enough, is the toggle being optimized out by the compiler?

## Step 4 — Add FreeRTOS

Now graduate from bare-metal to RTOS:

```
/rtos add FreeRTOS to my bare-metal STM32F411RE project. I want two tasks: a blinky task on LD2 (PA5) and an idle health task. Use the FreeRTOS Cortex-M4F port.
```

Expected output:
- Instructions to clone or vendor FreeRTOS Kernel into the project (`FreeRTOS-Kernel/` subdirectory)
- `FreeRTOSConfig.h` with appropriate settings for F411RE (configCPU_CLOCK_HZ = 100 MHz, configTOTAL_HEAP_SIZE, configUSE_PREEMPTION = 1, configCHECK_FOR_STACK_OVERFLOW = 2)
- Modifications to `main.c` to create tasks + call `vTaskStartScheduler()`
- The blinky task code with proper `vTaskDelay()` instead of busy-wait
- Build system updates to compile FreeRTOS sources

Rebuild + flash. LD2 should blink, controlled by the RTOS scheduler.

## Step 5 — Add the button task with interrupt

Now use the EXTI interrupt for the user button (B1 on PC13):

```
/cortex-m add an EXTI interrupt on PC13 (the Nucleo user button B1, active low with internal pull-up). The interrupt should notify a FreeRTOS task that toggles a global flag. The blinky task should check the flag and change its blink rate.
```

Expected output:
- GPIO config for PC13 as input with pull-up
- SYSCFG configuration to route EXTI13 to PC13
- EXTI line 15-10 IRQ handler that calls `vTaskNotifyGiveFromISR`
- Button task that does `ulTaskNotifyTake(pdTRUE, portMAX_DELAY)` then toggles the flag
- Blinky task reading the flag

Rebuild + flash. Press B1 — the LED's blink rate should change.

## Step 6 — Debug something that breaks

It will break. Embedded code always breaks the first time. Common failures:

- **Interrupt fires but task isn't notified**: usually NVIC priority misconfigured (above `configMAX_SYSCALL_INTERRUPT_PRIORITY`)
- **Task never runs**: stack too small, or priority lower than another always-ready task
- **Hard fault**: usually invalid pointer or stack overflow

When something breaks:

```
/debug-embedded The interrupt fires (I see the LED toggle when I add code to the ISR), but my button task never wakes up. What am I missing?
```

The agent will check NVIC priority, the FreeRTOS configuration, and the task notification API usage. This is the kind of debugging Claude Code excels at — walking the cause-effect chain you don't yet have intuition for.

## What you learned

By the end of this path you should understand:

- The boundary between bare-metal C and an RTOS
- Why the linker script and startup code matter
- How GPIO + EXTI work at the register level (you saw it in the scaffolded code)
- The role of NVIC priorities, especially in RTOS contexts
- How tasks communicate via notifications
- How to debug with GDB + OpenOCD

Plus: how to use Claude Code with embedded constraints. The agents in this bundle are tuned for embedded — they ask for hardware specifics, they suggest measurement steps, they don't fabricate.

## Common gotchas

1. **GCC version mismatches** — older arm-none-eabi-gcc versions miss recent CMSIS headers. Update to 12.x or 13.x.
2. **OpenOCD permissions on Linux** — needs udev rule for ST-Link. Most distros include one; if not, `99-openocd.rules` from OpenOCD's contrib/.
3. **Optimization removes your code** — `-O0` keeps everything; `-O2` may inline `delay()` to nothing if it's just a counter. Use `__NOP()` or proper SysTick delay.
4. **Stack too small for FreeRTOS task** — default 128 words may be enough for a simple task, but if you call printf or HAL functions, increase it. The `/rtos` agent helps size stacks.

## Next: [Intermediate — bring up a custom board](intermediate.md)

You used a Nucleo with everything wired for you. Next: bring up firmware on a board you (or your team) designed, where the bring-up steps test whether the hardware is correct in addition to the software.

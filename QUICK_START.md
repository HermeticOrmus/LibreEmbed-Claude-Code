# Quick start

Twenty minutes from clone to "blinky on a real MCU with Claude Code helping."

## What you'll do

1. Install the plugins
2. Use Claude Code with the `/rtos` agent to design a task structure for a real-board project
3. Verify the agent's output makes sense for embedded constraints

## What you'll need

- Linux or macOS development host (Windows + WSL2 works)
- GCC ARM toolchain installed (`arm-none-eabi-gcc --version` works)
- A debugger probe — J-Link or ST-Link or any CMSIS-DAP-compatible (or just borrow a Nucleo board with embedded ST-Link)
- A target MCU board — STM32F4 Discovery, Nucleo, or any ARM Cortex-M with SWD broken out
- Claude Code installed

If you don't have hardware yet: an STM32 Nucleo-64 board (any flavor) is ~$15, has an embedded ST-Link, and works out of the box with the plugins. The `/cortex-m` agent is tuned for the Nucleo family.

## 1. Clone + install

Inside Claude Code, add the marketplace and install what this walkthrough uses:

```text
/plugin marketplace add HermeticOrmus/LibreEmbed-Claude-Code
/plugin install rtos-patterns@libre-embed
/plugin install arm-cortex-m@libre-embed
/plugin install communication-buses@libre-embed
```

Or clone and install everything from a terminal:

```bash
git clone https://github.com/HermeticOrmus/LibreEmbed-Claude-Code.git ~/projects/LibreEmbed-Claude-Code
cd ~/projects/LibreEmbed-Claude-Code
./setup.sh
```

`setup.sh` registers the checkout as the `libre-embed` marketplace and installs all 15 plugins plus the optional `libre-embed-hooks` through the Claude Code CLI (it needs `claude` and `jq` on your `PATH`). Restart Claude Code afterwards.

Confirm:

```bash
claude plugin list | grep -c '@libre-embed'
# Should print 16 after ./setup.sh (15 plugins plus libre-embed-hooks)
```

## 2. Open Claude Code at your firmware project root

If you don't have a project yet, scaffold one:

```bash
mkdir ~/projects/sensor-logger && cd ~/projects/sensor-logger
git init
```

Open Claude Code in this directory.

## 3. Talk to the RTOS agent

In the Claude Code session:

```
/rtos design a FreeRTOS task structure for a sensor logger that samples a 3-axis accelerometer at 1 kHz over SPI and writes to a SD card via SDIO every 200 ms
```

What you should see in the agent's response:

- A task graph with **at least** three tasks: SPI sampler (highest priority, time-critical), SD writer (medium priority, throughput-bound), watchdog/heartbeat (lowest priority)
- IPC choice — likely a FreeRTOS queue between sampler and writer, sized for ≥ 200 ms of buffer at 1 kHz × 6 bytes/sample = ~1200 bytes
- A note on priority inversion risk (the SD writer holds a mutex that the sampler might wait on)
- A real-board-aware constraint (DMA-backed SPI to keep the sampler's CPU time minimal)

If the agent gives you a generic answer with no real numbers, the plugin isn't installed correctly. Re-run `./setup.sh` and try again.

## 4. Use the communication-buses agent for the driver

```
/comm-bus write an SPI driver in C for the LSM6DSO IMU on STM32F4 using HAL_SPI_TransmitReceive with DMA. Configure for 10 MHz, mode 0, 8-bit data
```

Expected output:

- Init function with proper GPIO + SPI clock enables
- DMA stream selection (DMA1 vs. DMA2, which streams pair with SPI1)
- Read/write helpers with CS GPIO toggling
- Awareness of the LSM6DSO's CS auto-increment behavior

## 5. Use the debug-trace agent when something's wrong

This is the agent you'll talk to most.

```
/debug-embedded I'm reading 0xFF from every register on the LSM6DSO. SPI is configured for mode 0, 10 MHz. CS is bouncing on the scope. What's wrong?
```

Expected reasoning chain:

- CS bouncing usually means CS line is floating between transactions or has a missing pull-up
- 0xFF on every register is the read pattern when MISO is floating (no slave driving the line)
- Likely root cause: CS is never going low (config error) OR slave isn't powered/clocked
- Diagnostic sequence: scope SCLK + CS together, verify CS goes low for the right duration

## 6. When you're ready to flash

The bundle does NOT auto-flash. That's intentional — flashing untested firmware can brick devices. The plugins suggest flash commands but you run them.

`setup.sh` also installs the optional `libre-embed-hooks` plugin. Its pre-tool-use hook asks for confirmation before flash and erase commands (OpenOCD `program`, `st-flash write`, `west flash`, `idf.py flash`, `pyocd flash`, and others) and before a file tool touches key or secret files. Skip it with `./setup.sh --no-safety-hooks`, or turn it off later with `claude plugin disable libre-embed-hooks@libre-embed`.

## Iterating

The pattern across all 15 plugins is the same:

1. Describe the problem to the relevant agent
2. The agent produces a structured response with real embedded constraints accounted for
3. You verify against your hardware reality
4. You implement, iterating with the agent for specific debug or refinement

## What's next

- **[Beginner](learning-paths/beginner.md)** — full first-MCU walkthrough from "I bought a Nucleo" to "blinky over RTOS"
- **[Intermediate](learning-paths/intermediate.md)** — bring up a custom board from a schematic
- **[Advanced](learning-paths/advanced.md)** — ship firmware that survives a year in the field

## Troubleshooting

- Agent answer is generic / not embedded-specific → `setup.sh` failed; re-run + verify
- `/rtos` not recognized → plugins installed but Claude Code wasn't restarted; restart it, then check `claude plugin list`
- All commands work but agents are too brief → you may have an older Claude Code build; agent-mode requires Claude Code v1.x+

For other issues: [TROUBLESHOOTING.md](TROUBLESHOOTING.md).

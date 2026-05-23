<p align="center">
  <img src="https://ormus.solutions/mascot/chain_braces_to_swan.gif" alt="LibreEmbed Claude Code" width="128" style="image-rendering: pixelated;" />
</p>

<h1 align="center">LibreEmbed Claude Code</h1>

<p align="center">
  <em>Embedded systems, firmware, and IoT development with Claude Code — 15 specialized plugins from bare metal to RTOS</em>
</p>

<p align="center">
  <a href="https://github.com/HermeticOrmus/LibreEmbed-Claude-Code/stargazers"><img src="https://img.shields.io/github/stars/HermeticOrmus/LibreEmbed-Claude-Code?style=flat-square&color=aa8142" alt="Stars" /></a>
  <a href="https://github.com/HermeticOrmus/LibreEmbed-Claude-Code/blob/main/LICENSE"><img src="https://img.shields.io/github/license/HermeticOrmus/LibreEmbed-Claude-Code?style=flat-square&color=aa8142" alt="License" /></a>
  <a href="https://github.com/HermeticOrmus/LibreEmbed-Claude-Code/commits"><img src="https://img.shields.io/github/last-commit/HermeticOrmus/LibreEmbed-Claude-Code?style=flat-square&color=aa8142" alt="Last Commit" /></a>
  <img src="https://img.shields.io/badge/C-aa8142?style=flat-square&logo=c&logoColor=white" alt="C" />
  <img src="https://img.shields.io/badge/Embedded-aa8142?style=flat-square&logo=arm&logoColor=white" alt="Embedded" />
  <img src="https://img.shields.io/badge/Claude_Code-aa8142?style=flat-square&logo=anthropic&logoColor=white" alt="Claude Code" />
</p>

---

> **Skills, agents, commands, and workflows for embedded systems development with Claude Code.**

Most LLM-assisted coding patterns assume a web stack. Embedded development isn't web. The toolchain is GCC + OpenOCD + a hardware debugger. The runtime is bare metal or a 32 KB RTOS. The bugs live in a register on a chip you can hold in your hand. The feedback loop is "compile, flash, watch the LED, decide."

**LibreEmbed is the Claude Code stack for that work.** Fifteen plugins covering the layers that actually matter when you're bringing up a board, writing a driver, debugging across SWD, or shipping firmware that has to survive a reflash in the field.

---

## The shift this kit responds to

Andrej Karpathy framed the broader change in December 2025:

> *"I've never felt this much behind as a programmer. The profession is being dramatically refactored."*
>
> *"New vocabulary: agents, subagents, their prompts, contexts, memory, modes, permissions, tools, plugins, skills, hooks, MCP, LSP, slash commands, workflows, IDE integrations..."*

Embedded development has resisted that refactor longer than most domains. The reasons are real — proprietary toolchains, hardware-in-the-loop testing, safety constraints, vendor lock-in — but the result is that embedded teams have lagged in adopting agent-assisted workflows. LibreEmbed exists to close that gap. Each plugin encodes a slice of embedded expertise as agent prompts + commands + skills, so the agent can think alongside you when you're trying to figure out why the chip won't enumerate over USB.

### Where LibreEmbed fits in the Claude Code stack

| Claude Code component | LibreEmbed provides |
|---|---|
| **Plugins** | 15 domain plugins (RTOS, ARM Cortex-M, comm buses, IoT, FPGA, safety-critical, more) |
| **Agents** | Domain-specialist agents for each plugin — e.g., RTOS engineer, ARM Cortex-M expert, IoT protocol designer |
| **Commands** | Quick-access slash commands per plugin (`/rtos`, `/comm-bus`, `/iot`, `/cortex-m`, etc.) |
| **Skills** | Reusable pattern libraries — calibration routines, sensor fusion, bootloader patterns, OTA workflows |
| **Hooks** | Pre/post tool hooks for safety nets (e.g., warn before flashing untested code) |
| **Templates** | Project scaffolds, CLAUDE.md per plugin, Makefile + linker script starting points |

---

## What's included

```
LibreEmbed-Claude-Code/
├── 15 plugins              # one per embedded subdomain
│   ├── arm-cortex-m       # ARM Cortex-M0/M3/M4/M7/M33 programming
│   ├── bare-metal          # Register manipulation, linker scripts, minimal runtime
│   ├── bootloader-design   # Bootloader architecture, secure boot, A/B partitions
│   ├── communication-buses # I2C, SPI, UART, CAN, USB protocols + drivers
│   ├── debug-trace         # JTAG, SWD, ITM, ETM, printf debugging, logic analyzers
│   ├── embedded-linux      # Yocto, Buildroot, device trees, kernel modules
│   ├── embedded-testing    # On-target unit tests, HIL testing, hardware mocks
│   ├── firmware-update     # OTA updates, dual-bank flash, rollback mechanisms
│   ├── fpga-integration    # MCU+FPGA integration, soft cores, HDL basics
│   ├── iot-protocols       # MQTT, CoAP, LwM2M, BLE, LoRaWAN, Zigbee, Thread
│   ├── memory-management   # Static allocation, pools, stack/heap analysis
│   ├── power-management    # Sleep modes, power budgeting, energy harvesting
│   ├── rtos-patterns       # FreeRTOS, Zephyr, task design, IPC, priority inversion
│   ├── safety-critical     # IEC 61508, DO-178C, MISRA C, certification patterns
│   └── sensor-integration  # Driver bring-up, calibration, filtering, fusion
├── 3 learning paths        # beginner → intermediate → advanced
├── templates               # Per-project CLAUDE.md, Makefile, linker, devicetree
└── hooks                   # Safety hooks (flash-warning, secret-scrub, etc.)
```

---

## The 15 plugins

Each plugin ships an **agent** (specialist persona with deep domain knowledge), a **command** (quick slash invocation), and a **skill** (reusable pattern library).

### Microcontroller core

| Plugin | Agent / Command | What it does |
|---|---|---|
| **arm-cortex-m** | `/cortex-m` | CMSIS, HAL vs. LL, startup code, vector table, MPU configuration, MMU on Cortex-A boundaries. ARM Cortex-M0+/M3/M4/M7/M33. |
| **bare-metal** | `/bare-metal` | Register-level programming, linker scripts, minimal runtime (no libc), C++ on embedded, freestanding builds. |
| **memory-management** | `/memory` | Static allocation strategies, memory pools, stack analysis via GCC `-fstack-usage`, heap-less design, fragmentation patterns. |
| **power-management** | `/power` | Sleep modes (run / sleep / stop / standby), peripheral clock gating, wake sources, power budgeting, energy harvesting designs. |

### Communication + I/O

| Plugin | Agent / Command | What it does |
|---|---|---|
| **communication-buses** | `/comm-bus` | I2C (master/slave, clock stretching, multi-master), SPI (modes, DMA, CS handling), UART (DMA, ring buffers, flow control), CAN (frame format, filters, error states), USB CDC/HID. |
| **sensor-integration** | `/sensor` | Sensor driver bring-up, factory calibration, Allan variance, complementary + Kalman filtering, sensor fusion (IMU + magnetometer + GPS). |
| **iot-protocols** | `/iot` | MQTT (QoS levels, retained messages, LWT), CoAP, LwM2M device management, BLE GATT, LoRaWAN class A/B/C, Zigbee, Thread. |

### Runtime + system

| Plugin | Agent / Command | What it does |
|---|---|---|
| **rtos-patterns** | `/rtos` | FreeRTOS + Zephyr task design, IPC primitives (queues, mutexes, semaphores, event groups), priority inversion + inheritance, watchdog patterns, deferred interrupt processing. |
| **embedded-linux** | `/embedded-linux` | Yocto + Buildroot, device tree authoring, kernel module patterns, init systems (systemd vs. OpenRC vs. BusyBox init), userspace driver patterns. |
| **bootloader-design** | `/bootloader` | First-stage vs. second-stage bootloaders, secure boot chains, signature verification, A/B partition designs, fail-safe rollback, ROM bootloader interaction. |
| **firmware-update** | `/firmware-update` | OTA update protocols, dual-bank flash, delta updates (bsdiff/Heatshrink), version negotiation, anti-rollback, signed-by-vendor enforcement. |

### Hardware-software integration

| Plugin | Agent / Command | What it does |
|---|---|---|
| **fpga-integration** | `/fpga` | MCU + FPGA designs, AXI bus integration, soft-core CPUs (RISC-V on FPGA), DMA across the boundary, HDL basics for the embedded developer. |
| **debug-trace** | `/debug-embedded` | JTAG + SWD setup, OpenOCD + pyOCD, ITM (Instrumentation Trace Macrocell), ETM (Embedded Trace Macrocell), printf-over-SWO, logic analyzer captures, oscilloscope vs. logic analyzer trade-offs. |

### Quality + compliance

| Plugin | Agent / Command | What it does |
|---|---|---|
| **embedded-testing** | `/embedded-test` | On-target unit tests (Unity, CMocka, Ceedling), Hardware-in-the-Loop (HIL) test rigs, hardware peripheral mocks, golden-image regression, CI for embedded. |
| **safety-critical** | `/safety` | IEC 61508 SIL levels, DO-178C aviation, ISO 26262 automotive, MISRA C compliance, formal verification basics, freedom-from-interference. |

---

## Quick start

```bash
# Clone
git clone https://github.com/HermeticOrmus/LibreEmbed-Claude-Code.git ~/projects/LibreEmbed-Claude-Code

# Install all 15 plugins into Claude Code
cd ~/projects/LibreEmbed-Claude-Code
./setup.sh

# Or install just the plugins you need
./setup.sh --only rtos-patterns,communication-buses,iot-protocols
```

Then in any Claude Code session at your firmware project root:

```
/rtos design a task structure for a sensor logger that samples 4 channels at 1 kHz and writes to QSPI flash every 100 ms
```

See [QUICK_START.md](QUICK_START.md) for the full walkthrough on a real board (STM32F4 Discovery + ICM-20948 IMU).

---

## Learning paths

The repo is organized by experience level. Pick your entry point:

### Beginner — *"My first MCU project with Claude Code"*

You've programmed C. Maybe you've blinked an LED on Arduino. You want to graduate to a real MCU + GCC toolchain + a hardware debugger, with Claude Code helping you avoid the obvious mistakes.

→ [`learning-paths/beginner.md`](learning-paths/beginner.md)

### Intermediate — *"Bring up a custom board"*

You have a schematic + a populated PCB on your desk. The crystal is the right frequency. The power rails measure clean. Now you need to write the first firmware that confirms the board works. Claude Code as your bring-up partner.

→ [`learning-paths/intermediate.md`](learning-paths/intermediate.md)

### Advanced — *"Ship firmware that survives the field"*

OTA updates that don't brick devices. Watchdog patterns that catch real failures. CI/CD for firmware. Long-term support patterns. The work that makes firmware credible for production.

→ [`learning-paths/advanced.md`](learning-paths/advanced.md)

---

## Compatibility

- **Toolchains**: GCC ARM (any recent version), Clang/LLVM with embedded targets, Zephyr SDK, ESP-IDF, STM32CubeIDE, Microchip XC32, Renesas e² studio
- **MCU families covered**: ARM Cortex-M0/M0+/M3/M4/M7/M33 (STM32, NXP LPC + Kinetis + i.MX RT, Nordic nRF, Microchip SAM, RP2040, ESP32, Renesas RA), MSP430 (light), AVR (light)
- **RTOS coverage**: FreeRTOS (deep), Zephyr (deep), ThreadX (moderate), RT-Thread (light)
- **Build systems**: Make, CMake, PlatformIO, Zephyr west, ESP-IDF idf.py
- **Debuggers**: SEGGER J-Link (preferred), ST-Link, CMSIS-DAP, Black Magic Probe, JLink-OB
- **OS**: Linux / macOS for development host (Windows tolerated, WSL2 recommended)

LibreEmbed makes no calls home and does not require any vendor account beyond what your toolchain itself needs.

---

## Contributing

Embedded is wide. Fifteen plugins is a start; depth varies per plugin (see [CHANGELOG.md](CHANGELOG.md) for the per-plugin maturity matrix). PRs are especially welcome for:

- **RTOS** other than FreeRTOS + Zephyr (ThreadX, RT-Thread, NuttX, ChibiOS deeper coverage)
- **Vendor-specific HALs** (we lean on CMSIS today; vendor HAL conventions need their own plugins or sub-plugins)
- **Regional certifications** (CCC China, KC Korea, etc.) — the safety-critical plugin is Western-cert-centric today
- **Toolchain support** (Microchip XC32, Renesas e², IAR, Keil — currently GCC-centric)
- **Worked examples** with real hardware — the more real-board demos, the more credible the bundle

See [CONTRIBUTING.md](CONTRIBUTING.md) for the contribution model.

---

## Part of the Libre Open-Source Stack for Claude Code

LibreEmbed is one of a family of open-source toolkits for Claude Code, each focused on a specific lane:

- [LibreUIUX-Claude-Code](https://github.com/HermeticOrmus/LibreUIUX-Claude-Code) — UI/UX system (152 agents, 70 plugins, 76 commands, 74 skills)
- [LibreGEO-Claude-Code](https://github.com/HermeticOrmus/LibreGEO-Claude-Code) — AI-search optimization (12 skills for ChatGPT/Perplexity/Gemini citation)
- [LibreGameDev-Claude-Code](https://github.com/HermeticOrmus/LibreGameDev-Claude-Code) — game development across Godot, Unity, Unreal
- [LibreFinTech-Claude-Code](https://github.com/HermeticOrmus/LibreFinTech-Claude-Code) — financial technology development

Star the family, not just one — that's how the Libre-X-Claude-Code suite stays coherent.

---

## License

MIT © 2026 [Diego Bodart](https://github.com/HermeticOrmus) — see [LICENSE](LICENSE).

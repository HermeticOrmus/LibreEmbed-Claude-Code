<p align="center">
  <h1 align="center">LibreEmbed-Claude-Code</h1>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/plugins-15-2aa198?style=flat-square" alt="Plugins">
  <img src="https://img.shields.io/badge/license-MIT-2aa198?style=flat-square" alt="License">
  <img src="https://img.shields.io/badge/domain-embedded%20systems-2aa198?style=flat-square" alt="Domain">
  <img src="https://img.shields.io/badge/claude-code%20plugins-2aa198?style=flat-square" alt="Claude Code">
</p>

<p align="center">
  A curated collection of Claude Code plugins for embedded systems, firmware, and IoT development.<br>
  From bare metal to RTOS, ARM Cortex-M to FPGA, sensors to safety-critical systems.
</p>

---

## Plugin Collection

| # | Plugin | Domain | Command | Description |
|---|--------|--------|---------|-------------|
| 1 | [arm-cortex-m](plugins/arm-cortex-m/) | MCU | `/cortex-m` | ARM Cortex-M programming, CMSIS, HAL, startup code |
| 2 | [bare-metal](plugins/bare-metal/) | Core | `/bare-metal` | Register manipulation, linker scripts, minimal runtime |
| 3 | [bootloader-design](plugins/bootloader-design/) | Firmware | `/bootloader` | Bootloader architecture, secure boot, firmware updates |
| 4 | [communication-buses](plugins/communication-buses/) | Peripherals | `/comm-bus` | I2C, SPI, UART, CAN, USB protocols and drivers |
| 5 | [debug-trace](plugins/debug-trace/) | Tooling | `/debug-embedded` | JTAG, SWD, printf debugging, trace analysis |
| 6 | [embedded-linux](plugins/embedded-linux/) | Linux | `/embedded-linux` | Yocto, Buildroot, device trees, kernel modules |
| 7 | [embedded-testing](plugins/embedded-testing/) | Quality | `/embedded-test` | Unit testing on target, HIL testing, hardware mocks |
| 8 | [firmware-update](plugins/firmware-update/) | OTA | `/firmware-update` | OTA updates, versioning, rollback mechanisms |
| 9 | [fpga-integration](plugins/fpga-integration/) | FPGA | `/fpga` | FPGA/MCU integration, HDL basics, soft cores |
| 10 | [iot-protocols](plugins/iot-protocols/) | IoT | `/iot` | MQTT, CoAP, LwM2M, BLE, LoRaWAN, Zigbee |
| 11 | [memory-management](plugins/memory-management/) | Memory | `/memory` | Static allocation, memory pools, stack/heap analysis |
| 12 | [power-management](plugins/power-management/) | Power | `/power` | Sleep modes, power budgeting, energy harvesting |
| 13 | [rtos-patterns](plugins/rtos-patterns/) | RTOS | `/rtos` | FreeRTOS, Zephyr, task design, synchronization |
| 14 | [safety-critical](plugins/safety-critical/) | Safety | `/safety` | IEC 61508, DO-178C, MISRA C, certification |
| 15 | [sensor-integration](plugins/sensor-integration/) | Sensors | `/sensor` | Sensor drivers, calibration, filtering, fusion |

## Quick Start

### 1. Clone the repository

```bash
git clone https://github.com/HermeticOrmus/LibreEmbed-Claude-Code.git
```

### 2. Copy a plugin into your project

```bash
# Copy the RTOS patterns plugin
cp -r LibreEmbed-Claude-Code/plugins/rtos-patterns/.claude/ your-project/.claude/

# Or copy specific components
cp LibreEmbed-Claude-Code/plugins/rtos-patterns/agents/rtos-engineer/AGENT.md \
   your-project/.claude/agents/rtos-engineer/AGENT.md
```

### 3. Use the embedded project template

```bash
cp LibreEmbed-Claude-Code/templates/CLAUDE.md your-project/CLAUDE.md
```

### 4. Install hooks (optional)

```bash
cp LibreEmbed-Claude-Code/hooks/*.sh your-project/.claude/hooks/
chmod 755 your-project/.claude/hooks/*.sh
```

## Architecture

```
LibreEmbed-Claude-Code/
├── plugins/
│   └── {plugin-name}/
│       ├── README.md              # Plugin overview and usage
│       ├── agents/
│       │   └── {agent-name}/
│       │       └── AGENT.md       # Agent identity, expertise, behavior
│       ├── commands/
│       │   └── {command-name}/
│       │       └── COMMAND.md     # Slash command definition
│       └── skills/
│           └── {skill-name}/
│               └── SKILL.md       # Knowledge base and patterns
├── hooks/
│   ├── session-start.sh           # MCU/toolchain detection
│   ├── pre-tool-use.sh            # Memory and peripheral checks
│   └── post-tool-use.sh           # Binary size and analysis
├── learning-paths/
│   ├── beginner.md                # GPIO, UART, first blinky
│   ├── intermediate.md            # RTOS, interrupts, DMA
│   └── advanced.md                # Safety-critical, FPGA, bootloaders
├── templates/
│   └── CLAUDE.md                  # Embedded project template
├── CONTRIBUTING.md
├── CODE_OF_CONDUCT.md
├── CHANGELOG.md
└── LICENSE
```

## Learning Paths

| Level | Path | Topics |
|-------|------|--------|
| Beginner | [beginner.md](learning-paths/beginner.md) | Embedded fundamentals, GPIO, UART, toolchains, first blinky |
| Intermediate | [intermediate.md](learning-paths/intermediate.md) | RTOS concepts, interrupt handling, DMA, communication protocols |
| Advanced | [advanced.md](learning-paths/advanced.md) | Safety-critical systems, FPGA, custom bootloaders, power optimization |

## Design Principles

- **Hardware-aware**: Every plugin understands resource constraints (flash, RAM, real-time deadlines)
- **Safety-conscious**: Patterns enforce defensive coding, MISRA compliance, and fault tolerance
- **Vendor-neutral**: Supports ARM, RISC-V, AVR, and vendor-specific HALs without lock-in
- **Test-driven**: Hardware-in-the-loop and simulation testing built into workflows
- **Teach-first**: Explains the WHY behind patterns, not just the WHAT

## Target Platforms

- **MCU families**: ARM Cortex-M (M0/M0+/M3/M4/M7/M33), RISC-V, AVR, MSP430
- **Development boards**: STM32 Nucleo/Discovery, nRF52/nRF53, ESP32, Raspberry Pi Pico, Arduino
- **RTOS**: FreeRTOS, Zephyr, ThreadX, RTEMS, NuttX
- **Build systems**: CMake, Make, PlatformIO, Zephyr west, Yocto/Buildroot
- **Toolchains**: arm-none-eabi-gcc, LLVM/Clang, IAR, Keil

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on adding new plugins or improving existing ones.

## License

[MIT](LICENSE) - Copyright (c) 2025-2026 Hermetic Ormus

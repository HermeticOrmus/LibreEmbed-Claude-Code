<p align="center">
  <img src="https://ormus.solutions/mascot/pixellab_liquid_to_cube.gif" alt="LibreEmbed Claude Code" width="128" style="image-rendering: pixelated;" />
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

English | [简体中文](README.zh-CN.md)

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
| **Plugins** | 15 domain plugins (RTOS, ARM Cortex-M, comm buses, IoT, FPGA, safety-critical, more), installed from one marketplace named `libre-embed` |
| **Agents** | Domain-specialist agents for each plugin — e.g., RTOS engineer, ARM Cortex-M expert, IoT protocol designer |
| **Commands** | Quick-access slash commands per plugin (`/rtos`, `/comm-bus`, `/iot`, `/cortex-m`, etc.) |
| **Skills** | Reusable pattern libraries — calibration routines, sensor fusion, bootloader patterns, OTA workflows |
| **Hooks** | Pre/post tool hooks for safety nets, packaged as the optional `libre-embed-hooks` plugin: asks before flash, erase, and secret-file operations |
| **Templates** | A project `CLAUDE.md` scaffold (`templates/CLAUDE.md`) |

---

## What's included

```
LibreEmbed-Claude-Code/
├── .claude-plugin/         # marketplace.json for the libre-embed marketplace
├── plugins/                # 15 plugins, one per embedded subdomain, plus libre-embed-hooks
│   ├── arm-cortex-m        # ARM Cortex-M0/M3/M4/M7/M33 programming
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
│   ├── sensor-integration  # Driver bring-up, calibration, filtering, fusion
│   └── libre-embed-hooks   # Optional safety hooks: confirm flash, erase, and secret-file operations
├── learning-paths/         # 3 learning paths: beginner → intermediate → advanced
├── templates/              # Project CLAUDE.md scaffold
└── setup.sh                # Installs the plugins through the Claude Code CLI
```

---

## The 15 plugins

Each plugin ships an **agent** (specialist persona with deep domain knowledge), a **command** (quick slash invocation), and a **skill** (reusable pattern library).

### Microcontroller core

| Plugin | Agent / Command | What it does |
|---|---|---|
| **arm-cortex-m** | `cortex-m-engineer` / `/cortex-m` | CMSIS, HAL vs. LL, startup code, vector table, MPU configuration, MMU on Cortex-A boundaries. ARM Cortex-M0+/M3/M4/M7/M33. |
| **bare-metal** | `bare-metal-engineer` / `/bare-metal` | Register-level programming, linker scripts, minimal runtime (no libc), C++ on embedded, freestanding builds. |
| **memory-management** | `memory-engineer` / `/memory` | Static allocation strategies, memory pools, stack analysis via GCC `-fstack-usage`, heap-less design, fragmentation patterns. |
| **power-management** | `power-engineer` / `/power` | Sleep modes (run / sleep / stop / standby), peripheral clock gating, wake sources, power budgeting, energy harvesting designs. |

### Communication + I/O

| Plugin | Agent / Command | What it does |
|---|---|---|
| **communication-buses** | `bus-driver-engineer` / `/comm-bus` | I2C (master/slave, clock stretching, multi-master), SPI (modes, DMA, CS handling), UART (DMA, ring buffers, flow control), CAN (frame format, filters, error states), USB CDC/HID. |
| **sensor-integration** | `sensor-engineer` / `/sensor` | Sensor driver bring-up, factory calibration, Allan variance, complementary + Kalman filtering, sensor fusion (IMU + magnetometer + GPS). |
| **iot-protocols** | `iot-protocol-engineer` / `/iot` | MQTT (QoS levels, retained messages, LWT), CoAP, LwM2M device management, BLE GATT, LoRaWAN class A/B/C, Zigbee, Thread. |

### Runtime + system

| Plugin | Agent / Command | What it does |
|---|---|---|
| **rtos-patterns** | `rtos-engineer` / `/rtos` | FreeRTOS + Zephyr task design, IPC primitives (queues, mutexes, semaphores, event groups), priority inversion + inheritance, watchdog patterns, deferred interrupt processing. |
| **embedded-linux** | `embedded-linux-engineer` / `/embedded-linux` | Yocto + Buildroot, device tree authoring, kernel module patterns, init systems (systemd vs. OpenRC vs. BusyBox init), userspace driver patterns. |
| **bootloader-design** | `bootloader-engineer` / `/bootloader` | First-stage vs. second-stage bootloaders, secure boot chains, signature verification, A/B partition designs, fail-safe rollback, ROM bootloader interaction. |
| **firmware-update** | `fota-engineer` / `/firmware-update` | OTA update protocols, dual-bank flash, delta updates (bsdiff/Heatshrink), version negotiation, anti-rollback, signed-by-vendor enforcement. |

### Hardware-software integration

| Plugin | Agent / Command | What it does |
|---|---|---|
| **fpga-integration** | `fpga-engineer` / `/fpga` | MCU + FPGA designs, AXI bus integration, soft-core CPUs (RISC-V on FPGA), DMA across the boundary, HDL basics for the embedded developer. |
| **debug-trace** | `debug-engineer` / `/debug-embedded` | JTAG + SWD setup, OpenOCD + pyOCD, ITM (Instrumentation Trace Macrocell), ETM (Embedded Trace Macrocell), printf-over-SWO, logic analyzer captures, oscilloscope vs. logic analyzer trade-offs. |

### Quality + compliance

| Plugin | Agent / Command | What it does |
|---|---|---|
| **embedded-testing** | `embedded-test-engineer` / `/embedded-test` | On-target unit tests (Unity, CMocka, Ceedling), Hardware-in-the-Loop (HIL) test rigs, hardware peripheral mocks, golden-image regression, CI for embedded. |
| **safety-critical** | `safety-engineer` / `/safety` | IEC 61508 SIL levels, DO-178C aviation, ISO 26262 automotive, MISRA C compliance, formal verification basics, freedom-from-interference. |

### Optional safety hooks

| Plugin | Hooks | What it does |
|---|---|---|
| **libre-embed-hooks** | SessionStart, PreToolUse, PostToolUse | Asks before flash and erase commands (OpenOCD `program`, `st-flash write`, `west flash`, `idf.py flash`, `pyocd flash`, `nrfjprog --program`, and more) and before a file tool touches `.env`, `.pem`, `.key`, credentials, or secrets files. Prints one context line when a session opens in a firmware project, and flags a file left empty by an edit. No agents, no logs. See [its README](plugins/libre-embed-hooks/README.md). |

---

## Quick start

### Install from Claude Code

```text
/plugin marketplace add HermeticOrmus/LibreEmbed-Claude-Code
/plugin install rtos-patterns@libre-embed
```

Install any of the 15 plugins the same way, `/plugin install <plugin>@libre-embed` with a name from the tables above, then restart Claude Code. From a terminal the same two steps are:

```bash
claude plugin marketplace add HermeticOrmus/LibreEmbed-Claude-Code
claude plugin install rtos-patterns@libre-embed
```

The safety hooks are a separate, optional plugin: `/plugin install libre-embed-hooks@libre-embed` (or `claude plugin install libre-embed-hooks@libre-embed`).

### Install everything with setup.sh

```bash
# Clone
git clone https://github.com/HermeticOrmus/LibreEmbed-Claude-Code.git ~/projects/LibreEmbed-Claude-Code

# Install all 15 plugins plus libre-embed-hooks into Claude Code
cd ~/projects/LibreEmbed-Claude-Code
./setup.sh

# Or install just the plugins you need
./setup.sh --only rtos-patterns,communication-buses,iot-protocols

# List the plugins, skip the hooks plugin, or remove the pack
./setup.sh --list
./setup.sh --no-safety-hooks
./setup.sh --uninstall
```

`setup.sh` needs the `claude` CLI and `jq`. It registers the checkout as the `libre-embed` marketplace and runs `claude plugin install` for each plugin, so it installs exactly what the `/plugin` commands install. All fifteen together add about 4.7k tokens of plugin descriptions to every session (`claude plugin details <plugin>@libre-embed` shows each one), so `--only` pays off if you work in a few areas.

Upgrading from 0.x: the old `setup.sh` copied directories into `~/.claude/plugins/` and scripts into `~/.claude/hooks/`, locations Claude Code does not load. Install with either method above, then delete any leftover `~/.claude/plugins/libre-embed-*` directories and `~/.claude/hooks/libre-embed-*.sh` scripts.

### First prompt

Then in any Claude Code session at your firmware project root:

```text
/rtos design a task structure for a sensor logger that samples 4 channels at 1 kHz and writes to QSPI flash every 100 ms
```

If another plugin also defines `/rtos`, use the namespaced form `/rtos-patterns:rtos`.

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

- **Claude Code**: a release with plugin marketplaces (`/plugin`); this release was verified with Claude Code 2.1.285. `setup.sh` and the hooks plugin also need `jq`.
- **Toolchains**: GCC ARM (any recent version), Clang/LLVM with embedded targets, Zephyr SDK, ESP-IDF, STM32CubeIDE, Microchip XC32, Renesas e² studio
- **MCU families covered**: ARM Cortex-M0/M0+/M3/M4/M7/M33 (STM32, NXP LPC + Kinetis + i.MX RT, Nordic nRF, Microchip SAM, RP2040, ESP32, Renesas RA), MSP430 (light), AVR (light)
- **RTOS coverage**: FreeRTOS (deep), Zephyr (deep), ThreadX (moderate), RT-Thread (light)
- **Build systems**: Make, CMake, PlatformIO, Zephyr west, ESP-IDF idf.py
- **Debuggers**: SEGGER J-Link (preferred), ST-Link, CMSIS-DAP, Black Magic Probe, JLink-OB
- **OS**: Linux / macOS for development host (Windows tolerated, WSL2 recommended)

LibreEmbed makes no calls home and does not require any vendor account beyond what your toolchain itself needs.

---

## Feedback

Starred this? Tell us what worked and what is missing: [open a feedback issue](https://github.com/HermeticOrmus/LibreEmbed-Claude-Code/issues/new?template=feedback.yml). Every piece of feedback gets an answer, and changes that come from it are credited in the release notes.

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

This repository is part of a growing family of open-source toolkits for Claude Code.

### Libre suite — comprehensive plugin bundles

- [LibreUIUX-Claude-Code](https://github.com/HermeticOrmus/LibreUIUX-Claude-Code) — UI/UX development (152 agents, 70 plugins, 76 commands, 74 skills)
- [LibreArch-Claude-Code](https://github.com/HermeticOrmus/LibreArch-Claude-Code) — Software architecture and system design
- [LibreCopy-Claude-Code](https://github.com/HermeticOrmus/LibreCopy-Claude-Code) — Technical writing and documentation engineering
- [LibreDevOps-Claude-Code](https://github.com/HermeticOrmus/LibreDevOps-Claude-Code) — DevOps engineering and infrastructure automation
- [LibreFinTech-Claude-Code](https://github.com/HermeticOrmus/LibreFinTech-Claude-Code) — Financial technology development
- [LibreGEO-Claude-Code](https://github.com/HermeticOrmus/LibreGEO-Claude-Code) — AI-search optimization (ChatGPT, Perplexity, Gemini, Google AI Overviews)
- [LibreGameDev-Claude-Code](https://github.com/HermeticOrmus/LibreGameDev-Claude-Code) — Game development across Godot, Unity, Unreal
- [LibreMLOps-Claude-Code](https://github.com/HermeticOrmus/LibreMLOps-Claude-Code) — ML engineering and AI operations
- [LibreMobileDev-Claude-Code](https://github.com/HermeticOrmus/LibreMobileDev-Claude-Code) — Mobile app development (Flutter, React Native, native iOS, native Android)
- [LibreSecOps-Claude-Code](https://github.com/HermeticOrmus/LibreSecOps-Claude-Code) — Security operations
- [LibreSessionFlow-Claude-Code](https://github.com/HermeticOrmus/LibreSessionFlow-Claude-Code) — Session lifecycle: handoff, pickup, absorb, explore, close

### Skills mini-repos — single CLAUDE.md drop-ins

- [vibe-engineer-skills](https://github.com/HermeticOrmus/vibe-engineer-skills) — Direct AI codegen well: hypothesis before help, scoped prompts, validate before accepting
- [markdown-discipline-skills](https://github.com/HermeticOrmus/markdown-discipline-skills) — Strip AI-slop from markdown (no em dashes, no marketing fluff)
- [shell-safety-skills](https://github.com/HermeticOrmus/shell-safety-skills) — `set -euo pipefail` discipline plus 15 failure-mode examples
- [commit-standard-skills](https://github.com/HermeticOrmus/commit-standard-skills) — Ormus Commit Standard v1.0 plus commit-msg hook and commitlint
- [unwoke-skills](https://github.com/HermeticOrmus/unwoke-skills) — Strip AI theater (ten sins to eliminate, symmetric engagement)
- [python-conventions-skills](https://github.com/HermeticOrmus/python-conventions-skills) — Modern Python 3.11+ (types, pathlib, async, ruff, mypy, uv)
- [typescript-conventions-skills](https://github.com/HermeticOrmus/typescript-conventions-skills) — TypeScript strict mode, discriminated unions, Result types
- [hermetic-laws-skills](https://github.com/HermeticOrmus/hermetic-laws-skills) — Seven Hermetic Principles applied to engineering
- [riper-workflow-skills](https://github.com/HermeticOrmus/riper-workflow-skills) — Research / Innovate / Plan / Execute / Review systematic dev
- [six-day-cycle-skills](https://github.com/HermeticOrmus/six-day-cycle-skills) — Sustainable shipping cadence with mandatory rest
- [token-optimization-skills](https://github.com/HermeticOrmus/token-optimization-skills) — Claude Code token and context optimization
- [osint-skills](https://github.com/HermeticOrmus/osint-skills) — OSINT research methodology (multi-wave investigative spiral)
- [calcinate-skills](https://github.com/HermeticOrmus/calcinate-skills) — Stage 1 of the Magnum Opus (burn project bloat)
- [claude-md-overhaul-skills](https://github.com/HermeticOrmus/claude-md-overhaul-skills) — Audit CLAUDE.md and MEMORY.md against caps
- [session-handoff-skills](https://github.com/HermeticOrmus/session-handoff-skills) — Session handoff and pickup discipline
- [naming-skills](https://github.com/HermeticOrmus/naming-skills) — Product naming methodology (mine the brand's vocabulary)
- [magnum-opus-skills](https://github.com/HermeticOrmus/magnum-opus-skills) — Seven-stage alchemy applied to project transformation
- [mem-search-skills](https://github.com/HermeticOrmus/mem-search-skills) — Search claude-mem cross-session memory: search, filter, fetch
- [hypothesis-debugging-skills](https://github.com/HermeticOrmus/hypothesis-debugging-skills) — Hypothesis-driven debugging: reproduce, isolate, test, fix
- [vibe-proof-skills](https://github.com/HermeticOrmus/vibe-proof-skills) — Security hardening for vibe-coded full-stack apps
- [tdd-skills](https://github.com/HermeticOrmus/tdd-skills) — Test-driven development (Red-Green-Refactor) for JS/TS and Python
- [mars-skills](https://github.com/HermeticOrmus/mars-skills) — Production-readiness audit: the five mortal sins of vibe-coded MVPs
- [git-workflow-skills](https://github.com/HermeticOrmus/git-workflow-skills) — Clean git workflow: branch, atomic commits, reviewable PRs
- [code-review-skills](https://github.com/HermeticOrmus/code-review-skills) — Domain-aware code review: classify the code, then focus
- [code-comprehension-skills](https://github.com/HermeticOrmus/code-comprehension-skills) — Understand an unfamiliar codebase fast
- [dx-audit-skills](https://github.com/HermeticOrmus/dx-audit-skills) — Audit developer experience: docs, onboarding, tooling friction
- [setup-env-skills](https://github.com/HermeticOrmus/setup-env-skills) — Set up a project's development environment
- [automate-skills](https://github.com/HermeticOrmus/automate-skills) — Turn repetitive tasks into reliable automation scripts
- [quick-fix-skills](https://github.com/HermeticOrmus/quick-fix-skills) — Fast troubleshooting for common issues
- [prime-context-skills](https://github.com/HermeticOrmus/prime-context-skills) — Prime project context at the start of a session
- [auto-docs-skills](https://github.com/HermeticOrmus/auto-docs-skills) — Generate and maintain project documentation
- [learning-skills](https://github.com/HermeticOrmus/learning-skills) — Learn any technology: roadmaps, explanations, practice, cheatsheets, comparisons
- [linux-sysadmin-skills](https://github.com/HermeticOrmus/linux-sysadmin-skills) — Linux system administration: security, performance, diagnostics, monitoring, maintenance

### Template source

- [andrej-karpathy-skills](https://github.com/HermeticOrmus/andrej-karpathy-skills) — the canonical single-file CLAUDE.md pattern (fork of jiayuan_jy's original)

Star the family, not just one — that's how the suite stays coherent.

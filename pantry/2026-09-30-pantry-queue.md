# Pantry queue: LibreEmbed-Claude-Code

First stock, 2026-09-30, from the [competitor map](2026-09-30-competitor-map.md), [X mine](2026-09-30-x-mine.md) and [people mine](2026-09-30-people-mine.md) of the same date, plus the repo audit notes below. Every atom is buildable by an outside contributor and checkable on this repo.

## Atoms

| # | Title | Done predicate | Surface | Evidence | Confidence |
|---|-------|----------------|---------|----------|------------|
| 1 | Correct the ESP32 architecture in the README (`esp32-architecture`) | In README.md and README.zh-CN.md the "MCU families covered" line no longer lists ESP32 inside the ARM Cortex-M parentheses, and names ESP32 as Xtensa (ESP32, ESP32-S2, ESP32-S3) and RISC-V (ESP32-C and ESP32-H series) parts. | repo | Map matrix: Espressif ESP32 (Xtensa and RISC-V) as a first-class target (Us P; Espressif SoC page); audit A1 | high |
| 2 | Replace the templated usage examples in 12 plugin READMEs (`plugin-readme-usage`) | `grep -l 'generate --context' plugins/*/README.md` prints nothing, and every `/<command> <action>` example in those 12 READMEs uses an action named in that plugin's `commands/*.md` `argument-hint`. | repo | Audit A2; map Product surfaces | high |
| 3 | Translate QUICK_START into Simplified Chinese (`quick-start-zh-cn`) | `QUICK_START.zh-CN.md` exists with every `##` section of QUICK_START.md translated, README.zh-CN.md links to it, and QUICK_START.md links to it in its first lines. | repo | People mine: Audience context (8 of 10 stargazers with a location are in China); map matrix: Docs in Simplified Chinese (Us P); audit A3 | medium |
| 4 | Translate the beginner learning path into Simplified Chinese (`beginner-path-zh-cn`) | `learning-paths/beginner.zh-CN.md` exists with every `##` section of `learning-paths/beginner.md` translated, and the learning paths section of README.zh-CN.md links to it. | repo | People mine: Audience context; map matrix: Docs in Simplified Chinese (Us P); audit A3 | medium |
| 5 | Add a Zephyr devicetree and Kconfig skill (`zephyr-devicetree`) | `claude plugin validate plugins/rtos-patterns` passes, `claude plugin details rtos-patterns@libre-embed` lists skill `zephyr-devicetree`, and its SKILL.md has a board overlay that enables an I2C sensor node plus the matching `prj.conf` lines. | repo | Map matrix: Zephyr devicetree overlays and Kconfig (Us P, zephyr-agent-skills Y) | medium |
| 6 | Add a hardware loop skill for build, flash and log capture (`hardware-loop`) | `claude plugin validate plugins/debug-trace` passes, `claude plugin details debug-trace@libre-embed` lists skill `hardware-loop`, and its SKILL.md gives the `claude mcp add` line for an open-source build and flash MCP server (ESP-IDF `idf.py mcp-server` or a probe-rs server), a build, flash and read-logs loop with a timeout for a hung flash, and how it meets the `libre-embed-hooks` flash confirmation. | repo | Map matrix: Tool access to build, flash and read target state (Us N; ESP-IDF MCP, embedded-debugger-mcp, Embedder Y); X complaints: flashing hangs, cannot self verify; X praise: USB-plug | medium |
| 7 | Back the RISC-V soft-core claim in fpga-integration (`fpga-riscv-softcore`) | The fpga-integration agent or skill has a RISC-V soft-core section (for example PicoRV32 or VexRiscv) with a memory map and an MCU-side register access example, and `claude plugin validate plugins/fpga-integration` passes. | repo | Audit A4 | medium |
| 8 | Add an embedded Rust plugin (`embedded-rust`) | `plugins/embedded-rust/` has `.claude-plugin/plugin.json`, an agent, a command and a skill with routing descriptions and a `.claude-plugin/marketplace.json` entry; `claude plugin validate plugins/embedded-rust` passes; `claude plugin details embedded-rust@libre-embed` lists its agent and skill; the skill covers a `no_std` Cortex-M target with `cortex-m-rt`, flashing and logging with probe-rs and defmt, and one embassy task. | repo | Map matrix: Embedded Rust (Us N; wshobson P; Embedder Y) | low |

## Audit notes (repo as on `main`, 2026-09-30)

- A1: README.md line 219 and README.zh-CN.md line 219 list ESP32 among "ARM Cortex-M0/M0+/M3/M4/M7/M33" families. Espressif lists ESP32 and ESP32-S3 as Xtensa and ESP32-C3 as RISC-V (https://www.espressif.com/en/products/socs).
- A2: 12 plugin READMEs (arm-cortex-m, bare-metal, bootloader-design, debug-trace, embedded-linux, embedded-testing, firmware-update, fpga-integration, memory-management, power-management, safety-critical, sensor-integration) carry the same template: `/<command> analyze` and `/<command> generate --context "your project"`. The commands take other actions, for example `/cortex-m` takes `init|configure|debug|benchmark` and `/fpga` takes `design|synthesize|program|interface`. `generate` is not an action of any command.
- A3: QUICK_START.md, TROUBLESHOOTING.md and `learning-paths/*.md` exist only in English; CONTRIBUTING.md asks for translations of the learning paths and lists Chinese first.
- A4: README.md lists "soft-core CPUs (RISC-V on FPGA)" for fpga-integration, but no file under `plugins/fpga-integration/` mentions RISC-V; the agent names MicroBlaze and NIOS II in a table.

## Explicitly not stocked (and why)

- Bundling an MCP server binary inside a plugin: not stocked. The pack ships prompts and shell hooks only; atom 6 documents open-source servers instead.
- Eval suites for `claude plugin eval`: not stocked this run. Running them spends model credits on the contributor's account; revisit when a free check is available.
- Indexed datasheets or SVD files, as Embedder does: not stocked. It needs a hosted index or vendor files this repo cannot redistribute.
- Codex and Cursor manifests: not stocked this run. Only competitor rows point there; no user has asked.

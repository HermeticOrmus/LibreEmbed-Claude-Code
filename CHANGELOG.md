# Changelog

All notable changes to LibreEmbed-Claude-Code.

## [Unreleased]

### Added

- A public pantry in `pantry/`: a competitor map, an X mine, a people mine and a pantry queue, every row cited. `pantry/MENU.md`, generated from the queue, names the next piece of work anyone can take.
- Two issue forms: routing miss (Claude picked the wrong agent or skill, or none) and plugin proposal.
- A Ways to contribute section in CONTRIBUTING.md, with the local test loop, and a Contribute section in README.md and README.zh-CN.md.
- Grok Build support: `.grok-plugin/marketplace.json`, generated from the Claude manifest by `scripts/sync-grok-manifest.py`, so `grok plugin marketplace add HermeticOrmus/LibreEmbed-Claude-Code` then `grok plugin install <plugin>@libre-embed` works, as does `grok plugin install HermeticOrmus/LibreEmbed-Claude-Code#plugins/<plugin>`. CI checks the generated file, runs `grok plugin validate` on every plugin, and installs all 16 into a clean Grok home. README, README.zh-CN.md and QUICK_START show the Grok Build install; `libre-embed-hooks` is not yet verified in a live Grok session.
- `./setup.sh --grok` installs through the `grok` CLI instead of `claude`, with the same `--only`, `--list`, `--uninstall`, and `--no-safety-hooks` behavior.
- `LEDGER.md`, the kintsugi ledger: every crack the 1.0.0 release found and sealed, with its evidence, and the cracks still open.

## [1.0.0] - 2026-09-30

First installable release. Before it, Claude Code could not load this pack: the plugins had no manifests, most agents and commands sat in nested folders Claude Code does not read, and `setup.sh` copied everything to a directory Claude Code ignores. 1.0.0 makes all fifteen plugins installable without dropping any content, and adds an optional hooks plugin.

### Added

- The `libre-embed` plugin marketplace (`.claude-plugin/marketplace.json`) and a `plugin.json` for every plugin. Install with `/plugin marketplace add HermeticOrmus/LibreEmbed-Claude-Code`, then `/plugin install <plugin>@libre-embed`.
- `libre-embed-hooks`, an optional plugin. It asks before flash and erase commands (OpenOCD, st-flash, STM32CubeProgrammer CLI, pyOCD, nrfjprog, esptool, idf.py, west, dfu-util, avrdude, picotool, PlatformIO, J-Link Commander scripts, `make flash`) and before a file tool touches `.env`, `.pem`, `.key`, credentials, or secrets files; adds one context line when a session opens in a firmware project; and flags a file left empty by an edit. It writes no logs.
- Code reference material in the `rtos-patterns`, `communication-buses`, and `iot-protocols` agents, commands, and skills, merged from older copies Claude Code could not see: FreeRTOS task, queue, mutex, event group, and notification code; STM32 HAL and LL examples for I2C, SPI, UART, CAN, and USB; ESP-IDF MQTT, Zephyr BLE GATT, LMIC LoRaWAN OTAA, libcoap, and Paho C clients; `FreeRTOSConfig.h` settings, a stack overflow hook, and rate monotonic analysis; and action shortcuts such as `/rtos design` and `/comm-bus configure`.
- A LoRa airtime and duty cycle calculator in the `iot-protocols` skill, built on the Semtech time-on-air formula.
- `README.zh-CN.md`, a Simplified Chinese translation of the README.
- CI that validates the marketplace and every plugin, then installs all of them into a clean config, on each pull request.
- A feedback issue form.

### Changed

- `setup.sh` installs through the Claude Code CLI (`claude plugin marketplace add`, `claude plugin install`) and supports `--list`, `--only`, `--scope`, `--uninstall`, and `--no-safety-hooks`. It needs `claude` and `jq`. `--plugins-dir` is still accepted but no longer used.
- Agents, commands, and skills live where Claude Code loads them: `agents/<name>.md`, `commands/<name>.md`, `skills/<name>/SKILL.md`.
- Every agent, command, and skill description is rewritten as routing text, so Claude Code can tell when to use each one. Commands show an argument hint.
- `rtos-engineer`, `bus-driver-engineer`, and `iot-protocol-engineer` now use `model: inherit` instead of `sonnet`, like the other twelve agents, so they run on the model of your session.
- The hook scripts moved from `hooks/` to `plugins/libre-embed-hooks/hooks/` and now read Claude Code's JSON hook input on stdin.
- If you ran the 0.x `setup.sh`: delete the leftover `~/.claude/plugins/libre-embed-*` directories and `~/.claude/hooks/libre-embed-*.sh` scripts after installing 1.0.0. Claude Code never loaded them.

### Fixed

- CAN at 500 kbit/s from a 42 MHz clock: prescaler 6 with 1 + 11 + 2 time quanta. The old prescaler 5 with 15 quanta gave 560 kbit/s.
- UART BRR for 115200 baud at 42 MHz is 0x16D (115,068 baud actual).
- In the UART DMA pattern, `HAL_UARTEx_RxEventCallback` receives a buffer position, not a count since the last call.
- LoRa airtime: the calculator, the air time table, and the SF9 and SF12 figures follow the Semtech formula, and the duty cycle arithmetic is corrected.
- The `/iot` battery budget arithmetic, which undercounted TX and sleep charge.
- The `/rtos` port notes said Zephyr semaphores inherit priority. They do not; mutexes do, in both RTOSes.
- The `/rtos` sensor task now waits for its SPI DMA to finish before queueing a sample, the logger writes only the samples it received, and the Zephyr port defines its semaphore once.
- The Paho C `messageArrived` callback returns `int`, the Python Paho example passes `CallbackAPIVersion.VERSION2` for paho-mqtt 2.x, MCP3204 accepts SPI mode 0 or 3, the ESP-IDF certificate comment names `EMBED_TXTFILES`, and the FreeRTOS state diagram shows `vTaskDelay` blocking rather than suspending.
- QUICK_START promised a pre-flash warning hook that never ran. The `libre-embed-hooks` plugin now provides it.

## [0.2.0] — 2026-05-23

Major content depth pass. The 15 plugin shells from v0.1 are being filled with real embedded systems content matching the LibreUIUX-Claude-Code substance bar.

### Added
- README rewrite matching the LibreUIUX template (mascot, brass badges, Karpathy framing, "where this fits" table, full plugin catalog with descriptions)
- Real `QUICK_START.md` walkthrough with concrete first-board project (LSM6DSO IMU + STM32F4)
- Real `CONTRIBUTING.md` with plugin-authoring conventions and substance bar
- Real `TROUBLESHOOTING.md` covering common embedded debug scenarios
- `setup.sh` installer copying plugins into `~/.claude/plugins/`
- "Part of the Libre Open-Source Stack" cross-link block referencing LibreUIUX, LibreGEO, LibreGameDev, LibreFinTech
- 3 flagship plugins promoted to depth-complete (see maturity matrix below):
  - `rtos-patterns` — FreeRTOS + Zephyr task design, IPC primitives, priority inversion patterns, watchdog idioms
  - `communication-buses` — I2C clock stretching, SPI DMA, UART ring buffers, CAN frame format, USB CDC
  - `iot-protocols` — MQTT QoS + LWT, CoAP, BLE GATT, LoRaWAN class A/B/C
- Substantively rewritten learning paths (beginner / intermediate / advanced) with real walkthroughs

### Per-plugin maturity matrix

| Plugin | v0.1 state | v0.2 state |
|---|---|---|
| arm-cortex-m | templated | shell-improved |
| bare-metal | templated | shell-improved |
| bootloader-design | templated | shell-improved |
| **communication-buses** | templated | **depth-complete** |
| debug-trace | templated | shell-improved |
| embedded-linux | templated | shell-improved |
| embedded-testing | templated | shell-improved |
| firmware-update | templated | shell-improved |
| fpga-integration | templated | shell-improved |
| **iot-protocols** | templated | **depth-complete** |
| memory-management | templated | shell-improved |
| power-management | templated | shell-improved |
| **rtos-patterns** | templated | **depth-complete** |
| safety-critical | templated | shell-improved |
| sensor-integration | templated | shell-improved |

"shell-improved" = README + plugin metadata corrected, but agent + command content not yet rewritten to depth-complete bar.
"depth-complete" = real expertise content in agent + command + skill, matches the LibreUIUX-Claude-Code substance bar.

### Planned for v0.3

- 4-5 more plugins promoted to depth-complete (next priorities: `debug-trace`, `bootloader-design`, `firmware-update`, `power-management`, `arm-cortex-m`)
- Real-board worked example for each depth-complete plugin (currently `rtos-patterns` and `communication-buses` reference STM32 + LSM6DSO; need ESP32, nRF52, RP2040 variants)
- HIL test rig recipe in `embedded-testing` plugin

### Planned for v0.4

- Remaining 10 plugins to depth-complete
- Per-vendor HAL sub-skills (ST HAL, Nordic nRFx, ESP-IDF) layered over CMSIS baseline
- Translation infrastructure for learning paths (zh-CN, es, pt-BR)

## [0.1.0] — 2026-03-01

Initial release. 15 plugin shells with templated content. Established the directory structure and naming conventions.

### Added
- 15 plugin directories (1 per embedded subdomain)
- Templated learning paths (beginner/intermediate/advanced)
- Templates folder with project CLAUDE.md scaffold
- Hooks folder with pre/post tool-use scaffolds
- Initial README with plugin catalog table
- MIT license

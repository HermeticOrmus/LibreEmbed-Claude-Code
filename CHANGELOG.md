# Changelog

All notable changes to LibreEmbed-Claude-Code.

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

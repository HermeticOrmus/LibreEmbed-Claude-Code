# Menu: LibreEmbed-Claude-Code

Queue: 2026-09-30-pantry-queue.md
Counts: open 8, in flight 0, shipped 0, parked 0, dropped 0, needs fixing 0

## Steer

- none

## Up next

**esp32-architecture**: Correct the ESP32 architecture in the README (`esp32-architecture`) (queue #1, high, repo, since 2026-09-30)

- Done when: In README.md and README.zh-CN.md the "MCU families covered" line no longer lists ESP32 inside the ARM Cortex-M parentheses, and names ESP32 as Xtensa (ESP32, ESP32-S2, ESP32-S3) and RISC-V (ESP32-C and ESP32-H series) parts; `grep -rn -i esp32 .` finds no file that calls ESP32 a Cortex-M part.
- Verify on: repo
- Evidence: Map matrix: Espressif ESP32 (Xtensa and RISC-V) as a first-class target (Us P; Espressif SoC page); audit A1; open good first issue #4
- Issue: none yet (promote after merge)
- Order: esp32-architecture, plugin-readme-usage, beginner-path-zh-cn, fpga-riscv-softcore, hardware-loop, quick-start-zh-cn, zephyr-devicetree, embedded-rust
- Tie: esp32-architecture over plugin-readme-usage, by key order (jev off)

## Atoms

| Key | Title | State | Confidence | Class | Since | Queue # | Issue | Because |
|-----|-------|-------|------------|-------|-------|---------|-------|---------|
| beginner-path-zh-cn | Translate the beginner learning path into Simplified Chinese (`beginner-path-zh-cn`) | open | medium | repo | 2026-09-30 | 4 | - | - |
| embedded-rust | Add an embedded Rust plugin (`embedded-rust`) | open | low | repo | 2026-09-30 | 8 | - | - |
| esp32-architecture | Correct the ESP32 architecture in the README (`esp32-architecture`) | open | high | repo | 2026-09-30 | 1 | - | - |
| fpga-riscv-softcore | Back the RISC-V soft-core claim in fpga-integration (`fpga-riscv-softcore`) | open | medium | repo | 2026-09-30 | 7 | - | - |
| hardware-loop | Add a hardware loop skill for build, flash and log capture (`hardware-loop`) | open | medium | repo | 2026-09-30 | 6 | - | - |
| plugin-readme-usage | Replace the templated usage examples in 12 plugin READMEs (`plugin-readme-usage`) | open | high | repo | 2026-09-30 | 2 | - | - |
| quick-start-zh-cn | Translate QUICK_START into Simplified Chinese (`quick-start-zh-cn`) | open | medium | repo | 2026-09-30 | 3 | - | - |
| zephyr-devicetree | Add a Zephyr devicetree and Kconfig skill (`zephyr-devicetree`) | open | medium | repo | 2026-09-30 | 5 | - | - |

## Retired

| Key | Title | State | Since | Issue | Because |
|-----|-------|-------|-------|-------|---------|
| none | | | | | |

## Notes

- none

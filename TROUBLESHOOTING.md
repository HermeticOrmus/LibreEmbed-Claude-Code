# Troubleshooting

Common scenarios when using LibreEmbed plugins, plus the general embedded debugging patterns you'll hit regardless of the bundle.

## Plugin issues

### Plugins copied but Claude Code doesn't see them

```bash
ls ~/.claude/plugins/ | grep '^libre-embed-'
```

If you see the directories: restart Claude Code. Plugin changes don't hot-reload.

If you don't see them: re-run `./setup.sh` and watch the output for `[skip]` lines. Older Claude Code installs may use `~/.config/claude/plugins/` instead — pass `--plugins-dir <path>`.

### `/rtos`, `/iot`, `/cortex-m`, etc. not recognized

The slash commands are registered when Claude Code reads the plugin's `commands/*.md` files at startup. If a command isn't recognized:

1. Verify the plugin's `commands/` directory has at least one `.md` file
2. Verify the filename matches the command name (the slash is the file basename minus `.md`)
3. Restart Claude Code

### Agent gives generic answers, not embedded-specific

This is the v0.1-state symptom — templated content. As of v0.2, three plugins are depth-complete (`rtos-patterns`, `communication-buses`, `iot-protocols`). The rest are still being deepened — see [CHANGELOG.md](CHANGELOG.md) maturity matrix.

If a depth-complete plugin still gives generic answers, file an issue with the exact prompt + response.

## Hardware debug scenarios the agents help with

The `/debug-embedded` agent is tuned for the following patterns. If you're hitting one of these, talk to it before reaching for the scope.

### "I'm reading 0xFF from every register on an I2C/SPI peripheral"

Pattern: the slave isn't driving MISO (SPI) or SDA (I2C). The bus is floating high (pull-ups + no driver).

Common root causes:
- Slave not powered (check VCC at the slave's pin, not at the regulator output)
- Slave reset asserted (check NRST or equivalent)
- Bus contention: another master is driving the bus (multi-master without arbitration)
- CS / address mismatch: you're addressing the wrong slave, or CS is never going low
- Slave is in a sleep mode the bus access doesn't wake

### "Code works in debug build, fails in release build"

Pattern: optimization exposed a latent bug.

Common root causes:
- Missing `volatile` on a hardware register access
- Missing memory barrier (`__DMB()`, `__DSB()`, `__ISB()` on ARM)
- DMA cache coherency (Cortex-M7 with cache + DMA — invalidate before read, clean before write)
- Stack overflow that debug build's larger stack happened to tolerate
- Uninitialized variable that debug build happened to zero

### "Code works in simulator/QEMU, fails on hardware"

Pattern: simulator doesn't model timing or hardware quirks the real chip has.

Common root causes:
- Flash wait states wrong for the actual clock speed
- DMA + Flash conflict (some MCUs can't run DMA from RAM while CPU fetches from Flash without arbitration delays)
- Crystal oscillator startup time longer than your delay assumes
- Power-on reset taking longer than the debugger's halt-at-reset

### "Chip won't enumerate over USB"

Pattern: USB device-side problems usually trace to power, clock, or pull-up.

Common root causes:
- USB clock not exactly 48 MHz (CDC tolerates ~0.25%, HID is stricter)
- D+ pull-up not enabled (or enabled too early before VBUS is stable)
- VBUS detect not wired (host won't request descriptors)
- Descriptors too long for the EP0 max packet size you configured
- Vendor ID / Product ID conflicting with another device on the host

### "Watchdog keeps resetting the chip"

Pattern: a task is blocked longer than the watchdog timeout, or the kick interval is wrong.

Common root causes:
- Highest-priority task running an unbounded loop (priority inversion can also cause this)
- Watchdog kick path itself blocked (e.g., kick is inside a mutex held by another task)
- Wrong watchdog window timing — some MCUs have a window watchdog that resets if kicked TOO SOON, not just too late
- Sleep modes that don't pause the watchdog clock

## Toolchain issues

### `arm-none-eabi-gcc` not found

```bash
# Linux
sudo apt install gcc-arm-none-eabi

# macOS
brew install --cask gcc-arm-embedded
```

Newer versions are available from [ARM's official downloads](https://developer.arm.com/downloads/-/arm-gnu-toolchain-downloads).

### OpenOCD won't connect to the target

Check in order:

1. Probe USB enumeration — does `lsusb` (or macOS Console) show the probe?
2. Permissions — on Linux, the probe needs udev rules. SEGGER J-Link's installer adds them; ST-Link needs `99-openocd.rules` from OpenOCD's contrib/.
3. Target power — OpenOCD can't connect if VTRef pin reads 0V
4. Reset state — try `openocd ... -c "init; reset halt"` to force a known state
5. SWD/JTAG wire order — common gotcha when using a 10-pin probe with a 4-pin SWD breakout

### `Error: Unknown option: --json` from openocd

Older openocd builds (< 0.11) don't support `--json`. Update OpenOCD or use the plain text output mode.

## Performance issues

### Code "feels slow" but you can't tell why

Reach for the `debug-trace` plugin's ITM/ETM walkthrough. Stopwatch-style print debugging adds enormous CPU overhead and hides real bottlenecks. ETM tracing on Cortex-M7 + a J-Trace probe gives you instruction-by-instruction timing without observer effect.

### DMA throughput lower than expected

Check:

- DMA priority vs. CPU bus master priority (some MCUs let the CPU starve the DMA)
- DMA stream vs. peripheral mapping (some peripherals only work with specific streams)
- Burst length (single-word vs. burst-of-4 vs. burst-of-8)
- Buffer alignment — unaligned DMA buffers force fallback to single-word transfers

### Power consumption higher than the datasheet implies

Datasheets specify with *all peripherals disabled*. In practice:

- Floating GPIO pins draw current (always configure as input-pulldown or output-low when unused)
- ADC reference voltage may keep an internal reference powered even between sample conversions
- Brownout reset circuitry stays powered in all but the deepest sleep modes
- Debugger probe holding SWCLK keeps the chip in "I'm being debugged" mode which can disable some sleep transitions

## When to file an issue

- A depth-complete plugin gives templated / generic answers — file an issue with the prompt
- A hook fires when it shouldn't — file an issue with `~/.claude/logs/hooks.log` (after redacting any project paths you don't want public)
- A `setup.sh` flag doesn't behave as documented
- Translation requests for learning paths

See [CONTRIBUTING.md](CONTRIBUTING.md) for the issue template.

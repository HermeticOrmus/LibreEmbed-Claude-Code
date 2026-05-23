# Advanced — ship firmware that survives the field

Your firmware works on the bench. You can flash it, debug it, demo it. None of that survives contact with real users in real environments unless you design for survival from Day 1. This path covers the patterns that separate firmware that ships from firmware that returns to engineering with field complaints.

## What you'll learn

- OTA update patterns that don't brick devices
- Watchdog + recovery patterns that catch real failures (not just total hangs)
- CI/CD for firmware — automated build, test, and release
- Long-term support — versioning, deprecation, multi-firmware deployment
- Telemetry + crash reporting from production devices
- Field debugging — diagnosing problems on a device you can't physically touch

## OTA update patterns

### Dual-bank flash

The reference architecture:

```
Flash layout:
  0x0800_0000 — 0x0801_FFFF  Bootloader (128 KB)
  0x0802_0000 — 0x080F_FFFF  Slot A (firmware bank 1, 896 KB)
  0x0810_0000 — 0x081F_FFFF  Slot B (firmware bank 2, 896 KB)
  0x0820_0000 — 0x0820_FFFF  Persistent state (which slot is active, signatures, etc.)
```

Update sequence:
1. Device currently running from Slot A
2. Bootloader records "active slot = A" in persistent state
3. Application downloads new firmware to Slot B
4. Application writes "active slot = B (pending)" to persistent state
5. Application verifies Slot B's signature
6. Application resets the device
7. Bootloader reads persistent state, sees Slot B pending, validates Slot B
8. Bootloader marks Slot B as committed, executes Slot B
9. New firmware runs; if it boots cleanly and checks in within N seconds, it's considered good
10. If new firmware fails to check in: bootloader reverts to Slot A on next reset

This is the **A/B with rollback** pattern. The user can't brick the device by interrupting an update — there's always a previously-known-good firmware to fall back to.

### Implementation outline

Use the `/bootloader` agent:

```
/bootloader design A/B firmware update for STM32F411RE with 1 MB Flash, using the persistent state pattern above. Include rollback on first-boot failure detection.
```

Expected output:
- Linker scripts for bootloader + Slot A + Slot B (each with distinct memory base addresses)
- Bootloader main: read persistent state, validate active slot's signature, jump to application
- Application: download new firmware, verify, write persistent state, reset
- First-boot detection: persistent state has "trial run" flag; if app doesn't clear it within N seconds, bootloader reverts on next boot

### Cryptographic signing

Never accept unsigned firmware. The bootloader must verify the firmware signature before executing it.

Minimum: SHA-256 hash + ECDSA signature (P-256).

The build pipeline:
1. Compile firmware to .bin
2. Compute SHA-256 hash
3. Sign hash with vendor private key (kept offline, in HSM or YubiKey)
4. Prepend signature + manifest to firmware binary
5. Bootloader verifies signature against pinned vendor public key

Use mbedTLS or libtomcrypt for the verification side.

## Watchdog + recovery patterns

The pattern hierarchy:

### Pattern 1: Heartbeat watchdog (covered in beginner)

Already covered: low-priority task kicks IWDG every N ms.

### Pattern 2: Per-task health aggregator (covered in intermediate)

Each task posts heartbeat; central watchdog task kicks only if all heartbeats recent.

### Pattern 3: Brownout + watchdog cooperation

```c
// On boot
if (RCC->CSR & RCC_CSR_WWDGRSTF) {
    log_event("Watchdog reset");
    record_crash_metadata();
}
if (RCC->CSR & RCC_CSR_IWDGRSTF) {
    log_event("Independent watchdog reset");
    record_crash_metadata();
}
if (RCC->CSR & RCC_CSR_BORRSTF) {
    log_event("Brownout reset");
}
RCC->CSR |= RCC_CSR_RMVF;  // Clear flags
```

The bootloader records why the last reset happened. If watchdog resets are frequent in the field, you have a real problem. If brownouts are frequent, the power supply is undersized.

### Pattern 4: Watchdog-triggered firmware revert

Combine OTA with watchdog: if the new firmware causes 3 watchdog resets in 5 minutes, the bootloader reverts to the previous firmware. This catches firmware bugs that the lab QA missed.

## CI/CD for firmware

### Build pipeline

```yaml
# GitHub Actions example
name: firmware-ci
on: [push, pull_request]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install ARM toolchain
        run: |
          sudo apt update
          sudo apt install gcc-arm-none-eabi
      - name: Build
        run: make BUILD_TYPE=release
      - name: Lint
        run: make lint
      - name: Unit tests (host)
        run: make test-host
      - name: Build size check
        run: |
          arm-none-eabi-size build/firmware.elf
          # Fail if .text exceeds 80% of flash
      - name: Upload artifacts
        uses: actions/upload-artifact@v4
        with:
          name: firmware
          path: build/firmware.bin
```

### Host-side unit tests

Embedded code can be tested on the host with Unity or Ceedling or cmocka, using mocks for hardware. Apply to:

- Pure logic (state machines, parsers, validators)
- Protocol implementations (CBOR parser, packet framing)
- Algorithm code (filtering, sensor fusion)

What can't be tested on the host:
- Anything that touches real hardware peripherals
- Timing-dependent code
- DMA + cache interactions

These need on-target tests (Step 3 below).

### Hardware-in-the-Loop (HIL) tests

A HIL rig is a fixture with:
- The target board
- A test controller (Raspberry Pi or another MCU)
- Loops back peripherals (UART RX↔TX, SPI master↔slave) for echo tests
- Simulates sensors (DAC outputs that pretend to be sensor voltages)
- Power-cycles the target programmatically

CI runs a small set of fast HIL tests on every PR; the full HIL suite runs nightly.

### Release pipeline

1. Tag a commit with `v1.2.3`
2. CI builds firmware, signs it with the release key (separate from dev key)
3. CI uploads to release artifact storage (S3, GitHub Releases, etc.)
4. Release manager promotes to canary (1% of devices)
5. Canary observed for N hours; metrics show no regression
6. Release manager promotes to staged rollout (10%, 50%, 100% over days)
7. Any device that crashes after upgrade reverts to previous version automatically

## Long-term support

### Versioning

Use semver: `MAJOR.MINOR.PATCH`. Bake into firmware:

```c
#define FW_VERSION_MAJOR 1
#define FW_VERSION_MINOR 4
#define FW_VERSION_PATCH 2

const char *fw_version_string(void) {
    static char s[16];
    snprintf(s, sizeof(s), "%d.%d.%d",
             FW_VERSION_MAJOR, FW_VERSION_MINOR, FW_VERSION_PATCH);
    return s;
}
```

Report at every device check-in. The cloud knows which version each device is on. Useful for diagnostics and rollout management.

### Multi-firmware deployment

If you have multiple SKUs (different sensors, different markets), version per-SKU:

```c
#define FW_SKU "sensor-node-eu"
```

The cloud's OTA manifest can route updates per SKU. Don't send the EU firmware to a US device.

### Deprecation

When you drop a feature: announce, deprecate, remove. Don't surprise users.

```c
#if FW_VERSION_MAJOR < 2
// Old API still available
#endif

#if FW_VERSION_MAJOR >= 2
// New API
#endif
```

Deprecated APIs that still work for 6-12 months give users time to migrate. Hard removals only at major version bumps.

## Telemetry + crash reporting

### What to log

- Boot (with reset cause)
- Watchdog resets (with last task heartbeat states)
- Hard faults (with PC, LR, fault status register)
- Peripheral errors (I2C bus-off, UART overrun, etc.)
- OTA events (download started, completed, verified, applied)
- Battery level (if applicable)

Aggregate to cloud at low frequency (once per hour, or on-error).

### What NOT to log

- User data
- Sensor readings (those go to the data pipeline, not the telemetry pipeline)
- Anything that requires explicit user consent

### Crash reporting

When the device crashes (hard fault, unhandled exception), the fault handler should:

1. Save PC, LR, SP, fault status to persistent storage (RTC backup registers, or flash sector)
2. Reset

On boot:
1. Bootloader / app checks persistent crash data
2. If present, send to cloud telemetry
3. Clear

The agent in `/debug-embedded` can help write the fault handler. STM32 ARM Cortex-M has well-documented patterns.

## Field debugging

When a device misbehaves in the field, you don't have physical access. Tools:

- **Telemetry log**: what the device has been doing
- **Remote logging level adjustment**: command the device to set log level to DEBUG temporarily
- **Remote crash dump retrieval**: request the device's most recent crash dump
- **Coredump on demand**: rare, but for critical bugs — request a full memory snapshot

Build these into the firmware from Day 1. Adding them after a problem is harder than designing for them.

### Field debugging workflow

```
Customer: "My device stopped working at 14:00 UTC yesterday."

You:
1. Pull device telemetry from cloud
2. Find logs from 13:55 - 14:05 UTC
3. Identify last event before silence (often a watchdog reset followed by a crash dump)
4. Read the crash dump's PC + LR → identify which function crashed
5. Reproduce in lab if possible
6. Fix, queue for next release
```

This workflow only works if telemetry + crash reporting + log retrieval are in the firmware. Build them early.

## What you learned

- Firmware updates need cryptographic verification + rollback
- Watchdogs catch more than total hangs when designed well
- CI/CD for embedded looks like CI/CD for any other software, with target-specific test rigs
- Long-term support requires versioning + per-SKU manifests + deprecation discipline
- Telemetry + crash reporting are Day-1 features, not "we'll add it later"
- Field debugging is design, not heroics

## What's still hard

This bundle doesn't replace deep expertise in:

- Safety certification (IEC 61508, DO-178C, ISO 26262) — see `/safety` plugin and dedicated industry resources
- Compliance + regulatory (FCC, CE, regional approvals)
- Manufacturing test fixtures + product testing
- Supply chain (component sourcing, second sources, end-of-life management)

These are full disciplines. The agents in this bundle help you write the firmware; they don't help you ship the product. For that, you need humans with experience in the specific domain.

## Where to go from here

- **Contribute back**: real-board examples + worked-out HIL rig schematics are gold for newcomers. See [CONTRIBUTING.md](../CONTRIBUTING.md).
- **Deepen specific plugins**: the bundle has 15 plugins; depth varies. The maturity matrix in [CHANGELOG.md](../CHANGELOG.md) tracks which are depth-complete and which need work.
- **Pair with other Libre-X-Claude-Code repos**:
  - [LibreUIUX-Claude-Code](https://github.com/HermeticOrmus/LibreUIUX-Claude-Code) — when your embedded product has a companion mobile or web UI
  - [LibreGEO-Claude-Code](https://github.com/HermeticOrmus/LibreGEO-Claude-Code) — when your product's marketing site needs to rank in AI search

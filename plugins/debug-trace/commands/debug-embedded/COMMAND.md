# /debug-embedded

Embedded debug command: fault analysis, GDB sessions, trace setup, stack inspection.

## Trigger

`/debug-embedded <action> [options]`

## Actions

### `attach`
Generate OpenOCD or J-Link connection commands.

```
/debug-embedded attach --probe stlink --target stm32f4x
/debug-embedded attach --probe jlink --device STM32F407VG --speed 4000
/debug-embedded attach --probe pyocd --target stm32f407
```

### `halt`
Stop the target and inspect state.

```
/debug-embedded halt --dump-registers
/debug-embedded halt --dump-stack --depth 32
```

### `fault-analyze`
Decode fault registers from a running or halted target.

```
/debug-embedded fault-analyze --cfsr 0x00020000
/debug-embedded fault-analyze --cfsr 0x00008200 --bfar 0x00000004
/debug-embedded fault-analyze --hfsr 0x40000000
```

Outputs: fault type in plain English, common causes, suggested fix, addr2line command.

### `trace`
Configure ITM/SWO or ETM trace.

```
/debug-embedded trace --itm-printf --cpu-freq 168000000 --swo-freq 2000000
/debug-embedded trace --dwt-cycles --instrument my_function
/debug-embedded trace --watchpoint --addr 0x20001234 --type write
```

## Process

1. Identify probe type and connection.
2. For faults: read CFSR, HFSR, MMFAR, BFAR from 0xE000ED28–0xE000ED38.
3. Extract stacked PC from exception frame (MSP or PSP depending on EXC_RETURN bit 2).
4. Run addr2line with stacked PC to get source location.
5. Check LR for caller context.

## Output Examples

### CFSR decode: 0x00020000
```
CFSR = 0x00020000
  UFSR[17] = INVSTATE = 1
  Meaning: CPU tried to execute an instruction in ARM state (Thumb bit = 0 in xPSR).
  Common cause: function pointer missing Thumb bit (should be addr | 1).
  Fix: ensure function pointers are loaded from elf/symbol table, not cast from integer.
```

### GDB session startup
```bash
arm-none-eabi-gdb -ex "target remote :3333" \
                  -ex "monitor reset halt"   \
                  -ex "load"                 \
                  -ex "break HardFault_HandlerC" \
                  -ex "continue"             \
                  firmware.elf
```

### addr2line decode
```bash
arm-none-eabi-addr2line -e firmware.elf -f -i 0x08003A24
# → sensor_init at src/sensor.c:142
```

### pyOCD flash and debug
```bash
# Flash and run
pyocd flash -t stm32f407 firmware.elf

# GDB server on port 3333
pyocd gdb -t stm32f407

# Commander (interactive)
pyocd commander -t stm32f407
>> halt
>> reg
>> read32 0xE000ED28   # CFSR
```

## Error Handling

- "Error: JTAG-DP STICKY ERROR" — probe connection issue; check SWD wiring, SWDCLK/SWDIO pins
- "No device found" — target may be in low-power mode; assert NRST or use power-on attach
- "HardFault on load" — flash not erased or wrong target in OpenOCD config
- "backtrace unavailable" — compiled with -O2 without -fno-omit-frame-pointer; use addr2line on stacked PC instead

# /bare-metal

Bare-metal firmware command: register-level drivers, linker scripts, startup code, and size analysis.

## Trigger

`/bare-metal <action> [options]`

## Actions

### `init`
Generate a complete bare-metal project scaffold for a target MCU.

```
/bare-metal init --mcu stm32f407vg --flash 1024K --sram 128K --ccm 64K
/bare-metal init --mcu stm32f103c8 --flash 64K --sram 20K
```

Generates:
- `startup.c` with Reset_Handler and weak default ISR aliases
- `<mcu>.ld` linker script with MEMORY regions and SECTIONS
- `Makefile` with arm-none-eabi-gcc flags (`-Os -ffunction-sections --gc-sections`)
- `main.c` skeleton with SystemInit call and infinite loop

### `optimize`
Analyze and reduce code/data size.

```
/bare-metal optimize --map firmware.map --target flash
/bare-metal optimize --elf firmware.elf --show-top 20
```

Actions:
- Parse `.map` file for top consumers
- Suggest `__attribute__((optimize("Os")))` on hot paths that need size over speed
- Identify padding bytes between sections
- Check for `-fno-exceptions` and `-fno-rtti` if C++ is mixed in

### `analyze-map`
Decode a linker map file.

```
/bare-metal analyze-map firmware.map
/bare-metal analyze-map firmware.map --section .text --min-size 512
```

Output: table of symbol, section, size, origin file, sorted descending.

### `flash`
Generate flash commands for common programmers.

```
/bare-metal flash --tool openocd --interface stlink --target stm32f4x
/bare-metal flash --tool pyocd --target stm32f407
/bare-metal flash --tool jlink --device STM32F407VG
```

## Process

1. Confirm MCU part number (determines FLASH/SRAM sizes, peripheral base addresses).
2. Check if CMSIS device headers are available (`stm32f4xx.h` or similar).
3. Generate startup and linker script matching the target's memory map exactly.
4. Verify with `arm-none-eabi-size` that sections fit within declared MEMORY regions.
5. Add linker `ASSERT` statements to catch overflows at link time.

## Output Examples

### Flash + SRAM ASSERT in linker script
```ld
/* Fail at link time if firmware exceeds flash */
ASSERT(SIZEOF(.text) + SIZEOF(.data) < LENGTH(FLASH),
       "ERROR: Flash overflow")

ASSERT(SIZEOF(.data) + SIZEOF(.bss) < LENGTH(SRAM),
       "ERROR: SRAM overflow")
```

### Makefile flash target (OpenOCD + ST-Link)
```makefile
OPENOCD      = openocd
OCD_IFACE    = -f interface/stlink.cfg
OCD_TARGET   = -f target/stm32f4x.cfg
OCD_FLASH_CMD = -c "program firmware.elf verify reset exit"

flash: firmware.elf
	$(OPENOCD) $(OCD_IFACE) $(OCD_TARGET) $(OCD_FLASH_CMD)

erase:
	$(OPENOCD) $(OCD_IFACE) $(OCD_TARGET) \
	  -c "init" -c "halt" -c "stm32f4x mass_erase 0" -c "exit"
```

### arm-none-eabi-size output interpretation
```
   text    data     bss     dec     hex filename
   9832     128     512   10472    28e8 firmware.elf

text = flash used for code + rodata + .data LMA copy
data = SRAM initialized variables (also counted in flash above)
bss  = SRAM zero-initialized variables (not in flash)
```

## Error Handling

Common failures:
- "region FLASH overflowed" — reduce code size: `-Os`, check for accidental float printf
- "undefined reference to _sbrk" — add `-specs=nosys.specs` or provide your own `_sbrk`
- "HardFault at 0x08000000" — vector table not in flash at expected address; check BOOT0/BOOT1 pin state
- "reset loops" — `.data` copy overwrites stack; check `_estack` and `_sidata` in `.map` file

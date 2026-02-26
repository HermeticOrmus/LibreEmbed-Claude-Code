# /cortex-m

ARM Cortex-M development command: startup code, linker scripts, peripheral configuration, and debug.

## Trigger

`/cortex-m <action> [options]`

## Actions

### `init`
Generate startup code and linker script for a target MCU.

```
/cortex-m init --mcu stm32f407 --flash 1024K --sram 192K --ccm 64K
/cortex-m init --mcu nrf52840 --flash 1024K --sram 256K
```

Generates:
- `startup_stm32f407xx.s` or `.c` (Reset_Handler, vector table, .data copy, .bss zeroing)
- `stm32f407.ld` (MEMORY regions, SECTIONS with LMA/VMA separation)
- `system_init.c` (clock tree, FPU enable, SysTick)

### `configure`
Configure a specific Cortex-M subsystem.

```
/cortex-m configure --subsystem nvic --groups 4
/cortex-m configure --subsystem fpu --core m4
/cortex-m configure --subsystem mpu --guard-stack 0x20000000 --size 32
/cortex-m configure --subsystem systick --freq-hz 168000000 --tick-ms 1
```

### `debug`
Analyze fault conditions and decode exception frames.

```
/cortex-m debug --fault hardfault
/cortex-m debug --fault memmanage
/cortex-m debug --decode-cfsr 0x00000082
/cortex-m debug --stack-frame 0x20001F00
```

Outputs: decoded CFSR/HFSR/BFAR/MMFAR, stacked register dump, fault cause in plain English.

### `benchmark`
Generate DWT-based timing instrumentation.

```
/cortex-m benchmark --function my_dsp_filter --core m4
/cortex-m benchmark --isr uart_rx_handler --cycles
```

## Process

1. Confirm target core variant (determines available features: FPU, DSP, MPU regions, DWT).
2. Read existing linker script and startup if present.
3. Generate or modify requested artifact.
4. Include barrier instructions (`__DSB`, `__ISB`) wherever system register writes occur.
5. Verify generated ISR names against device header `IRQn_Type` enum.

## Output Examples

### Minimal linker script fragment (STM32F407, Cortex-M4)
```ld
MEMORY
{
  FLASH  (rx)  : ORIGIN = 0x08000000, LENGTH = 1024K
  SRAM   (rwx) : ORIGIN = 0x20000000, LENGTH = 128K
  SRAM2  (rwx) : ORIGIN = 0x2001C000, LENGTH = 16K
  CCM    (rwx) : ORIGIN = 0x10000000, LENGTH = 64K
}

_estack = ORIGIN(SRAM) + LENGTH(SRAM);

SECTIONS
{
  .isr_vector :
  {
    . = ALIGN(4);
    KEEP(*(.isr_vector))
    . = ALIGN(4);
  } > FLASH

  .text :
  {
    . = ALIGN(4);
    *(.text)
    *(.text*)
    *(.rodata)
    *(.rodata*)
    . = ALIGN(4);
    _etext = .;
  } > FLASH

  .data :
  {
    . = ALIGN(4);
    _sdata = .;
    *(.data)
    *(.data*)
    . = ALIGN(4);
    _edata = .;
  } > SRAM AT > FLASH

  _sidata = LOADADDR(.data);

  .bss :
  {
    . = ALIGN(4);
    _sbss = .;
    *(.bss)
    *(.bss*)
    *(COMMON)
    . = ALIGN(4);
    _ebss = .;
  } > SRAM
}
```

### Reset_Handler (C version)
```c
extern uint32_t _sidata, _sdata, _edata, _sbss, _ebss;

void Reset_Handler(void)
{
    uint32_t *src = &_sidata;
    uint32_t *dst = &_sdata;

    /* Copy .data from flash to SRAM */
    while (dst < &_edata) { *dst++ = *src++; }

    /* Zero .bss */
    dst = &_sbss;
    while (dst < &_ebss) { *dst++ = 0U; }

    SystemInit();           /* Clock tree, FPU enable */
    __libc_init_array();    /* C++ constructors, .init_array */
    main();

    for (;;) { __WFI(); }  /* Should not reach here */
}
```

## Error Handling

```
## /cortex-m Error

Issue: [description]
Likely cause: [root cause]
Fix: [specific action]
```

Common errors:
- "HardFault on startup" → .data copy overwrites SRAM before stack is set; check `_estack` in linker script
- "FPU UsageFault" → `SCB->CPACR` not set before first FP instruction; call `fpu_enable()` in SystemInit
- "Wrong IRQ fires" → VTOR not updated after bootloader jump; check `SCB->VTOR` value in debugger

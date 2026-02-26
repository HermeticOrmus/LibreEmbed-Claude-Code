# /memory

Memory management command: pool allocators, stack sizing, heap analysis, MPU protection.

## Trigger

`/memory <action> [options]`

## Actions

### `analyze`
Analyze memory usage from a map file or ELF.

```
/memory analyze --elf firmware.elf
/memory analyze --map firmware.map --show-stacks
```

### `pool`
Generate a fixed-block memory pool for a data type.

```
/memory pool --type msg_t --count 32 --thread-safe freertos
/memory pool --size 128 --count 16 --type generic
```

### `protect`
Generate MPU configuration for stack protection.

```
/memory protect --mcu stm32f4 --guard-stack --region 7
/memory protect --mcu stm32h7 --regions "bootloader=ro,app-stack=guard"
```

### `audit`
Generate stack high-water mark audit code.

```
/memory audit --tasks "sensor=256,comm=512,display=384" --alert-threshold 32
```

## Process

1. Run `arm-none-eabi-size` to get current SRAM usage.
2. Identify all FreeRTOS objects and their sizes.
3. Check `uxTaskGetStackHighWaterMark` for each task after 24h of typical operation.
4. Calculate: stack usage = (initial_stack_depth - hwm) * 4 bytes.
5. Set minimum stack = peak_usage * 1.5 (50% headroom).

## Output Examples

### Memory budget calculation
```
Flash:
  .text + .rodata: 48,320 bytes (48KB)
  .data LMA copy:     512 bytes
  Total flash:     48,832 / 1,048,576 bytes (4.6%)

SRAM:
  .data (init):      512 bytes
  .bss  (zero):    4,096 bytes
  FreeRTOS heap:  32,768 bytes
  Task stacks:     6,144 bytes  (sensor=1KB, comm=2KB, display=1.5KB, idle=256B, timer=512B)
  Total SRAM:     43,520 / 131,072 bytes (33%)
```

### Stack sizing formula
```
Required stack = local variables + nested call chain depth + interrupt overhead
  + printf with %d: ~256 bytes
  + printf with %f: ~1024 bytes (avoid in embedded)
  + FreeRTOS queue send/receive: ~64 bytes
  + IRQ save/restore frame: 32 bytes (8 stacked registers * 4 bytes)

Minimum for a sensor task doing I2C reads and printf:
  = 256 (locals) + 128 (calls) + 256 (printf %d) + 64 (queue) + 32 (IRQ) = 736 bytes ≈ 192 words
  With 50% headroom: 288 words → use 384 words (configurable in 256-word steps)
```

### FreeRTOS static allocation check
```c
/* Verify static allocation is enabled */
#if (configSUPPORT_STATIC_ALLOCATION != 1)
  #error "Enable configSUPPORT_STATIC_ALLOCATION for static RTOS objects"
#endif

/* Required by FreeRTOS kernel when static alloc is enabled */
void vApplicationGetIdleTaskMemory(StaticTask_t **tcb,
                                    StackType_t **stack, uint32_t *size)
{
    static StaticTask_t idle_tcb;
    static StackType_t  idle_stack[configMINIMAL_STACK_SIZE];
    *tcb   = &idle_tcb;
    *stack = idle_stack;
    *size  = configMINIMAL_STACK_SIZE;
}
```

## Error Handling

- "pvPortMalloc returned NULL" — heap exhausted; increase `configTOTAL_HEAP_SIZE` or find leak
- "Stack overflow detected" — FreeRTOS stack overflow hook fired; increase task stack depth
- "HardFault on stack write" — MPU guard triggered; confirm stack bottom alignment and region size
- "Heap fragmentation" — many small allocs/frees; switch from dynamic to memory pool for that object type

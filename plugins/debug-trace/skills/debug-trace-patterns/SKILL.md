# debug-trace-patterns

## Knowledge Base

Practical debug patterns for ARM Cortex-M firmware. Tools: OpenOCD, GDB, J-Link, logic analyzer.

---

## Pattern 1: Decode CFSR After HardFault

Given a CFSR value (e.g., from `monitor mdw 0xE000ED28`), decode:

```
CFSR = 0x00020000 → UFSR.INVSTATE (bit 17)
  Cause: Attempted to execute code with Thumb bit cleared in xPSR.
  Common cause: function pointer stored with bit 0 cleared (missing |1 for Thumb).

CFSR = 0x00000400 → BFSR.IMPRECISERR (bit 10)
  Cause: Imprecise bus error. BFAR is not valid.
  Common cause: DMA write to invalid address, async fault from write buffer.
  Fix: set SCB->CCR |= SCB_CCR_BFHFNMIGN_Msk temporarily to locate source.

CFSR = 0x00008200 → BFSR.PRECISERR + BFSR.BFARVALID
  Cause: Precise data bus error. BFAR = 0xE000ED38 contains fault address.
  Common cause: null pointer dereference, access to unmapped memory region.

CFSR = 0x02000000 → UFSR.DIVBYZERO (bit 25)
  Cause: Integer divide by zero.
  Fix: enable div-by-zero trap: SCB->CCR |= SCB_CCR_DIV_0_TRP_Msk.
```

---

## Pattern 2: addr2line — Fault PC to Source Line

```bash
# Convert stacked PC to source file + line number
arm-none-eabi-addr2line -e firmware.elf -f -i 0x08003A24

# Output:
# sensor_read
# /home/user/project/src/sensor.c:87

# Also inspect LR to find the caller:
arm-none-eabi-addr2line -e firmware.elf -f -i 0x080038F6
```

The `-i` flag follows inline function chains.

---

## Pattern 3: GDB Commands for Live Fault Debugging

```bash
# Full embedded debug session
arm-none-eabi-gdb firmware.elf
(gdb) target remote :3333       # OpenOCD GDB server
(gdb) monitor reset halt
(gdb) load

# After a fault occurs:
(gdb) info registers            # All CPU registers
(gdb) p/x *((uint32_t*)0xE000ED28)   # CFSR
(gdb) p/x *((uint32_t*)0xE000ED2C)   # HFSR
(gdb) p/x *((uint32_t*)0xE000ED34)   # MMFAR
(gdb) p/x *((uint32_t*)0xE000ED38)   # BFAR
(gdb) x/16xw $sp                # Stack dump
(gdb) backtrace                 # Unwind stack (requires -g and no -O2 optimization)

# Watchpoints: halt when variable changes
(gdb) watch g_critical_var
(gdb) rwatch *(uint32_t*)0x20001000   # Hardware read watchpoint (DWT)
```

---

## Pattern 4: Stack Corruption Detection with Canary

```c
#define STACK_CANARY_VAL  0xDEADBEEFUL

/* Place canary at bottom of task stack (lowest address, first to overflow) */
void stack_canary_init(uint32_t *stack_bottom, uint32_t depth)
{
    for (uint32_t i = 0; i < depth; i++) {
        stack_bottom[i] = STACK_CANARY_VAL;
    }
}

/* Call periodically or from idle task hook */
bool stack_canary_check(const uint32_t *stack_bottom, uint32_t depth)
{
    for (uint32_t i = 0; i < depth; i++) {
        if (stack_bottom[i] != STACK_CANARY_VAL) {
            return false;  /* Overflow: canary corrupted */
        }
    }
    return true;
}
```

FreeRTOS alternative: `uxTaskGetStackHighWaterMark(NULL)` returns minimum free stack words ever observed for the current task.

---

## Pattern 5: ITM Trace Printf

```c
/* Retarget printf to ITM port 0 (SWO output) */
int _write(int fd, const char *buf, int len)
{
    (void)fd;
    for (int i = 0; i < len; i++) {
        ITM_SendChar((uint32_t)buf[i]);
    }
    return len;
}

/* ITM enable in SystemInit or debug init: */
void itm_enable(uint32_t cpu_freq, uint32_t swo_freq)
{
    CoreDebug->DEMCR |= CoreDebug_DEMCR_TRCENA_Msk;
    /* SWO prescaler: cpu_freq / swo_freq - 1 */
    TPI->ACPR  = cpu_freq / swo_freq - 1U;
    TPI->SPPR  = 2U;   /* NRZ (UART) encoding */
    TPI->FFCR  = 0x100U;
    ITM->LAR   = 0xC5ACCE55UL;  /* Unlock ITM */
    ITM->TCR   = ITM_TCR_ITMENA_Msk | ITM_TCR_SYNCENA_Msk | (1UL << 16);
    ITM->TER   = 0xFFFFFFFFUL;  /* Enable all 32 stimulus ports */
}
```

Host: ST-Link SWV viewer in STM32CubeIDE, or J-Link SWO Viewer, or OpenOCD `tpiu` + PuTTY serial.

---

## Pattern 6: DWT Data Watchpoint (without debugger)

Use DWT comparators to detect writes to a specific address at runtime:

```c
/* Trigger DebugMon exception when address 0x20001234 is written */
void dwt_set_watchpoint(uint32_t addr)
{
    CoreDebug->DEMCR |= CoreDebug_DEMCR_TRCENA_Msk | CoreDebug_DEMCR_MON_EN_Msk;
    DWT->COMP0    = addr;
    DWT->MASK0    = 0U;        /* Match exact address */
    DWT->FUNCTION0 = 0x6U;    /* Data write watchpoint → DebugMon */
}

/* DebugMon_Handler fires instead of halting (no debugger attached) */
void DebugMon_Handler(void)
{
    DWT->FUNCTION0 = 0U;  /* Disable watchpoint */
    /* Log PC, LR for analysis */
}
```

---

## Anti-Patterns

- **Using printf for timing analysis**: printf is slow (UART or ITM) and perturbs timing. Use DWT->CYCCNT or toggle a GPIO on oscilloscope.
- **Compiling with -O0 always**: some bugs are optimizer-sensitive. Debug with -Og (debug optimizations) to get accurate backtraces while keeping most debug info.
- **Ignoring IMPRECISERR**: it means the fault address is not directly available. Enable BFHFNMIGN + process in NMI to find the source.
- **Not initializing DWT before using cycle counter**: CoreDebug->DEMCR bit must be set first, or DWT->CYCCNT stays 0.

## References

- ARM CoreSight Architecture Specification: IHI0029
- OpenOCD documentation: openocd.org/doc/html/
- Percepio Tracealyzer: trace tool for FreeRTOS
- "Hard Fault Analysis" by Joseph Yiu (ARM community blog)

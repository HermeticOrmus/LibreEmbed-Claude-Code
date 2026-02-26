# cortex-m-patterns

## Knowledge Base

Real ARM Cortex-M patterns used in production firmware. All code targets C11 with arm-none-eabi-gcc unless noted.

---

## Pattern 1: SysTick Configuration

SysTick is a 24-bit down-counter built into every Cortex-M. Used as the RTOS tick source or a simple 1ms timebase.

```c
/* Configure SysTick for 1ms interrupt at SystemCoreClock = 168 MHz */
/* Returns 0 on success, 1 if reload value exceeds 24-bit counter   */
uint32_t systick_init_1ms(void)
{
    return SysTick_Config(SystemCoreClock / 1000U);
    /* SysTick_Config: sets LOAD = (ticks-1), CTRL = CLKSOURCE|TICKINT|ENABLE */
}

volatile uint32_t g_tick_ms = 0;

void SysTick_Handler(void)
{
    g_tick_ms++;
}

uint32_t get_tick_ms(void)
{
    return g_tick_ms;
}

void delay_ms(uint32_t ms)
{
    uint32_t start = get_tick_ms();
    while ((get_tick_ms() - start) < ms) { __NOP(); }
}
```

Key: `SysTick_Config` is CMSIS-Core, defined in `core_cm4.h`. The RELOAD value is `(SystemCoreClock/ticks_per_sec) - 1`.

---

## Pattern 2: NVIC Priority Grouping

Priority grouping splits the 8-bit priority register into preempt bits and sub-priority bits.

```c
/* NVIC_PRIORITYGROUP_4: 4 bits preempt (0-15), 0 bits sub.
   NVIC_PRIORITYGROUP_2: 2 bits preempt (0-3),  2 bits sub. */

/* STM32 HAL sets NVIC_PRIORITYGROUP_4 in HAL_Init() */
HAL_NVIC_SetPriorityGrouping(NVIC_PRIORITYGROUP_4);

/* DMA stream2 at preempt=5, sub=0 */
HAL_NVIC_SetPriority(DMA1_Stream2_IRQn, 5, 0);
HAL_NVIC_EnableIRQ(DMA1_Stream2_IRQn);

/* UART1 at lower preempt than DMA so DMA can preempt UART ISR */
HAL_NVIC_SetPriority(USART1_IRQn, 6, 0);
HAL_NVIC_EnableIRQ(USART1_IRQn);
```

Rule: FreeRTOS requires all ISRs that call `FromISR` API to have priority numerically >= `configLIBRARY_MAX_SYSCALL_INTERRUPT_PRIORITY` (lower urgency). Hardware-only ISRs (DMA completion triggering semaphore) can use any priority.

---

## Pattern 3: Cortex-M4 FPU Enable

Must execute before any floating-point instruction, before FreeRTOS scheduler starts.

```c
void fpu_enable(void)
{
    /* CP10 and CP11: coprocessors for FPU. Set both to full access (0b11). */
    SCB->CPACR |= ((3UL << (10U * 2U)) | (3UL << (11U * 2U)));
    __DSB();  /* Data Synchronization Barrier: ensure write completes */
    __ISB();  /* Instruction Synchronization Barrier: flush pipeline   */
}
```

On STM32F4: called from `SystemInit()` in `system_stm32f4xx.c` if `__FPU_PRESENT` and `__FPU_USED` are defined. Verify with:

```c
assert_param((__get_FPSCR() & 0x1U) == 0U); /* FPU idle after enable */
```

---

## Pattern 4: MPU Region Setup (Cortex-M4)

Use MPU to catch stack overflows by placing a no-access region at the bottom of the stack.

```c
#include "core_cm4.h"

void mpu_configure_stack_guard(uint32_t stack_bottom_addr)
{
    /* Disable MPU before configuration */
    MPU->CTRL = 0;

    /* Region 0: stack guard, 32 bytes, no access */
    MPU->RNR  = 0U;                          /* Select region 0 */
    MPU->RBAR = (stack_bottom_addr & MPU_RBAR_ADDR_Msk) | MPU_RBAR_VALID_Msk | 0U;
    MPU->RASR = MPU_RASR_ENABLE_Msk          /* Enable region     */
              | (0x04U << MPU_RASR_SIZE_Pos)  /* Size = 2^(4+1) = 32 bytes */
              | (0x00U << MPU_RASR_AP_Pos)    /* AP=000: no access         */
              | MPU_RASR_XN_Msk;             /* Execute-never             */

    /* Enable MPU with default memory map for privileged code */
    MPU->CTRL = MPU_CTRL_ENABLE_Msk | MPU_CTRL_PRIVDEFENA_Msk;
    __DSB();
    __ISB();
}
```

Size field encodes as `(log2(size_bytes) - 1)`. 32 bytes = 2^5, so SIZE = 4 (0x04).

---

## Pattern 5: AAPCS Register Usage in Inline Assembly

```c
/* Cortex-M4: get PSP (Process Stack Pointer) from privileged context */
static inline uint32_t get_psp(void)
{
    uint32_t result;
    __asm volatile ("MRS %0, psp\n" : "=r" (result));
    return result;
}

/* Trigger PendSV for context switch */
static inline void trigger_pendsv(void)
{
    SCB->ICSR = SCB_ICSR_PENDSVSET_Msk;
    __DSB();
    __ISB();
}
```

AAPCS: R0 returns the result (single 32-bit return value). `volatile` on `__asm` prevents the compiler from removing or reordering it.

---

## Pattern 6: DWT Cycle Counter for Timing

DWT (Data Watchpoint and Trace) provides a free-running 32-bit cycle counter on M3/M4/M7.

```c
void dwt_enable(void)
{
    /* Enable DWT: requires CoreDebug to be unlocked */
    CoreDebug->DEMCR |= CoreDebug_DEMCR_TRCENA_Msk;
    DWT->CYCCNT  = 0U;
    DWT->CTRL   |= DWT_CTRL_CYCCNTENA_Msk;
}

uint32_t dwt_get_cycles(void) { return DWT->CYCCNT; }

/* Usage: measure ISR latency */
uint32_t t0 = dwt_get_cycles();
HAL_GPIO_TogglePin(GPIOA, GPIO_PIN_5);
uint32_t cycles = dwt_get_cycles() - t0;
float us = (float)cycles / (SystemCoreClock / 1e6f);
```

Note: DWT->CYCCNT is not available on Cortex-M0/M0+ (no DWT). Use SysTick reload difference instead.

---

## Pattern 7: Vector Table Relocation

Bootloaders relocate the application vector table to SRAM or a different flash offset before jumping.

```c
/* In application startup, called before any interrupt is enabled */
void vtor_relocate(void)
{
    /* Copy vector table to SRAM (required if running from external flash) */
    extern uint32_t __isr_vector_start;   /* Linker symbol: start of .isr_vector */
    uint32_t *src = &__isr_vector_start;
    uint32_t *dst = (uint32_t *)0x20000000UL; /* SRAM base */

    for (uint32_t i = 0; i < 256U; i++) {
        dst[i] = src[i];
    }

    SCB->VTOR = 0x20000000UL;
    __DSB();
}
```

On Cortex-M0 (no VTOR): vector table is always at 0x00000000. Use memory remap if needed.

---

## Pattern 8: Sleep Entry with WFI

```c
/* Enter Sleep mode, wake on any IRQ */
void enter_sleep(void)
{
    /* Clear SLEEPDEEP to select Sleep (not Stop/Standby) */
    SCB->SCR &= ~SCB_SCR_SLEEPDEEP_Msk;
    __DSB();
    __ISB();
    __WFI();
    /* Execution resumes here after wakeup ISR completes */
}
```

Common mistake: forgetting `__DSB()`/`__ISB()` before `__WFI()`. Without them, pending register writes may not complete and the CPU may not enter sleep.

---

## Anti-Patterns

- **Missing `volatile` on hardware registers**: Without `volatile`, the compiler caches register reads in a CPU register and misses hardware updates. CMSIS device headers declare all peripheral structs as `volatile`.
- **Unaligned 32-bit access on M0**: Cortex-M0 does not support unaligned word access. Use `__UNALIGNED_UINT32_READ` macro from CMSIS or byte-by-byte copy.
- **Calling `FromISR` API without FreeRTOS priority ceiling**: ISR priority must be >= `configLIBRARY_MAX_SYSCALL_INTERRUPT_PRIORITY`. Violating this causes silent corruption.
- **Not flushing pipeline after SCB->VTOR write**: Always follow SCB register writes with `__DSB()` + `__ISB()`.
- **Using SysTick for DMA timing on M4**: DMA operates independently of CPU. Use DMA transfer-complete interrupt, not SysTick polling.

## References

- ARM Cortex-M4 Technical Reference Manual (DDI0439)
- ARMv7-M Architecture Reference Manual (DDI0403)
- CMSIS-Core documentation: https://arm-software.github.io/CMSIS_5/Core/html/
- STM32F4 Reference Manual (RM0090)

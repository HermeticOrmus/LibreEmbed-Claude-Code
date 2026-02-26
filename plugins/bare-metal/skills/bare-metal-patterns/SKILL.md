# bare-metal-patterns

## Knowledge Base

Production bare-metal C patterns for ARM Cortex-M. All code uses arm-none-eabi-gcc, C11.

---

## Pattern 1: Register Bit Manipulation Macros

Consistent, readable register access without HAL dependency.

```c
/* Generic bit manipulation — safe for any 32-bit register */
#define REG_SET_BIT(reg, bit)      ((reg) |=  (1U << (bit)))
#define REG_CLR_BIT(reg, bit)      ((reg) &= ~(1U << (bit)))
#define REG_TST_BIT(reg, bit)      (((reg) >> (bit)) & 1U)

/* Set a multi-bit field: mask off old value, OR in new value */
#define REG_SET_FIELD(reg, mask, shift, val) \
    ((reg) = ((reg) & ~(mask)) | (((val) << (shift)) & (mask)))

/* Example: set USART1 baud rate divisor in BRR register */
/* BRR = fCK / baud (oversampling by 16) */
#define USART_BRR_SET(uart, fck, baud) \
    ((uart)->BRR = (uint32_t)((fck) / (baud)))

USART_BRR_SET(USART1, 84000000UL, 115200UL);  /* STM32F4 APB2 @ 84MHz */
```

---

## Pattern 2: GPIO Configuration (Register Level)

Full GPIO setup for STM32F4 without HAL:

```c
/* PA5 = LED (push-pull output), PA0 = button (input, pull-up) */
void gpio_init(void)
{
    /* 1. Enable GPIOA clock */
    RCC->AHB1ENR |= RCC_AHB1ENR_GPIOAEN;
    (void)RCC->AHB1ENR;            /* Bus latency flush: read back after write */

    /* 2. PA5: General purpose output, push-pull, high speed */
    GPIOA->MODER   = (GPIOA->MODER & ~(3U << 10)) | (1U << 10);  /* MODER5 = 01 */
    GPIOA->OTYPER &= ~(1U << 5);                                  /* Push-pull */
    GPIOA->OSPEEDR|=  (3U << 10);                                 /* Very high speed */
    GPIOA->PUPDR   = (GPIOA->PUPDR & ~(3U << 10));                /* No pull */

    /* 3. PA0: Input, pull-up */
    GPIOA->MODER   = (GPIOA->MODER & ~(3U << 0));   /* MODER0 = 00: input */
    GPIOA->PUPDR   = (GPIOA->PUPDR & ~(3U << 0)) | (1U << 0);  /* Pull-up */
}

static inline void led_on(void)  { GPIOA->BSRR = (1U << 5);       }
static inline void led_off(void) { GPIOA->BSRR = (1U << (5+16));  }
static inline void led_toggle(void) { GPIOA->ODR ^= (1U << 5);    }
static inline int  btn_read(void) { return (int)((GPIOA->IDR >> 0) & 1U); }
```

---

## Pattern 3: UART Transmit (Polling, No HAL)

```c
void uart1_init(uint32_t baud)
{
    /* USART1 on APB2 (84 MHz on STM32F407) */
    RCC->APB2ENR |= RCC_APB2ENR_USART1EN;

    /* PA9 = TX, PA10 = RX: set alternate function 7 (USART1) */
    GPIOA->MODER   = (GPIOA->MODER & ~(0xFU << 18)) | (0xAU << 18); /* AF mode */
    GPIOA->AFR[1] |= (7U << ((9-8)*4)) | (7U << ((10-8)*4));       /* AF7 */

    USART1->BRR = 84000000UL / baud;   /* 84 MHz / baud rate */
    USART1->CR1 = USART_CR1_TE         /* Transmitter enable */
                | USART_CR1_RE         /* Receiver enable     */
                | USART_CR1_UE;        /* USART enable        */
}

void uart1_send_byte(uint8_t c)
{
    while (!(USART1->SR & USART_SR_TXE)) { __NOP(); }  /* Wait TX empty */
    USART1->DR = c;
}

void uart1_send_str(const char *s)
{
    while (*s) { uart1_send_byte((uint8_t)*s++); }
}

uint8_t uart1_recv_byte(void)
{
    while (!(USART1->SR & USART_SR_RXNE)) { __NOP(); } /* Wait RX not empty */
    return (uint8_t)(USART1->DR & 0xFFU);
}
```

---

## Pattern 4: SysTick Timebase Without RTOS

```c
static volatile uint32_t s_ticks = 0U;

/* Call once after SystemInit: generates 1ms tick */
void systick_init(void)
{
    SysTick->LOAD = SystemCoreClock / 1000U - 1U;  /* Reload for 1ms */
    SysTick->VAL  = 0U;                             /* Clear current */
    SysTick->CTRL = SysTick_CTRL_CLKSOURCE_Msk      /* Processor clock */
                  | SysTick_CTRL_TICKINT_Msk         /* Enable interrupt */
                  | SysTick_CTRL_ENABLE_Msk;         /* Start counter   */
}

void SysTick_Handler(void) { s_ticks++; }

uint32_t millis(void) { return s_ticks; }

void delay_ms(uint32_t ms)
{
    uint32_t t = millis();
    while ((millis() - t) < ms) { __WFI(); }
}
```

---

## Pattern 5: Interrupt-Driven UART RX Ring Buffer

```c
#define RX_BUF_SIZE 64U

static volatile uint8_t  s_rx_buf[RX_BUF_SIZE];
static volatile uint32_t s_rx_head = 0U;
static volatile uint32_t s_rx_tail = 0U;

void USART1_IRQHandler(void)
{
    if (USART1->SR & USART_SR_RXNE) {
        uint8_t c = (uint8_t)(USART1->DR & 0xFFU);  /* Read clears RXNE */
        uint32_t next = (s_rx_head + 1U) % RX_BUF_SIZE;
        if (next != s_rx_tail) {     /* Drop on overflow rather than corrupt */
            s_rx_buf[s_rx_head] = c;
            s_rx_head = next;
        }
    }
    if (USART1->SR & USART_SR_ORE) {
        (void)USART1->DR;            /* Read DR to clear overrun */
    }
}

int uart1_getchar(uint8_t *out)
{
    if (s_rx_tail == s_rx_head) { return 0; }   /* Empty */
    *out = s_rx_buf[s_rx_tail];
    s_rx_tail = (s_rx_tail + 1U) % RX_BUF_SIZE;
    return 1;
}
```

Enable RXNE interrupt in init: `USART1->CR1 |= USART_CR1_RXNEIE;`

---

## Pattern 6: Linker Script Sections and Map File Reading

After building, check section sizes:

```bash
# Total flash and SRAM usage
arm-none-eabi-size -A firmware.elf

# Example output:
#   section      size        addr
#   .isr_vector   268  134217728    <- 0x08000000
#   .text        8432  134218012
#   .data          84  536870912    <- 0x20000000
#   .bss          120  536870996
#   Total:       8904

# Identify the 10 largest functions
arm-none-eabi-nm --print-size --size-sort -td firmware.elf | tail -10
```

To place a buffer in CCM RAM (Cortex-M4 Core Coupled Memory, fastest SRAM, no DMA access):

```c
__attribute__((section(".ccm")))
static uint8_t s_fft_buffer[4096];
```

Add `.ccm` section in linker script targeting the CCM MEMORY region.

---

## Pattern 7: Weak Default ISR Handlers

All unused interrupt vectors should point to a default handler that traps for debugging:

```c
/* Weak alias: if the real handler is not defined, this version is used */
__attribute__((weak, alias("Default_Handler")))
void NMI_Handler(void);

__attribute__((weak, alias("Default_Handler")))
void HardFault_Handler(void);

/* Trap: breakpoint in debugger will stop here */
__attribute__((noreturn))
void Default_Handler(void)
{
    __disable_irq();
    for (;;) { __BKPT(0); }
}
```

---

## Anti-Patterns

- **Read-modify-write on GPIO ODR from ISR**: use BSRR instead. `ODR ^= pin` is not atomic.
- **Missing clock enable before peripheral register write**: writes to disabled peripheral clock domain have no effect (or cause bus fault on some MCUs).
- **`int` for register fields**: use `uint32_t`. Sign extension on bit-field extraction causes subtle bugs.
- **Polling UART without timeout**: locks the MCU forever on hardware fault. Add cycle-count timeout.
- **`-O0` in production**: debugging builds only. Production must use `-Os` or `-O2` with size verification.

## References

- STM32F4 Reference Manual RM0090 (register definitions)
- GNU LD Manual: https://sourceware.org/binutils/docs/ld/
- ARM AAPCS: IHI0042F
- Joseph Yiu, "The Definitive Guide to ARM Cortex-M3 and Cortex-M4 Processors"

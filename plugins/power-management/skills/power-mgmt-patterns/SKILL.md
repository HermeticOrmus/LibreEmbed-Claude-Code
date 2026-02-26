# power-mgmt-patterns

## Knowledge Base

Power management patterns for battery-operated embedded systems.

---

## Pattern 1: Sleep Entry Checklist

Before entering Stop/Standby mode, complete these steps in order:

```c
void prepare_for_stop2(void)
{
    /* 1. Complete all pending DMA transfers */
    HAL_DMA_Abort(&hdma_spi1_tx);

    /* 2. Flush UART TX buffer */
    while (!LL_USART_IsActiveFlag_TC(USART2)) {}

    /* 3. Disable peripheral clocks */
    __HAL_RCC_SPI1_CLK_DISABLE();
    __HAL_RCC_USART2_CLK_DISABLE();
    __HAL_RCC_ADC1_CLK_DISABLE();

    /* 4. Configure unused GPIOs as analog (lowest leakage) */
    GPIO_InitTypeDef gpio = {
        .Mode = GPIO_MODE_ANALOG, .Pull = GPIO_NOPULL,
        .Pin  = GPIO_PIN_2 | GPIO_PIN_3   /* Unused pins on GPIOB */
    };
    HAL_GPIO_Init(GPIOB, &gpio);

    /* 5. Configure wake-up: EXTI0 (PA0) falling edge */
    HAL_EXTI_GetHandle(&hexti0, EXTI_LINE_0);
    /* EXTI already configured; just ensure it's enabled */

    /* 6. Enter Stop 2 */
    HAL_PWREx_EnterSTOP2Mode(PWR_STOPENTRY_WFI);

    /* 7. After wake: restore clocks */
    SystemClock_Config();
    MX_USART2_UART_Init();
    MX_SPI1_Init();
}
```

---

## Pattern 2: RTC Alarm Wake-Up

Wake MCU at a specific time or after an interval using the RTC alarm.

```c
void rtc_set_wakeup_interval(uint32_t seconds)
{
    HAL_RTCEx_DeactivateWakeUpTimer(&hrtc);

    /* RTCCLK = LSE 32.768kHz, prescaler = 16 → 2048Hz */
    /* WUTR reload value = seconds * 2048 */
    HAL_RTCEx_SetWakeUpTimer_IT(&hrtc,
        seconds * 2048U - 1U,
        RTC_WAKEUPCLOCK_RTCCLK_DIV16);
}

void HAL_RTCEx_WakeUpTimerEventCallback(RTC_HandleTypeDef *hrtc)
{
    /* Woke from RTC: take sensor reading */
    schedule_sensor_read();
}

/* Usage: wake every 60 seconds */
void setup_periodic_wakeup(void)
{
    rtc_set_wakeup_interval(60U);
    prepare_for_stop2();
}
```

---

## Pattern 3: GPIO Leakage Prevention

Floating GPIO inputs near the logic threshold (VCC/2) draw up to 1mA per pin.

```c
/* Set all unused GPIO pins to analog mode (0 leakage) */
void gpio_minimize_leakage(void)
{
    /* Enable all GPIO clocks before configuring */
    __HAL_RCC_GPIOA_CLK_ENABLE();
    __HAL_RCC_GPIOB_CLK_ENABLE();
    __HAL_RCC_GPIOC_CLK_ENABLE();

    GPIO_InitTypeDef analog = {
        .Mode = GPIO_MODE_ANALOG,
        .Pull = GPIO_NOPULL,
        .Speed = GPIO_SPEED_FREQ_LOW,
    };

    /* Configure all pins as analog; specific pins will be re-initialized by peripherals */
    analog.Pin = GPIO_PIN_All;
    HAL_GPIO_Init(GPIOA, &analog);
    HAL_GPIO_Init(GPIOB, &analog);
    HAL_GPIO_Init(GPIOC, &analog);

    /* Now initialize peripheral pins (UART, SPI, I2C, LED) */
    MX_GPIO_Init();         /* Your CubeMX-generated init */
    MX_USART2_UART_Init();
    /* etc. */
}
```

---

## Pattern 4: Power Budget Spreadsheet Format

```
Component         | Active (mA) | Duration (ms) | Sleep (µA) | Interval (s)
MCU (STM32L4)    | 8.0         | 100           | 2.0        | 60
RF (nRF24L01+)   | 11.3        | 50            | 0.9        | 60
Sensor (BME280)   | 0.7         | 20            | 0.1        | 60
Regulator (quiescent) | 0.030   | -             | 0.030      | -

Average current =
  (8.0 * 0.1 + 11.3 * 0.05 + 0.7 * 0.02 + 0.030 * 60) / 60 + 3.0 * 0.001
  = (0.8 + 0.565 + 0.014 + 1.8) / 60 + 0.003
  = 3.179 / 60 + 0.003 = 0.056 mA = 56 µA average

CR2032 (220mAh): 220 / 0.056 = 3928 hours = 164 days ≈ 5 months
```

---

## Pattern 5: FreeRTOS Tickless Idle with LPTIM

```c
/* portmacro.h or port.c: override tickless idle */
#define portSUPPRESS_TICKS_AND_SLEEP(x) vApplicationSleep(x)

void vApplicationSleep(TickType_t xExpectedIdleTime)
{
    /* Prevent OS entering tickless if a task is about to become ready */
    if (eTaskConfirmSleepModeStatus() == eAbortSleep) { return; }

    /* Calculate sleep duration */
    uint32_t sleep_ms = xExpectedIdleTime * portTICK_PERIOD_MS;
    if (sleep_ms < 2U) { __WFI(); return; }  /* Too short: simple WFI */

    /* Configure LPTIM1 oneshot for sleep_ms */
    lptim1_start_oneshot_ms(sleep_ms);

    /* Disable SysTick during Stop */
    SysTick->CTRL &= ~SysTick_CTRL_ENABLE_Msk;

    HAL_PWREx_EnterSTOP2Mode(PWR_STOPENTRY_WFI);

    /* Woken: restore clocks, compute actual elapsed */
    SystemClock_Config();
    uint32_t actual_ms = lptim1_get_elapsed_ms();
    TickType_t ticks = actual_ms / portTICK_PERIOD_MS;
    vTaskStepTick(ticks);

    SysTick->CTRL |= SysTick_CTRL_ENABLE_Msk;
}
```

---

## Anti-Patterns

- **Entering Stop mode with SysTick running**: SysTick interrupt fires and wakes the MCU every 1ms, defeating sleep.
- **Not restoring the PLL after Stop mode exit**: Stop mode switches to MSI/HSI; PLL must be reconfigured or peripherals run at wrong speed.
- **Using delay loops during sleep**: HAL_Delay uses SysTick; use RTC or LPTIM for sleep timing.
- **Not measuring with the actual battery**: DCDC efficiency drops at low current; lab bench supply ≠ coin cell behavior.

## References

- STM32L4 Reference Manual RM0351, Chapter 5 (Power Control)
- Nordic Semiconductor Infocenter: Power management for nRF52 series
- AN4621 (ST): STM32L4xx ultra-low-power features
- FreeRTOS tickless idle: freertos.org/low-power-tickless-rtos.html

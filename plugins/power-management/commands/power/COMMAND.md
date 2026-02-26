# /power

Power management command: sleep mode configuration, power budget, measurement, optimization.

## Trigger

`/power <action> [options]`

## Actions

### `analyze`
Analyze power consumption from a power profile or estimate from code.

```
/power analyze --mcu stm32l476 --active-current 8mA --active-ms 100 --interval-s 60
/power analyze --battery cr2032 --target-days 365
```

### `configure`
Generate sleep mode entry/exit code.

```
/power configure --mcu stm32l476 --mode stop2 --wakeup exti --pin PA0
/power configure --mcu stm32l476 --mode stop2 --wakeup rtc --interval 60s
/power configure --mcu nrf52840 --mode system-on-lp --wakeup gpio
```

### `measure`
Generate measurement setup and current calculation guide.

```
/power measure --tool ppk2 --target nrf52840-dk
/power measure --tool jlink-energy --target stm32-nucleo
/power measure --tool shunt --resistance 100ohm
```

### `optimize`
Analyze firmware for power anti-patterns.

```
/power optimize --source src/ --find "polling loops,floating gpio,unused peripherals"
```

## Process

1. Define active profile: duration, current, frequency.
2. Define sleep current: measure with PPK2 or estimate from datasheet.
3. Calculate average current.
4. Divide battery capacity by average current for lifetime.
5. Identify and eliminate the largest current consumers.

## Output Examples

### Stop2 entry/exit with RTC alarm
```c
/* Complete entry sequence */
void go_to_sleep_for_ms(uint32_t ms)
{
    /* Disable unnecessary clocks */
    __HAL_RCC_SPI2_CLK_DISABLE();
    __HAL_RCC_USART1_CLK_DISABLE();

    /* Set RTC wakeup */
    HAL_RTCEx_SetWakeUpTimer_IT(&hrtc, ms * 2 / 1000,
                                 RTC_WAKEUPCLOCK_RTCCLK_DIV2);

    /* Enter Stop 2 */
    HAL_PWREx_EnterSTOP2Mode(PWR_STOPENTRY_WFI);

    /* Wake: restore clock, re-init peripherals */
    HAL_RTCEx_DeactivateWakeUpTimer(&hrtc);
    SystemClock_Config();
    __HAL_RCC_SPI2_CLK_ENABLE();
    __HAL_RCC_USART1_CLK_ENABLE();
}
```

### Battery lifetime calculation
```
CR2032: 220 mAh, 3.0V
Active: 12 mA for 80ms every 30s (sensor + BLE advertising)
Sleep:  1.8 µA in Stop 2

Duty cycle: 80ms / 30000ms = 0.00267
Avg current: 12 * 0.00267 + 0.0018 * 0.99733 = 0.0320 + 0.0018 = 0.0338 mA

Lifetime: 220 / 0.0338 = 6509 hours = 271 days
```

## Error Handling

- "MCU wakes immediately from Stop" — SysTick not disabled, or pending EXTI; check all enabled interrupts
- "PLL not locked after wake-up" — SystemClock_Config not called after Stop exit; MSI running at 4MHz
- "Higher than expected sleep current" — floating GPIO or enabled peripheral clock; use PPK2 to baseline
- "RTC alarm fires too early" — RTC prescaler mismatch with LSE frequency; verify PREDIV_S and PREDIV_A

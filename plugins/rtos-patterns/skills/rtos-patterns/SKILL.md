# rtos-patterns

## Knowledge Base

FreeRTOS and Zephyr patterns for production embedded firmware.

---

## Pattern 1: Producer/Consumer with Queue and Backpressure

```c
/* Queue with bounded backpressure: producer blocks if consumer falls behind */
#define Q_DEPTH 8U

static QueueHandle_t s_adc_queue;

typedef struct { uint16_t raw[8]; uint32_t ts_ms; } adc_sample_t;

/* Producer: ADC sampling task at 100Hz */
void adc_task(void *arg)
{
    s_adc_queue = xQueueCreate(Q_DEPTH, sizeof(adc_sample_t));

    for (;;) {
        adc_sample_t s;
        s.ts_ms = get_tick_ms();
        adc_read_all_channels(s.raw);

        /* Block 5ms max. If queue full for >5ms, consumer is too slow. */
        if (xQueueSend(s_adc_queue, &s, pdMS_TO_TICKS(5)) != pdTRUE) {
            metrics_increment(METRIC_ADC_QUEUE_OVERFLOW);
        }
        vTaskDelayUntil(&s_last_wake, pdMS_TO_TICKS(10)); /* Precise 100Hz */
    }
}

/* Consumer: data processing task */
void processing_task(void *arg)
{
    adc_sample_t s;
    for (;;) {
        xQueueReceive(s_adc_queue, &s, portMAX_DELAY);
        process_adc_sample(&s);
    }
}
```

---

## Pattern 2: Mutex-Protected Shared Resource

```c
typedef struct {
    I2C_HandleTypeDef *hi2c;
    SemaphoreHandle_t  mutex;
} i2c_bus_t;

static i2c_bus_t s_i2c1;

void i2c_bus_init(i2c_bus_t *bus, I2C_HandleTypeDef *hi2c)
{
    bus->hi2c  = hi2c;
    bus->mutex = xSemaphoreCreateMutex();
    configASSERT(bus->mutex != NULL);
}

bool i2c_write_reg(i2c_bus_t *bus, uint8_t addr, uint8_t reg, uint8_t val)
{
    if (xSemaphoreTake(bus->mutex, pdMS_TO_TICKS(50)) != pdTRUE) {
        return false;   /* Bus busy for >50ms: timeout */
    }
    uint8_t buf[2] = { reg, val };
    HAL_StatusTypeDef s = HAL_I2C_Master_Transmit(
        bus->hi2c, addr << 1, buf, 2, 10);
    xSemaphoreGive(bus->mutex);
    return s == HAL_OK;
}
```

---

## Pattern 3: FreeRTOS Config Settings

Critical `FreeRTOSConfig.h` settings for production:

```c
/* Scheduler */
#define configCPU_CLOCK_HZ           168000000UL
#define configTICK_RATE_HZ           1000UL          /* 1ms tick */
#define configMAX_PRIORITIES         10U
#define configUSE_PREEMPTION         1
#define configUSE_TIME_SLICING       1

/* Memory */
#define configTOTAL_HEAP_SIZE        ((size_t)(32 * 1024))
#define configSUPPORT_STATIC_ALLOCATION  1
#define configSUPPORT_DYNAMIC_ALLOCATION 1

/* Debug */
#define configCHECK_FOR_STACK_OVERFLOW   2       /* Enable stack check */
#define configUSE_MALLOC_FAILED_HOOK     1
#define configASSERT(x) do { if(!(x)) { taskDISABLE_INTERRUPTS(); for(;;){} } } while(0)

/* Hooks */
#define configUSE_IDLE_HOOK              1       /* Power management in idle */
#define configUSE_TICK_HOOK              0

/* Cortex-M interrupt priorities */
#define configKERNEL_INTERRUPT_PRIORITY         (0xF0U)  /* Lowest priority */
#define configMAX_SYSCALL_INTERRUPT_PRIORITY    (0x50U)  /* Syscall ceiling */
```

---

## Pattern 4: Stack Overflow Hook

```c
/* Called by FreeRTOS when configCHECK_FOR_STACK_OVERFLOW = 2 */
void vApplicationStackOverflowHook(TaskHandle_t xTask, char *pcTaskName)
{
    /* Capture task name before stack is more corrupted */
    char name_copy[configMAX_TASK_NAME_LEN + 1];
    strncpy(name_copy, pcTaskName, configMAX_TASK_NAME_LEN);
    name_copy[configMAX_TASK_NAME_LEN] = '\0';

    /* Log via ITM (doesn't use task stack) */
    ITM_print("STACK OVERFLOW: ");
    ITM_print(name_copy);

    /* Trap */
    taskDISABLE_INTERRUPTS();
    for (;;) { __BKPT(0); }
}
```

---

## Pattern 5: Rate Monotonic Priority Assignment

Rate Monotonic (RM) theorem: assign priority inversely to period. Shorter period = higher priority.

```
Task         | Period | Priority | CPU util | Deadline
sensor_read  | 10ms   | 9 (high) | 5%       | 10ms
filter       | 20ms   | 8        | 10%      | 20ms
control_loop | 20ms   | 7        | 8%       | 20ms
comm_send    | 100ms  | 5        | 15%      | 100ms
display      | 200ms  | 3        | 5%       | 200ms
logging      | 1000ms | 1 (low)  | 2%       | 1000ms

Total CPU: 45% < RM bound for 6 tasks: n(2^(1/n)-1) = 6*(2^(1/6)-1) = 73.5%
Schedulable: YES
```

For deadline-based: assign priority by earliest deadline (EDF), but RM is simpler to implement with static priorities.

---

## Anti-Patterns

- **Calling `vTaskDelay` from ISR**: `vTaskDelay` is a task API. ISRs must use `FromISR` variants only.
- **Using binary semaphore as mutex**: no priority inheritance — causes priority inversion under concurrent access.
- **Creating tasks inside an ISR**: `xTaskCreate` uses heap (may block). Create all tasks before starting the scheduler.
- **Blocking forever in idle task hook**: the idle hook must return. Use `__WFI()` for sleep, not a loop with conditions.

## References

- FreeRTOS API: freertos.org/a00104.html
- Richard Barry, "Mastering the FreeRTOS Real Time Kernel" (free PDF, freertos.org)
- Rate Monotonic Scheduling: Liu and Layland, 1973
- Zephyr RTOS: docs.zephyrproject.org

# memory-mgmt-patterns

## Knowledge Base

Embedded memory management patterns for deterministic, fragmentation-free firmware.

---

## Pattern 1: Static FreeRTOS Objects

Avoid dynamic allocation for RTOS objects. All objects pre-allocated at compile time.

```c
/* Static task */
static StackType_t  s_sensor_stack[256];
static StaticTask_t s_sensor_tcb;
static TaskHandle_t s_sensor_handle;

/* Static queue: 8 messages of 16 bytes each */
static uint8_t          s_queue_storage[8 * 16];
static StaticQueue_t    s_queue_struct;
static QueueHandle_t    s_queue;

/* Static semaphore */
static StaticSemaphore_t s_sem_struct;
static SemaphoreHandle_t s_sem;

void rtos_objects_create(void)
{
    s_sensor_handle = xTaskCreateStatic(
        sensor_task, "sensor",
        256U, NULL, TASK_PRIO_SENSOR,
        s_sensor_stack, &s_sensor_tcb);
    configASSERT(s_sensor_handle != NULL);

    s_queue = xQueueCreateStatic(8, 16, s_queue_storage, &s_queue_struct);
    configASSERT(s_queue != NULL);

    s_sem = xSemaphoreCreateBinaryStatic(&s_sem_struct);
    configASSERT(s_sem != NULL);
}
```

Required in `FreeRTOSConfig.h`: `configSUPPORT_STATIC_ALLOCATION 1`.

---

## Pattern 2: Memory Pool for Variable-Frequency Messages

When messages arrive at variable rate, a pool prevents heap fragmentation:

```c
/* Message pool: 32 messages, 128 bytes each */
typedef struct {
    uint8_t  data[120];
    uint8_t  len;
    uint8_t  type;
    uint16_t seq;
} msg_t;

#define MSG_POOL_SIZE 32U
static msg_t      s_msg_pool[MSG_POOL_SIZE];
static uint32_t   s_pool_used_mask = 0U;  /* Bitmask: bit N = msg N is in use */

msg_t *msg_alloc(void)
{
    taskENTER_CRITICAL();
    for (uint32_t i = 0; i < MSG_POOL_SIZE; i++) {
        if (!(s_pool_used_mask & (1U << i))) {
            s_pool_used_mask |= (1U << i);
            taskEXIT_CRITICAL();
            return &s_msg_pool[i];
        }
    }
    taskEXIT_CRITICAL();
    return NULL;  /* Pool exhausted: caller must handle */
}

void msg_free(msg_t *m)
{
    uint32_t idx = (uint32_t)(m - s_msg_pool);
    configASSERT(idx < MSG_POOL_SIZE);
    taskENTER_CRITICAL();
    s_pool_used_mask &= ~(1U << idx);
    taskEXIT_CRITICAL();
}
```

---

## Pattern 3: Heap Statistics Monitoring

```c
/* Log heap stats periodically for detecting slow leak */
void heap_monitor_task(void *param)
{
    (void)param;
    HeapStats_t stats;

    for (;;) {
        vPortGetHeapStats(&stats);

        char buf[128];
        snprintf(buf, sizeof(buf),
            "HEAP free=%lu min=%lu blocks=%lu",
            (unsigned long)stats.xAvailableHeapSpaceInBytes,
            (unsigned long)stats.xMinimumEverFreeBytesRemaining,
            (unsigned long)stats.xNumberOfFreeBlocks);
        log_info(buf);

        /* Alert if heap falls below 2KB */
        if (stats.xAvailableHeapSpaceInBytes < 2048U) {
            log_error("HEAP LOW");
        }

        vTaskDelay(pdMS_TO_TICKS(30000));  /* Every 30 seconds */
    }
}
```

`xMinimumEverFreeBytesRemaining` is the all-time low-water mark — use it for sizing.

---

## Pattern 4: Stack High-Water Mark Audit

```c
/* Call from a debug task or startup once system is stable */
void task_stack_audit(void)
{
    typedef struct {
        const char  *name;
        TaskHandle_t handle;
        uint32_t     min_expected_words;
    } task_entry_t;

    const task_entry_t tasks[] = {
        { "sensor",  s_sensor_handle,  32U },
        { "comm",    s_comm_handle,    64U },
        { "display", s_display_handle, 48U },
    };

    for (uint32_t i = 0; i < sizeof(tasks)/sizeof(tasks[0]); i++) {
        UBaseType_t hwm = uxTaskGetStackHighWaterMark(tasks[i].handle);
        if (hwm < tasks[i].min_expected_words) {
            /* Stack is close to overflow: increase allocation */
            configASSERT(0);  /* Break in debugger */
        }
    }
}
```

---

## Pattern 5: Placing Arrays in Specific SRAM Regions

```c
/* STM32F4: CCM RAM (0x10000000, 64KB) — no DMA access, CPU-only, fastest */
__attribute__((section(".ccm")))
static float s_fft_buffer[1024];   /* 4KB in CCM */

/* STM32F4: SRAM2 (0x2001C000, 16KB) — DMA-accessible backup */
__attribute__((section(".sram2")))
static uint8_t s_dma_rx_buf[4096];

/* Core-coupled memory for FreeRTOS idle task stack (avoids main SRAM contention) */
__attribute__((section(".ccm")))
static StackType_t s_idle_stack[configMINIMAL_STACK_SIZE];
```

Requires corresponding sections in linker script targeting the CCM/SRAM2 MEMORY regions.

---

## Anti-Patterns

- **Calling `malloc` in ISR**: `malloc` is not reentrant and not interrupt-safe. Use a pool.
- **Not checking `pvPortMalloc` return value**: returns NULL on heap exhaustion. Dereferencing NULL = HardFault.
- **Single heap_4 spanning all SRAM**: if DMA buffers and task stacks share one heap, a DMA overrun can corrupt task stacks silently.
- **Stack too small with `printf`**: `printf` with float formatting (`%f`) uses ~1KB of stack. Use integer formatting in embedded code.

## References

- FreeRTOS Heap: freertos.org/a00111.html
- ARM MPU: ARM Cortex-M4 Generic User Guide, Chapter 4.5
- FreeRTOS `uxTaskGetStackHighWaterMark`: freertos.org/uxTaskGetStackHighWaterMark.html

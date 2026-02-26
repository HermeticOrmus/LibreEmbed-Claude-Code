# /rtos

FreeRTOS task design, synchronization, and analysis command.

## Trigger

`/rtos <action> [options]`

## Actions

### `design`
Design a task architecture from a list of system functions.

```
/rtos design --functions "sensor-read,filter,control,comms,display,logging"
/rtos design --functions "adc,uart-rx,protocol,ui" --priority-method rm
```

Outputs: task table (name, priority, stack, period), queue/semaphore/mutex diagram.

### `create`
Generate task, queue, and synchronization code.

```
/rtos create --task sensor --period 100ms --queue adc_reading --depth 8
/rtos create --mutex i2c_bus --shared-by "sensor,display"
/rtos create --event-group startup --bits "sensor,comm,config"
```

### `debug`
Diagnose a FreeRTOS issue.

```
/rtos debug --symptom "task starved"
/rtos debug --symptom "deadlock between task1 and task2"
/rtos debug --symptom "HardFault in ISR"
/rtos debug --cfsr 0x02000000
```

### `analyze`
Analyze a FreeRTOS configuration for issues.

```
/rtos analyze --config FreeRTOSConfig.h
/rtos analyze --priorities "sensor=9,comm=5,display=3" --check-inversion
```

## Process

1. List all concurrent activities in the system.
2. Group into tasks by period or event source.
3. Assign priorities using Rate Monotonic (by period) or deadline.
4. Identify shared resources: assign mutex per resource.
5. Identify ISR → task signals: assign binary semaphore or task notification.
6. Size queues: queue_depth = max_burst_rate / consumer_rate * 1.5 (50% headroom).

## Output Examples

### Minimal FreeRTOS task scaffold
```c
/* sensor_task.c */
#define SENSOR_TASK_STACK  256U
#define SENSOR_TASK_PRIO   9U

static StackType_t  s_stack[SENSOR_TASK_STACK];
static StaticTask_t s_tcb;
static TaskHandle_t s_handle;

static void sensor_task_fn(void *arg)
{
    (void)arg;
    TickType_t last_wake = xTaskGetTickCount();

    for (;;) {
        sensor_reading_t r;
        r.temp_mC = sensor_read_temperature();
        r.ts_ms   = pdTICKS_TO_MS(xTaskGetTickCount());

        xQueueSend(q_sensor_out, &r, 0);  /* Non-blocking send */

        vTaskDelayUntil(&last_wake, pdMS_TO_TICKS(100));
    }
}

void sensor_task_start(void)
{
    s_handle = xTaskCreateStatic(sensor_task_fn, "sensor",
                                  SENSOR_TASK_STACK, NULL,
                                  SENSOR_TASK_PRIO, s_stack, &s_tcb);
    configASSERT(s_handle != NULL);
}
```

### Priority check using vTaskList
```c
/* In debug build: print all task states */
void rtos_print_task_list(void)
{
    char buf[512];
    vTaskList(buf);
    printf("Name\t\tState\tPrio\tStack\tNum\n%s\n", buf);
    /* State: R=Ready, B=Blocked, S=Suspended, D=Deleted */
}
```

## Error Handling

- "xQueueSend returned pdFALSE immediately" — queue full; increase depth or increase consumer priority
- "Task never runs" — lower-priority task starving; check for a higher-priority task spinning without yielding
- "Deadlock: task1 and task2 both blocked" — mutual lock acquisition in different order; always acquire locks in same global order
- "Mutex not released" — task that holds mutex was deleted or vTaskSuspend called while holding; never suspend while holding mutex

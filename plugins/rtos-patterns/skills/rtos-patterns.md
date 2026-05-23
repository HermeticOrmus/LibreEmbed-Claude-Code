# RTOS patterns library

Reference patterns for FreeRTOS + Zephyr task design. Use as a lookup when designing or reviewing RTOS firmware.

## Priority inversion taxonomy

Three forms exist; the agent distinguishes them:

### 1. Unbounded priority inversion (the bad one)

H blocks on resource R held by L. M (between H and L in priority) preempts L. H is now blocked for as long as M runs — unbounded.

**Fix**: priority inheritance (FreeRTOS mutex, Zephyr mutex) OR priority ceiling (declare R's ceiling = highest task that ever uses R).

### 2. Bounded priority inversion

H blocks on R held by L. L holds R for time T. H is delayed by T. T is bounded if L's critical section is bounded.

**Fix**: ensure L's critical section is short and bounded. Don't sleep, don't block, don't make long calls while holding R.

### 3. Chain blocking

H blocks on R1 held by L1. L1 blocks on R2 held by L2. H is delayed by L2's critical section + L1's critical section.

**Fix**: priority ceiling protocol on R1 + R2 (every holder runs at the highest possible blocker priority). Or use a single mutex / message passing.

## Deferred interrupt processing (DIP) pattern

When an ISR has work that exceeds "set a flag, post a semaphore":

```c
// ISR — minimal work
void EXTI9_5_IRQHandler(void) {
    __HAL_GPIO_EXTI_CLEAR_IT(GPIO_PIN_5);
    BaseType_t pxHigherPriorityTaskWoken = pdFALSE;
    vTaskNotifyGiveFromISR(SensorTaskHandle, &pxHigherPriorityTaskWoken);
    portYIELD_FROM_ISR(pxHigherPriorityTaskWoken);
}

// Task — the heavy work
void SensorTask(void *params) {
    for (;;) {
        ulTaskNotifyTake(pdTRUE, portMAX_DELAY);
        // ISR triggered me. Now do the heavy work in task context where I can:
        //  - Call non-ISR-safe HAL functions
        //  - Take mutexes
        //  - Call printf
        //  - Run for milliseconds without harming ISR latency
        process_sensor_event();
    }
}
```

Use direct-to-task notification (FreeRTOS) or `k_sem_give` from ISR (Zephyr) for lowest-latency DIP.

## Watchdog kick patterns

### Pattern 1: Single low-priority kicker

```c
void WatchdogKickerTask(void *params) {
    for (;;) {
        HAL_IWDG_Refresh(&hiwdg);
        vTaskDelay(pdMS_TO_TICKS(IWDG_TIMEOUT_MS / 2));
    }
}
```

Catches: total system hang.
Misses: single-task hang.

### Pattern 2: Heartbeat aggregator

```c
static volatile uint32_t task_heartbeats[NUM_TASKS];

void TaskA(void *params) {
    for (;;) {
        // Do work
        task_heartbeats[TASK_A] = xTaskGetTickCount();
    }
}

void WatchdogTask(void *params) {
    for (;;) {
        bool all_alive = true;
        TickType_t now = xTaskGetTickCount();
        for (int i = 0; i < NUM_TASKS; i++) {
            if (now - task_heartbeats[i] > TASK_TIMEOUT[i]) {
                all_alive = false;
            }
        }
        if (all_alive) {
            HAL_IWDG_Refresh(&hiwdg);
        }
        vTaskDelay(pdMS_TO_TICKS(IWDG_TIMEOUT_MS / 4));
    }
}
```

Catches: single-task hang (any task that doesn't post heartbeat in its expected window).
Misses: deadlock where all tasks post heartbeats but make no real progress.

### Pattern 3: Window watchdog (WWDG)

Hardware that resets if kicked **too soon**. Catches runaway loops that fire kicks too often.

Use when: code paths exist where a loop might erroneously kick the watchdog repeatedly.

## Mutex vs. semaphore decision

Picking the wrong primitive is a common bug source.

| Use case | Primitive |
|---|---|
| Protect shared mutable state | Mutex (with priority inheritance) |
| Resource counting (N units) | Counting semaphore |
| Signal "event happened" from ISR to task | Binary semaphore or direct task notification |
| Producer-consumer with data | Queue or stream buffer |
| Multiple tasks wait for one of N events | Event group |
| One-shot "system initialized" broadcast | Event group with all-tasks-set pattern |

Critical: **don't use a counting semaphore as a mutex**. Counting semaphores don't have priority inheritance in FreeRTOS. Mutex is what you want for mutual exclusion.

## Stack-size sizing recipe

1. Build with `-fstack-usage`. Per-function stack usage lands in `.su` files next to each `.o`.
2. Walk the call graph from each task's entry point. Sum the deepest path.
3. Add the worst-case ISR preemption stack — sum of ALL ISR stack usages (since any can preempt any task).
4. For Cortex-M with FPU, add 132 bytes for lazy FP stacking on first FP use.
5. Multiply by 1.3 for safety margin. 1.5 if you're not sure about the ISR worst-case.
6. Round up to a nice boundary (multiple of 64 or 128 bytes).

In Zephyr, `CONFIG_THREAD_STACK_INFO=y` lets `k_thread_stack_space_get` report runtime stack high-water marks. Use this in development to validate the sizing.

In FreeRTOS, `uxTaskGetStackHighWaterMark` does the same.

## Task design heuristics

### How many tasks?

The minimum that gives you:

- One task per **truly concurrent activity** (truly = different rates, different deadlines, different blocking patterns)
- Not one task per concept. Two tasks where one would do doubles overhead.
- A separate watchdog/health task — usually warranted even if it could fold into the main loop.

A common over-decomposition: separate tasks for "read sensor" and "process sensor data" when one task can do both. The processing is data-dependent on the read; there's no concurrency to exploit.

### Priority assignment

```
prio 5 (highest): time-critical ISR follower
prio 4:          time-critical worker (e.g., motor control loop)
prio 3:          throughput-critical worker (e.g., data logger)
prio 2:          background steady-state worker (e.g., telemetry)
prio 1:          health / watchdog / housekeeping
prio 0 (lowest): idle (FreeRTOS reserves this)
```

Reserve highest priority for the work that MUST run on time. Don't add tasks at the top of the priority stack without reason — they cost determinism.

### When to use software timers vs. tasks

Software timer (FreeRTOS) / kernel timer (Zephyr): use when:
- The action is short (< 1 ms of work)
- The action doesn't need its own stack
- The action is periodic

Use a task when:
- The action is long
- The action can block
- The action has its own state machine

The timer callback runs in the timer task's context (FreeRTOS) — sharing a stack with other timer callbacks. A long callback delays all other timer callbacks.

## Common mistakes catalog

### "My task isn't running"

Check in order:
1. Did you call `vTaskStartScheduler()` / start the scheduler?
2. Is the task's priority higher than any task that's busy-running?
3. Is the task blocked on something that's never signaled?
4. Did `xTaskCreate` succeed? Check the return code.
5. Is the stack overflowing? Enable `configCHECK_FOR_STACK_OVERFLOW` and provide a hook.

### "System resets randomly"

Check:
1. Watchdog firing — instrument the watchdog hook to log task heartbeats before reset
2. Hard fault — install a fault handler that dumps the LR + PC to UART before reset
3. Stack overflow — enable stack overflow checking
4. Bus fault from invalid pointer — check that DMA buffers haven't been freed or moved

### "Task X works on its own but fails when other tasks are running"

Inversion / starvation. Walk the priority graph.

### "ISR latency too long"

- Don't `printf` in an ISR.
- Don't take mutexes in an ISR (technically illegal; will assert in debug builds).
- Don't do floating-point work in an ISR unless you've configured lazy FP stacking.
- Check if you have nested interrupts disabled (`__disable_irq` in some code path).

### "Memory corruption on shared global"

You're using a shared global without protection. Either:
1. Switch to message passing (queue or stream buffer).
2. Protect with a mutex.
3. If single-writer + single-reader + atomic-size: use `volatile` + memory barriers and pray (only OK for very simple cases).

## Cross-references

- **debug-trace** plugin: when you need to see what's actually happening (ITM, ETM, runtime traces)
- **memory-management** plugin: for stack overflow detection patterns + memory pool design
- **bootloader-design** plugin: for watchdog-triggered recovery semantics
- **safety-critical** plugin: for certifiable RTOS subsets + freedom-from-interference

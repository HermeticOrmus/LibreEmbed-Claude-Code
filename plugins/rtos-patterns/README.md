# RTOS Patterns

> FreeRTOS and Zephyr task design, IPC primitives, synchronization, and the patterns that prevent the embedded systems failure modes nobody catches in code review.

## Overview

Real-time operating systems are not just "scheduler plus mutex." They are an opinionated set of trade-offs between latency, determinism, footprint, and developer ergonomics. Every embedded developer hits the same wall the first time they design a multi-task firmware: priority inversion, queue starvation, watchdog timing, ISR-to-task hand-off. This plugin encodes those patterns as agent expertise so the agent can think alongside you when you're designing task structures, sizing IPC primitives, or debugging why a low-priority task is somehow blocking a high-priority one.

Covered RTOSes:

- **FreeRTOS** — deep. The de-facto small-MCU RTOS. Tasks, queues, semaphores, mutexes (with priority inheritance), event groups, software timers, stream + message buffers, tickless idle, MPU regions.
- **Zephyr** — deep. The modern alternative with strong vendor backing. Threads, work queues, message queues, mailboxes, FIFOs, LIFOs, kernel timers, system work queue vs. dedicated work queues, device tree integration.
- **ThreadX** — moderate. Microsoft's RTOS (formerly Express Logic). Threads, queues, event flags, byte pools, block pools.
- **RT-Thread** — light. Patterns when crossing from FreeRTOS to RT-Thread.

## Contents

### Agents

- **rtos-engineer** -- Senior RTOS specialist who designs task structures, sizes IPC primitives based on actual data rates, identifies priority inversion + starvation risks before they ship, and translates between FreeRTOS and Zephyr conventions. Defaults to skepticism on memory + timing assumptions.

### Commands

- **/rtos** -- Task design + IPC sizing + synchronization recipe. Hand it a problem statement with real numbers (sample rates, data sizes, latency budgets) and it returns a concrete task graph with priorities, IPC primitives, and the reasons behind each choice.

### Skills

- **rtos-patterns** -- Reference library: priority-inversion taxonomy, deferred interrupt processing pattern, watchdog kick patterns, mutex vs. semaphore decision tree, stack-size sizing recipe, common-mistakes catalog.

## Key Capabilities

The rtos-patterns plugin gives you:

- **Task graph design** for problems stated in real-world terms (sample rates, bus throughputs, latency requirements). The agent produces priorities + IPC primitives + reasoning.
- **IPC sizing** that accounts for burst behavior. A queue sized for steady-state will deadlock under burst; the agent sizes for the worst burst the problem statement implies.
- **Priority inversion detection** by walking the mutex acquisition graph in your code or design. Names which task pair will inversion when, and proposes inheritance vs. ceiling fixes.
- **Stack-size analysis** via GCC `-fstack-usage` integration plus per-task safety margin recommendations based on the task's call graph depth.
- **Watchdog pattern selection** — window watchdog vs. independent watchdog, kick from idle vs. kick from heartbeat task, per-task health check pattern, recovery-on-reset semantics.
- **ISR-to-task hand-off** patterns: deferred interrupt processing (DIP), bottom-half handlers, work queue dispatch, message buffer for high-throughput streaming.
- **Cross-RTOS translation** — same problem expressed in FreeRTOS primitives and Zephyr primitives, with the equivalent + non-equivalent constructs called out.

## When to use this plugin

- Designing the task structure for a new firmware
- Choosing between FreeRTOS and Zephyr for a new project (the agent has opinions based on chip, footprint, and team experience)
- Debugging a "task X seems to never run" or "system stalls under load" scenario
- Porting from FreeRTOS to Zephyr or vice versa
- Adding a new task to an existing system without breaking the existing timing budget

## Compatibility

- FreeRTOS v10.x+, including SMP-capable versions on dual-core MCUs (ESP32, RP2040)
- Zephyr v3.x+
- Cortex-M0 through Cortex-M7 (M0+ requires the FreeRTOS Cortex-M0 port, which lacks priority inheritance — the agent will flag this)
- Cortex-A class for Zephyr (limited)
- ESP32 (Xtensa LX6/LX7) via FreeRTOS SMP
- RP2040 dual-core via FreeRTOS SMP or pico-sdk + dual-core APIs

## Limitations the agent will tell you about

- It will not invent timing numbers. If you don't give it a latency budget or sample rate, it will ask.
- It assumes you've measured worst-case ISR duration. If you haven't, it will tell you to.
- It does not analyze your actual code for priority inversion (that requires static analysis tooling — the agent will reference Tracealyzer and Percepio if you need that depth).
- It does not certify your design — safety-critical systems need formal verification, which is what the `safety-critical` plugin is for.

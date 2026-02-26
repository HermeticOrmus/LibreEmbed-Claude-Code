# safety-critical-patterns

## Knowledge Base

MISRA C compliance and safety-critical firmware patterns.

---

## Pattern 1: MISRA C Compliant Type Annotations

MISRA mandates explicit types. Use `<stdint.h>` types throughout.

```c
/* Non-compliant (implicit types): */
int i;
unsigned char flags;

/* MISRA compliant: */
#include <stdint.h>
#include <stdbool.h>

int32_t  i;
uint8_t  flags;
bool     enable;

/* Rule 7.1: Octal constants */
/* VIOLATION: */
uint8_t val = 010;   /* Octal 8, not decimal 10 */
/* COMPLIANT: */
uint8_t val = 0x08U;

/* Rule 7.2: Unsigned constants must have U suffix */
/* VIOLATION: */
uint32_t x = 100;
/* COMPLIANT: */
uint32_t x = 100U;
```

---

## Pattern 2: Single-Exit Function Pattern (Rule 15.5)

MISRA 15.5: a function shall have a single point of exit.

```c
/* NON-COMPLIANT: multiple returns */
int32_t process(uint8_t *buf, uint32_t len)
{
    if (buf == NULL) { return -1; }
    if (len == 0U)   { return -2; }
    /* process */
    return 0;
}

/* COMPLIANT: single exit */
int32_t process(uint8_t *buf, uint32_t len)
{
    int32_t result = 0;

    if (buf == NULL) {
        result = -1;
    } else if (len == 0U) {
        result = -2;
    } else {
        /* process */
        result = 0;
    }

    return result;
}
```

This is advisory in MISRA 2012 (was required in MISRA 2004), but required for DO-178C DAL-A.

---

## Pattern 3: MISRA Suppression Comments

When a violation is justified, document it with a suppression comment and deviation record.

```c
/* MISRA C:2012 Rule 11.5 Deviation:
   Reason: CMSIS HAL requires void* for peripheral handle cast.
   Risk: Low — type verified by HAL layer.
   Reviewed by: J.Smith, 2024-03-15, ref: DEV-2024-011 */
/*lint -e9087 */  /* PC-lint suppression */
void *handle = (void *)&hspi1;   /* PRQA S 0306 */   /* Polyspace suppression */
/*lint +e9087 */
```

Deviation records must be maintained in a deviation log linked to each suppression.

---

## Pattern 4: RAM Test (March-C Algorithm)

March-C tests SRAM integrity at startup (required for IEC 61508 SIL 2+).

```c
/* March-C+ algorithm: detects stuck-at faults, coupling faults */
bool ram_march_c_test(uint32_t *start, uint32_t *end)
{
    volatile uint32_t *p;

    /* Phase 1: write 0 ascending */
    for (p = start; p < end; p++) { *p = 0U; }

    /* Phase 2: read 0, write 1 ascending */
    for (p = start; p < end; p++) {
        if (*p != 0U) { return false; }
        *p = 0xFFFFFFFFU;
    }

    /* Phase 3: read 1, write 0 ascending */
    for (p = start; p < end; p++) {
        if (*p != 0xFFFFFFFFU) { return false; }
        *p = 0U;
    }

    /* Phase 4: read 0, write 1 descending */
    p = end;
    do {
        p--;
        if (*p != 0U) { return false; }
        *p = 0xFFFFFFFFU;
    } while (p > start);

    /* Phase 5: read 1, write 0 descending */
    p = end;
    do {
        p--;
        if (*p != 0xFFFFFFFFU) { return false; }
        *p = 0U;
    } while (p > start);

    /* Phase 6: read 0 */
    for (p = start; p < end; p++) {
        if (*p != 0U) { return false; }
    }

    return true;
}
```

Call from startup before `.bss` zero-fill (test RAM before relying on it).

---

## Pattern 5: Cyclic Redundancy of Critical Data

For data stored in NVM or transmitted over interfaces, verify integrity:

```c
/* CRC-8 of a configuration structure */
uint8_t crc8_compute(const uint8_t *data, uint32_t len)
{
    uint8_t crc = 0xFFU;
    while (len--) {
        crc ^= *data++;
        for (uint8_t i = 0U; i < 8U; i++) {
            crc = (crc & 0x80U) ? ((crc << 1U) ^ 0x07U) : (crc << 1U);
        }
    }
    return crc;
}

typedef struct __attribute__((packed)) {
    uint16_t setpoint_tenths;
    uint8_t  mode;
    uint8_t  flags;
    uint8_t  crc;   /* CRC-8 of previous 4 bytes */
} config_t;

bool config_is_valid(const config_t *cfg)
{
    return cfg->crc == crc8_compute((const uint8_t *)cfg,
                                    sizeof(config_t) - 1U);
}
```

---

## Anti-Patterns

- **Feeding WDT in ISR**: an ISR that fires independently of the application task will keep feeding the WDT even if the main task is deadlocked.
- **Magic numbers without named constants**: Rule 2.4, 2.5, 2.6. All literals must be named constants.
- **`goto` without justification**: MISRA 15.2 permits goto only for forward jumps within same function. Never use for error path unwinding when single-exit applies.
- **`assert` in production code that compiles to nothing with NDEBUG**: safety-critical code must use static_assert or a runtime assertion that does not disappear.

## References

- MISRA C:2012 Third Edition (purchase from misra.org.uk)
- IEC 61508-3:2010 Software requirements
- DO-178C: RTCA Inc.
- IAR EW MISRA checking: https://www.iar.com/knowledge/learn/software-quality/
- PC-lint Plus: https://pclintplus.com/

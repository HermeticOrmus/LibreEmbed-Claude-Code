# /safety

Safety-critical firmware command: MISRA analysis, defensive patterns, watchdog, certification.

## Trigger

`/safety <action> [options]`

## Actions

### `analyze`
Analyze C code for MISRA violations and safety issues.

```
/safety analyze --file src/motor_control.c --ruleset misra-2012
/safety analyze --dir src/ --level required-mandatory --output report.txt
```

### `enforce`
Rewrite a function to be MISRA compliant.

```
/safety enforce --function process_command --rule 15.5
/safety enforce --function set_register --rule 11.3
```

### `report`
Generate a deviation report for a known violation.

```
/safety report --rule 11.5 --file hal_wrapper.c --line 42 --reason "HAL requires void*"
```

### `certify`
Generate a certification evidence checklist.

```
/safety certify --standard iec-61508 --sil 2
/safety certify --standard do-178c --dal B
```

## Process

1. Identify applicable safety standard and required integrity level.
2. Configure static analysis tool with the MISRA ruleset.
3. Run analysis on all source files.
4. Categorize violations: fix immediately (mandatory) or document deviation (required/advisory).
5. Write deviation records for each documented suppression.
6. Verify 100% statement coverage with gcov or Polyspace.

## Output Examples

### cppcheck MISRA check
```bash
# Install: pip install cppcheck (or package manager)
cppcheck --enable=all --std=c11 \
    --addon=misra.json \
    --suppressions-list=misra_suppressions.txt \
    --xml --xml-version=2 \
    src/ 2> misra_report.xml
```

### MISRA deviation log entry
```
Deviation Record: DEV-2024-011
Rule:        MISRA C:2012 Rule 11.5
File:        src/hal_wrapper.c, line 42
Violation:   Cast from void* to SPI_HandleTypeDef*
Justification: STM32 HAL API requires void* parameter. Type is
               verified by handle initialization in MX_SPI1_Init().
Risk:        Low. Type mismatch would cause fault at initialization,
             not silently at runtime.
Test:        TC-HAL-001: SPI loopback test verifies correct operation.
Approved:    J. Smith, 2024-03-15
```

### Safety startup checks
```c
void safety_startup_checks(void)
{
    /* 1. RAM integrity */
    extern uint32_t _sram_test_start, _sram_test_end;
    if (!ram_march_c_test(&_sram_test_start, &_sram_test_end)) {
        safety_fault(FAULT_RAM_TEST_FAIL);
    }

    /* 2. Flash CRC */
    extern uint32_t _flash_crc_stored;
    uint32_t computed = crc32_compute(_flash_start, _flash_size);
    if (computed != _flash_crc_stored) {
        safety_fault(FAULT_FLASH_CORRUPTION);
    }

    /* 3. Stack guard region */
    mpu_protect_stack_bottom((uint32_t)_stack_guard_base);
}
```

## Error Handling

- "MISRA 10.3: essential type category mismatch" — add explicit cast with comment explaining the conversion
- "MISRA 15.5: multiple exit points" — refactor to single-exit with status variable
- "Polyspace: potential overflow on line X" — add range check before arithmetic
- "PC-lint 9087: suspicious pointer-to-pointer conversion" — add suppression comment with deviation record

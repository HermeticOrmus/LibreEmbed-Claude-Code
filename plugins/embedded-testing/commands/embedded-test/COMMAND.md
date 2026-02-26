# /embedded-test

Embedded test command: Unity/CMock unit tests, HIL setup, QEMU emulation, coverage.

## Trigger

`/embedded-test <action> [options]`

## Actions

### `unit`
Generate a Unity test file for a given module.

```
/embedded-test unit --module sensor --hal i2c
/embedded-test unit --module uart_driver --mock hal_uart
/embedded-test unit --module crc32 --no-hardware
```

Generates: `test_<module>.c` with setUp/tearDown, CMock includes, and skeleton test cases.

### `mock`
Generate CMock mock configuration and stubs for hardware headers.

```
/embedded-test mock --header hal_i2c.h --output test/mocks/
/embedded-test mock --header stm32f4xx_hal_spi.h --subset "HAL_SPI_Transmit,HAL_SPI_Receive"
```

### `hil`
Generate Hardware-in-the-Loop test scaffold.

```
/embedded-test hil --target stm32f407 --interface uart --baud 115200
/embedded-test hil --target nrf52840 --interface rtt
```

### `coverage`
Generate coverage report from Ceedling gcov output.

```
/embedded-test coverage --module sensor
/embedded-test coverage --all --threshold 80
```

## Process

1. Identify hardware dependencies in the module under test.
2. Create `i2c_ops_t`-style interface structs for each hardware dependency.
3. Generate CMock mocks from the abstraction headers.
4. Write test file with setUp/tearDown and test cases for normal + error paths.
5. Run `ceedling test:<module>` and fix failures.
6. Add gcov and check coverage with `ceedling gcov:<module>`.

## Output Examples

### Minimal Ceedling test
```c
#include "unity.h"
#include "mock_hal_i2c.h"
#include "sensor.h"

void setUp(void)    { sensor_reset_state(); }
void tearDown(void) {}

void test_sensor_who_am_i_passes_on_valid_id(void)
{
    uint8_t expected_id = 0x60;
    hal_i2c_read_reg_ExpectAndReturn(SENSOR_ADDR, REG_WHO_AM_I,
                                     NULL, 1, HAL_OK);
    hal_i2c_read_reg_ReturnThruPtr_buf(&expected_id);

    TEST_ASSERT_EQUAL(SENSOR_OK, sensor_verify_id());
}
```

### QEMU test runner
```bash
qemu-system-arm -machine mps2-an385 -cpu cortex-m3 \
  -kernel build/test/test_sensor.elf \
  -semihosting-config enable=on,target=native \
  -nographic 2>&1 | tee test_results.txt
grep -E "PASS|FAIL|OK" test_results.txt
```

## Error Handling

- "undefined reference to mock_X" — CMock not added to Ceedling source paths; check `project.yml :paths :test`
- "Called fewer times than expected" — some `_Expect` was not triggered; trace which function was skipped
- "QEMU: ELF machine type mismatch" — wrong QEMU machine for the binary's CPU target
- "gcov: no coverage data" — test binary not compiled with `-fprofile-arcs -ftest-coverage`; check Ceedling gcov plugin enabled

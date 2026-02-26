# embedded-testing-patterns

## Knowledge Base

Embedded C test patterns using Unity, CMock, Ceedling, and QEMU.

---

## Pattern 1: Ceedling Project Structure

```
project/
├── project.yml           # Ceedling configuration
├── src/
│   ├── sensor.c
│   └── sensor.h
├── test/
│   ├── test_sensor.c
│   └── support/          # Test helpers, stubs
└── vendor/               # Unity, CMock (git submodule or gem)
```

Minimal `project.yml`:
```yaml
:project:
  :build_root: build
  :test_file_prefix: test_

:paths:
  :source: ["src/**"]
  :test:   ["test/**"]
  :include: ["src"]

:tools:
  :test_compiler:
    :arguments:
      - -std=c11
      - -DUNIT_TEST

:plugins:
  :load_paths: ["vendor/ceedling/plugins"]
  :enabled: [gcov, xml_tests_report]

:cmock:
  :enforce_strict_ordering: TRUE
  :plugins: [:ignore, :return_thru_ptr, :callback]
```

Run:
```bash
ceedling test:all           # All tests
ceedling test:sensor        # Single module
ceedling gcov:all           # Coverage
ceedling utils:gcov         # HTML coverage report
```

---

## Pattern 2: Testable HAL Interface Pattern

The golden rule: drivers never call `HAL_I2C_Master_Transmit` directly. They call through a pointer.

```c
/* hal_i2c.h */
typedef int (*i2c_write_fn)(uint8_t dev_addr, uint8_t reg_addr,
                             const uint8_t *data, uint8_t len);
typedef int (*i2c_read_fn)(uint8_t dev_addr, uint8_t reg_addr,
                            uint8_t *data, uint8_t len);

typedef struct {
    i2c_write_fn write;
    i2c_read_fn  read;
} i2c_ops_t;

/* sensor.c uses i2c_ops_t, not HAL directly */
static const i2c_ops_t *s_i2c;

int sensor_begin(const i2c_ops_t *i2c_ops) {
    s_i2c = i2c_ops;
    return s_i2c->write(SENSOR_ADDR, REG_RESET, (uint8_t[]){0xB6}, 1);
}
```

Production: pass a `&stm32_i2c_ops` that wraps `HAL_I2C_Master_Transmit`.
Test: pass a `&mock_i2c_ops` backed by function pointers set by CMock.

---

## Pattern 3: CMock Expect Chaining

Order matters. CMock verifies calls happen in declared order when `enforce_strict_ordering: TRUE`.

```c
void test_bme280_init_sequence(void)
{
    /* Expect exact I2C register writes in order */
    i2c_write_ExpectAndReturn(BME280_ADDR, 0xF3, 0x00, 0);  /* status check */
    i2c_write_ExpectAndReturn(BME280_ADDR, 0xF4, 0x27, 0);  /* ctrl_meas */
    i2c_write_ExpectAndReturn(BME280_ADDR, 0xF5, 0xA0, 0);  /* config */

    int rc = bme280_init();

    TEST_ASSERT_EQUAL_INT(0, rc);
    /* CMock verifies all 3 Expects were called, in order, at test end */
}
```

If fewer calls happen than expected, CMock fails with "Called fewer times than expected."

---

## Pattern 4: Testing Error Paths

```c
void test_sensor_init_returns_error_on_i2c_failure(void)
{
    /* Inject I2C failure on first write */
    i2c_write_ExpectAndReturn(0x76, REG_RESET, 0xB6, I2C_ERR_NACK);

    sensor_error_t result = sensor_init();

    TEST_ASSERT_EQUAL(SENSOR_ERR_BUS, result);
}

void test_sensor_handles_crc_mismatch(void)
{
    uint8_t bad_data[4] = { 0xAA, 0xBB, 0xCC, 0x00 };  /* Wrong CRC */
    i2c_read_ExpectAndReturn(0x76, REG_DATA, bad_data, 4, 0);
    i2c_read_ReturnThruPtr_data(bad_data);

    int32_t temp;
    sensor_error_t result = sensor_read_temperature(&temp);

    TEST_ASSERT_EQUAL(SENSOR_ERR_CRC, result);
}
```

Error path coverage is often the most valuable. Always inject failures.

---

## Pattern 5: On-Target Test Runner via ITM

For tests that must run on hardware (timing-sensitive, peripheral integration):

```c
/* On-target Unity output via ITM */
void unity_output_char(char c)
{
    ITM_SendChar((uint32_t)c);
}

/* main.c in test build */
int main(void)
{
    SystemInit();
    itm_enable(168000000UL, 2000000UL);

    UNITY_BEGIN();
    RUN_TEST(test_sensor_read_temperature_converts_raw);
    RUN_TEST(test_sensor_init_configures_i2c);
    return UNITY_END();
}
```

Output captured via J-Link SWO Viewer or OpenOCD SWO. Pass/fail visible on host.

---

## Anti-Patterns

- **Testing HAL calls instead of business logic**: mock the HAL, test what your code does with the result.
- **Global state between tests**: reset all static variables in `setUp()`. Static state leaks cause false passes.
- **Single large test per function**: one test should test one behavior. Refactor to separate `test_X_when_Y`.
- **Ignoring all mock calls with `_IgnoreAndReturn`**: fine for stubs, but hides regressions. Be explicit.

## References

- Unity source + docs: https://github.com/ThrowTheSwitch/Unity
- CMock: https://github.com/ThrowTheSwitch/CMock
- Ceedling: https://github.com/ThrowTheSwitch/Ceedling
- James Grenning, "Test-Driven Development for Embedded C" (Pragmatic Bookshelf)

# /sensor

Sensor integration command: driver generation, calibration, filtering, fusion.

## Trigger

`/sensor <action> [options]`

## Actions

### `driver`
Generate a sensor driver from a datasheet description.

```
/sensor driver --part bme280 --bus i2c --addr 0x76
/sensor driver --part icm42688 --bus spi --mode 0
/sensor driver --part ads1115 --bus i2c --channels 4
```

### `calibrate`
Generate calibration code for a sensor.

```
/sensor calibrate --method 2-point --units celsius --range "-40,85"
/sensor calibrate --method multipoint --points 5 --nvm-address 0x08080000
/sensor calibrate --method temperature-compensation --coeff 0.05
```

### `filter`
Generate a digital filter for sensor data.

```
/sensor filter --type moving-average --window 8 --dtype int32
/sensor filter --type kalman-1d --q 1 --r 10
/sensor filter --type median --window 5
/sensor filter --type butterworth --order 2 --cutoff 10Hz --sample 100Hz
```

### `fuse`
Generate IMU sensor fusion code.

```
/sensor fuse --sensors accel+gyro --filter complementary --dt 0.01
/sensor fuse --sensors accel+gyro+mag --filter madgwick --beta 0.1
```

## Process

1. Read sensor datasheet: WHO_AM_I register, output registers, compensation formula.
2. Implement init: verify WHO_AM_I, read calibration NVM, configure oversampling and ODR.
3. Implement read: burst read raw output registers, apply compensation formula.
4. Add calibration: two-point at minimum, store in NVM.
5. Add filter: select based on noise characteristics and acceptable latency.

## Output Examples

### Sensor driver test sequence
```c
/* Acceptance test for a new sensor driver */
void sensor_driver_test(void)
{
    bme280_t dev;

    /* 1. Init */
    int rc = bme280_init(&dev, &i2c1_ops, BME280_ADDR);
    TEST_ASSERT_EQUAL_INT(0, rc);

    /* 2. Read and sanity-check (room temperature expected 15-35°C) */
    int32_t temp_hundredths;
    bme280_read_temperature(&dev, &temp_hundredths);
    TEST_ASSERT_INT_WITHIN(2000, 2500, temp_hundredths);  /* 5-45°C */

    /* 3. Verify no I2C errors after 100 consecutive reads */
    for (int i = 0; i < 100; i++) {
        TEST_ASSERT_EQUAL_INT(0, bme280_read_temperature(&dev, &temp_hundredths));
    }
}
```

### Kalman filter tuning guide
```
To tune Q and R:
1. Hold sensor still for 60 seconds
2. Log 100 readings, compute variance → this is R (measurement noise)
3. Move sensor slowly, observe drift rate → this is Q (process noise)
4. Start with R = measured_variance, Q = R/100
5. Increase Q to track faster changes; decrease Q for more smoothing
6. Rule: Q/R ratio = how much you trust the measurement vs the model
```

### Two-point calibration workflow
```
Step 1: Apply low reference value (e.g., 0°C: ice-water bath)
        Record sensor raw output: raw_low

Step 2: Apply high reference value (e.g., 100°C: boiling water)
        Record sensor raw output: raw_high

Step 3: cal_2pt_compute(&cal) → computes slope and offset

Step 4: cal_2pt_save(&cal) → writes to NVM

Step 5: Verify: re-read both reference points, check error < 0.5°C
```

## Error Handling

- "WHO_AM_I mismatch" — wrong I2C address (check SDO pin), or wrong device, or bus not working
- "All readings stuck at max/min" — sensor in reset or power not stable; check VDD and VDDIO timing
- "Kalman filter diverges" — Q too high or R too low; sensor noise is larger than assumed
- "Calibration fails at high temperature" — nonlinearity too large for two-point; add more calibration points or use NTC polynomial

# sensor-patterns

## Knowledge Base

Sensor driver, calibration, and filtering patterns for embedded C.

---

## Pattern 1: SPI Sensor Register Protocol

Most SPI sensors use: CS assert → [address byte with R/W bit] → [data bytes] → CS deassert.

```c
/* Generic SPI sensor: 8-bit register address, bit7 = R/W (1=read) */
/* Example: ICM-42688 IMU, MPU-9250, LIS3DH */

uint8_t spi_sensor_read_reg(uint8_t reg)
{
    uint8_t tx[2] = { reg | 0x80U, 0x00U };  /* Bit7=1: read */
    uint8_t rx[2] = { 0 };

    spi_cs_assert();
    spi_transfer_bytes(tx, rx, 2);
    spi_cs_deassert();

    return rx[1];   /* Byte 0 = dummy (address phase), byte 1 = data */
}

void spi_sensor_write_reg(uint8_t reg, uint8_t val)
{
    uint8_t tx[2] = { reg & 0x7FU, val };  /* Bit7=0: write */

    spi_cs_assert();
    spi_transfer_bytes(tx, NULL, 2);
    spi_cs_deassert();
}

/* Burst read: read N registers starting at addr */
void spi_sensor_read_burst(uint8_t start_reg, uint8_t *buf, uint8_t len)
{
    uint8_t addr = start_reg | 0x80U;

    spi_cs_assert();
    spi_transfer_bytes(&addr, NULL, 1);     /* Send address */
    spi_transfer_bytes(NULL, buf, len);     /* Receive data */
    spi_cs_deassert();
}
```

---

## Pattern 2: Temperature Sensor with NTC Thermistor

NTC (Negative Temperature Coefficient) resistance decreases with temperature. Steinhart-Hart equation.

```c
#include <math.h>

#define R_SERIES   10000.0f   /* 10kΩ series resistor */
#define R_NOM      10000.0f   /* Nominal resistance at T_NOM */
#define T_NOM      298.15f    /* 25°C in Kelvin */
#define B_COEFF    3950.0f    /* Beta coefficient from datasheet */

/* Returns temperature in Celsius */
float ntc_adc_to_celsius(uint16_t adc_raw, uint16_t adc_max)
{
    /* Voltage divider: R_NTC = R_SERIES * ADC / (ADC_MAX - ADC) */
    float resistance = R_SERIES * (float)adc_raw / (float)(adc_max - adc_raw);

    /* Steinhart-Hart simplified (B-parameter equation) */
    float temp_K = 1.0f / (1.0f/T_NOM + (1.0f/B_COEFF) * logf(resistance / R_NOM));

    return temp_K - 273.15f;
}
```

For higher accuracy: use a lookup table (LUT) generated from the datasheet R-T curve.

---

## Pattern 3: Multi-Point Calibration with Lookup Table

For sensors with non-linear response, interpolate between calibration points.

```c
#define CAL_POINTS 5U

typedef struct {
    float raw;
    float ref;
} cal_point_t;

/* Stored in NVM, ordered by raw value ascending */
static cal_point_t s_cal[CAL_POINTS];

float cal_apply(float raw)
{
    /* Find bracketing points */
    if (raw <= s_cal[0].raw)             { return s_cal[0].ref; }
    if (raw >= s_cal[CAL_POINTS-1].raw) { return s_cal[CAL_POINTS-1].ref; }

    for (uint32_t i = 0U; i < CAL_POINTS - 1U; i++) {
        if (raw <= s_cal[i+1].raw) {
            /* Linear interpolation */
            float t = (raw - s_cal[i].raw) / (s_cal[i+1].raw - s_cal[i].raw);
            return s_cal[i].ref + t * (s_cal[i+1].ref - s_cal[i].ref);
        }
    }
    return s_cal[CAL_POINTS-1].ref;
}
```

---

## Pattern 4: Median Filter for Spike Rejection

Median filter removes impulse noise (EMI spikes) without blurring edges.

```c
#define MED_WINDOW 5U   /* Must be odd */

static int32_t s_med_buf[MED_WINDOW];
static uint32_t s_med_head = 0U;
static bool s_med_full = false;

/* Insertion sort on a copy — avoids modifying the ring buffer */
static int32_t sort_median(void)
{
    int32_t sorted[MED_WINDOW];
    uint32_t n = s_med_full ? MED_WINDOW : s_med_head;
    memcpy(sorted, s_med_buf, n * sizeof(int32_t));

    /* Insertion sort: O(n^2), acceptable for n=5 */
    for (uint32_t i = 1U; i < n; i++) {
        int32_t key = sorted[i];
        int32_t j = (int32_t)i - 1;
        while (j >= 0 && sorted[j] > key) {
            sorted[j + 1] = sorted[j];
            j--;
        }
        sorted[j + 1] = key;
    }
    return sorted[n / 2U];
}

int32_t median_filter(int32_t new_val)
{
    s_med_buf[s_med_head] = new_val;
    s_med_head = (s_med_head + 1U) % MED_WINDOW;
    if (s_med_head == 0U) { s_med_full = true; }
    return sort_median();
}
```

---

## Pattern 5: Temperature Compensation

Sensors drift with temperature. Compensate using a correction polynomial or lookup:

```c
/* Pressure sensor with temperature coefficient
   Example: offset drifts 0.05% FSO/°C from 25°C baseline */
#define TEMP_BASELINE_C   25.0f
#define TEMP_COEFF        0.0005f   /* 0.05% per °C */
#define FSO_PA            100000.0f /* Full Scale Output: 100kPa */

float pressure_temp_compensate(float raw_pressure_pa, float temp_celsius)
{
    float delta_t = temp_celsius - TEMP_BASELINE_C;
    float correction = raw_pressure_pa * TEMP_COEFF * delta_t * FSO_PA / 100.0f;
    return raw_pressure_pa - correction;
}
```

For highly accurate sensors (load cells, precision ADCs): use a 2D calibration matrix indexed by [temperature][load] with bilinear interpolation.

---

## Anti-Patterns

- **Reading sensor without checking DRDY (data ready) bit**: reading before conversion complete returns stale or garbage data.
- **Calibrating at a single point**: single-point cal only corrects offset, not gain error. Always use at least two points.
- **Moving average window too long**: a 64-sample window at 100Hz = 640ms latency. Size the window to the acceptable response time.
- **Not re-calibrating on temperature change**: a sensor calibrated at 20°C may be 2-5% off at 60°C without compensation.

## References

- BME280 datasheet (Bosch): register map section 4.2.3, compensation formula
- ICM-42688 datasheet (InvenSense): SPI protocol section 5.1
- Madgwick filter: sebastianmadgwick.com/downloads/MadgwickAndAHRSalgorithm.zip
- Maxim AN4691: NTC thermistor measurement techniques

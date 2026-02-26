# comm-bus-patterns

## Knowledge Base

Production communication bus patterns for embedded C. STM32 HAL and LL examples.

---

## Pattern 1: I2C Register Read/Write for MEMS Sensors

Generic register-addressed I2C sensor driver (BME280, MPU-6050, etc.):

```c
#define I2C_TIMEOUT_MS  5U

HAL_StatusTypeDef sensor_write_reg(I2C_HandleTypeDef *hi2c,
                                    uint8_t dev_addr, uint8_t reg, uint8_t val)
{
    uint8_t buf[2] = { reg, val };
    return HAL_I2C_Master_Transmit(hi2c, dev_addr << 1, buf, 2, I2C_TIMEOUT_MS);
}

HAL_StatusTypeDef sensor_read_reg(I2C_HandleTypeDef *hi2c,
                                   uint8_t dev_addr, uint8_t reg,
                                   uint8_t *out, uint16_t len)
{
    HAL_StatusTypeDef s;
    s = HAL_I2C_Master_Transmit(hi2c, dev_addr << 1, &reg, 1, I2C_TIMEOUT_MS);
    if (s != HAL_OK) { return s; }
    return HAL_I2C_Master_Receive(hi2c, (dev_addr << 1) | 1,
                                   out, len, I2C_TIMEOUT_MS);
}

/* I2C bus recovery: toggle SCL 9 times to release stuck SDA */
void i2c_bus_recover(GPIO_TypeDef *scl_port, uint16_t scl_pin,
                     GPIO_TypeDef *sda_port, uint16_t sda_pin)
{
    for (int i = 0; i < 9; i++) {
        HAL_GPIO_WritePin(scl_port, scl_pin, GPIO_PIN_SET);
        HAL_Delay(1);
        HAL_GPIO_WritePin(scl_port, scl_pin, GPIO_PIN_RESET);
        HAL_Delay(1);
    }
    /* Generate STOP: SDA low→high while SCL high */
    HAL_GPIO_WritePin(sda_port, sda_pin, GPIO_PIN_RESET);
    HAL_GPIO_WritePin(scl_port, scl_pin, GPIO_PIN_SET);
    HAL_Delay(1);
    HAL_GPIO_WritePin(sda_port, sda_pin, GPIO_PIN_SET);
}
```

---

## Pattern 2: SPI DMA Transfer with Semaphore

Non-blocking SPI using DMA and FreeRTOS binary semaphore for completion notification:

```c
static SemaphoreHandle_t s_spi_done;

void HAL_SPI_TxRxCpltCallback(SPI_HandleTypeDef *hspi)
{
    if (hspi == &hspi1) {
        BaseType_t woken = pdFALSE;
        xSemaphoreGiveFromISR(s_spi_done, &woken);
        portYIELD_FROM_ISR(woken);
    }
}

void spi_dma_init(void)
{
    s_spi_done = xSemaphoreCreateBinary();
}

bool spi_transfer(const uint8_t *tx, uint8_t *rx, uint16_t len)
{
    spi_cs_assert();
    HAL_SPI_TransmitReceive_DMA(&hspi1, (uint8_t *)tx, rx, len);
    /* Block task until DMA complete (max 10ms) */
    bool ok = xSemaphoreTake(s_spi_done, pdMS_TO_TICKS(10)) == pdTRUE;
    spi_cs_deassert();
    return ok;
}
```

---

## Pattern 3: UART DMA Circular Buffer with IDLE Detection

Most reliable pattern for variable-length UART frames at high baud:

```c
#define DMA_RX_BUF  256U
static uint8_t  s_dma_rx[DMA_RX_BUF];
static uint32_t s_rx_wr = 0U;  /* Written by IDLE ISR */
static uint32_t s_rx_rd = 0U;  /* Read by application  */

void uart_dma_init(UART_HandleTypeDef *hu)
{
    /* Start DMA receive in circular mode — never needs restart */
    HAL_UARTEx_ReceiveToIdle_DMA(hu, s_dma_rx, DMA_RX_BUF);
    __HAL_DMA_DISABLE_IT(hu->hdmarx, DMA_IT_HT);  /* Disable half-transfer */
}

void HAL_UARTEx_RxEventCallback(UART_HandleTypeDef *hu, uint16_t size)
{
    /* size = number of bytes received since last callback */
    /* DMA wrote to s_dma_rx[s_rx_wr .. s_rx_wr+size-1] (circular) */
    s_rx_wr = (s_rx_wr + size) % DMA_RX_BUF;
}

uint16_t uart_available(void) {
    return (s_rx_wr - s_rx_rd + DMA_RX_BUF) % DMA_RX_BUF;
}

uint8_t uart_read_byte(void) {
    uint8_t c = s_dma_rx[s_rx_rd];
    s_rx_rd = (s_rx_rd + 1U) % DMA_RX_BUF;
    return c;
}
```

---

## Pattern 4: CAN Transmit and Receive

```c
/* Transmit CAN frame */
CAN_TxHeaderTypeDef tx_hdr = {
    .StdId  = 0x123U,
    .IDE    = CAN_ID_STD,
    .RTR    = CAN_RTR_DATA,
    .DLC    = 8U,
    .TransmitGlobalTime = DISABLE,
};

void can_send(uint8_t *data)
{
    uint32_t mailbox;
    if (HAL_CAN_GetTxMailboxesFreeLevel(&hcan1) == 0) { return; }
    HAL_CAN_AddTxMessage(&hcan1, &tx_hdr, data, &mailbox);
}

/* Receive: called from CAN RX FIFO0 interrupt */
void HAL_CAN_RxFifo0MsgPendingCallback(CAN_HandleTypeDef *hcan)
{
    CAN_RxHeaderTypeDef hdr;
    uint8_t buf[8];
    if (HAL_CAN_GetRxMessage(hcan, CAN_RX_FIFO0, &hdr, buf) == HAL_OK) {
        can_dispatch(hdr.StdId, buf, hdr.DLC);
    }
}
```

---

## Pattern 5: SPI CPOL/CPHA Mode Selection Reference

```c
/* STM32 HAL SPI mode to CPOL/CPHA mapping */
/* Mode 0: CPOL=0, CPHA=0 — idle low, sample rising  */
hspi1.Init.CLKPolarity = SPI_POLARITY_LOW;
hspi1.Init.CLKPhase    = SPI_PHASE_1EDGE;

/* Mode 3: CPOL=1, CPHA=1 — idle high, sample rising */
hspi1.Init.CLKPolarity = SPI_POLARITY_HIGH;
hspi1.Init.CLKPhase    = SPI_PHASE_2EDGE;

/* Always verify against the sensor's timing diagram.
   ICM-42688 (IMU): Mode 0 or Mode 3
   W25Q128 (Flash): Mode 0 or Mode 3
   MCP3204 (ADC):   Mode 0 only           */
```

---

## Anti-Patterns

- **I2C HAL_OK return does not mean data is correct**: check sensor WHO_AM_I register before trusting any data.
- **SPI without explicit CS control**: HAL NSS software mode has glitches during multi-byte transfers. Manage CS manually.
- **CAN without filter configured**: all frames enter FIFO, FIFO overflows, data is lost.
- **UART polling in production**: blocks CPU on every byte. Use DMA+IDLE for any baud rate above 9600.
- **I2C without bus recovery**: a slave stuck holding SDA low after power glitch makes the bus permanently busy without recovery.

## References

- UM1905 (ST): Description of STM32F4 HAL and Low-Layer drivers
- I2C specification: NXP UM10204
- CAN spec: Bosch CAN 2.0 specification
- USB CDC class specification: USB.org CDC120.pdf

# bootloader-patterns

## Knowledge Base

Production bootloader patterns for STM32, nRF52, and SAM MCUs.

---

## Pattern 1: Boot Decision Tree

```
Power-on Reset
    │
    ▼
Read boot flag (RTC backup register or dedicated NVM byte)
    │
    ├── FLAG_UPDATE_PENDING ──► Receive new image via UART/CAN/USB
    │                           │
    │                           ▼
    │                      Write to inactive bank
    │                           │
    │                      Verify CRC + signature
    │                           │
    │                      Set FLAG_BOOT_NEW, reset
    │
    ├── FLAG_BOOT_NEW ──► Validate image at new bank
    │                      │
    │                      ├── OK ─► Clear flag, increment boot counter,
    │                      │         jump to new image
    │                      │
    │                      └── FAIL ─► Increment failure counter
    │                                  │
    │                                  └── > 3 fails ─► Revert to golden
    │
    └── FLAG_NONE ──► Validate active bank image
                       │
                       ├── OK ─► Jump to application
                       │
                       └── FAIL ─► Fall back to recovery UART mode
```

---

## Pattern 2: RTC Backup Register for Boot Flags

STM32 RTC backup registers survive reset (not power-off). Ideal for bootloader flags.

```c
#define BKP_REG_BOOT_FLAG  RTC->BKP0R
#define BOOT_FLAG_NONE     0x00000000UL
#define BOOT_FLAG_UPDATE   0xA5A5A5A5UL
#define BOOT_FLAG_BOOT_NEW 0x5A5A5A5AUL

void bootflag_set(uint32_t flag)
{
    /* Enable backup domain access */
    RCC->APB1ENR |= RCC_APB1ENR_PWREN;
    PWR->CR |= PWR_CR_DBP;
    BKP_REG_BOOT_FLAG = flag;
    PWR->CR &= ~PWR_CR_DBP;
}

uint32_t bootflag_get(void)
{
    RCC->APB1ENR |= RCC_APB1ENR_PWREN;
    PWR->CR |= PWR_CR_DBP;
    return BKP_REG_BOOT_FLAG;
}
```

---

## Pattern 3: Dual-Bank Flash Layout (STM32F407, 1MB)

```
0x08000000 ┌─────────────────────────┐  Sector 0 (16KB)
           │  Primary Bootloader     │  Write-protected
           │  (golden copy)          │
0x08004000 ├─────────────────────────┤  Sector 1 (16KB)
           │  Bootloader config      │
           │  (version NVM, keys)    │
0x08008000 ├─────────────────────────┤  Sectors 2-3 (32KB)
           │  Application Bank A     │  Active
           │  (img_header + app)     │
0x08040000 ├─────────────────────────┤  Sector 6 (128KB)
           │  Application Bank B     │  OTA target
           │  (img_header + app)     │
0x080C0000 ├─────────────────────────┤  Sector 10 (128KB)
           │  Application Data       │
           │  (settings, logs)       │
0x08100000 └─────────────────────────┘
```

Linker scripts for application: `ORIGIN = 0x08008080` (0x08008000 + 0x80 for header).

---

## Pattern 4: YMODEM Receive Over UART

YMODEM-1K is the standard for bootloader firmware transfer. 1024-byte packets, CRC-16.

```c
/* Simplified YMODEM receive state machine */
#define YMODEM_SOH  0x01  /* 128-byte packet start */
#define YMODEM_STX  0x02  /* 1024-byte packet start */
#define YMODEM_EOT  0x04  /* End of transmission */
#define YMODEM_ACK  0x06
#define YMODEM_NAK  0x15
#define YMODEM_CAN  0x18
#define YMODEM_C    0x43  /* 'C': request CRC mode */

typedef enum {
    YMODEM_WAIT_HEADER,
    YMODEM_RECV_DATA,
    YMODEM_VERIFY,
    YMODEM_DONE,
    YMODEM_ERROR
} ymodem_state_t;

/* Host tool: sz --ymodem firmware.bin /dev/ttyUSB0 */
```

Libraries: libxmodem (open-source), or roll your own with 200 lines of C.

---

## Pattern 5: Post-Flash Verification

After writing each page to flash, read it back and compare.

```c
bool flash_verify_region(uint32_t flash_addr, const uint8_t *src, uint32_t len)
{
    const uint8_t *flash = (const uint8_t *)flash_addr;
    for (uint32_t i = 0; i < len; i++) {
        if (flash[i] != src[i]) { return false; }
    }
    return true;
}

/* Verify full image CRC after writing all pages */
bool bootloader_verify_written_image(uint32_t app_base, uint32_t img_size)
{
    const img_header_t *hdr = (const img_header_t *)app_base;
    if (hdr->magic != IMAGE_MAGIC) { return false; }

    const uint8_t *body = (const uint8_t *)app_base + sizeof(img_header_t);
    uint32_t crc = crc32_compute(body, img_size);
    return crc == hdr->crc32;
}
```

---

## Pattern 6: Watchdog During Bootloader

Always feed a watchdog during flash write loops. If flash write hangs (bad sector), WDT resets and bootloader recovers.

```c
/* Configure IWDG for 4-second timeout (STM32, LSI ~32kHz) */
void iwdg_init(void)
{
    IWDG->KR  = 0xCCCC;      /* Start IWDG */
    IWDG->KR  = 0x5555;      /* Enable register write */
    IWDG->PR  = 6U;           /* Prescaler /256: 32kHz/256 = 125 Hz */
    IWDG->RLR = 500U;         /* Reload: 500/125 Hz = 4 seconds */
    IWDG->KR  = 0xAAAA;      /* Reload (arm) */
}

void iwdg_feed(void) { IWDG->KR = 0xAAAA; }

/* In flash write loop: */
for (uint32_t page = 0; page < total_pages; page++) {
    flash_write_page(base + page * PAGE_SIZE, buf + page * PAGE_SIZE);
    iwdg_feed();
}
```

---

## Anti-Patterns

- **Jumping to app without disabling IRQs**: Application installs its own vector table; pending IRQs from bootloader fire in application context and crash it.
- **Writing new image over running firmware without dual-bank**: Power loss during write = unrecoverable brick.
- **CRC only, no signature**: CRC protects against corruption, not malicious injection. Add ECDSA for production.
- **No boot counter with fallback**: One bad image = permanent brick in the field.
- **Bootloader in non-protected flash**: Application bug can overwrite the bootloader.

## References

- AN3965 (ST): STM32F40x/41x in-application programming using USART
- mcuboot: https://github.com/mcu-tools/mcuboot
- mbedTLS ECDSA: https://mbed-tls.readthedocs.io/
- YMODEM protocol specification by Chuck Forsberg

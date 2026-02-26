# firmware-update-patterns

## Knowledge Base

FOTA patterns for MCU firmware updates with reliability guarantees.

---

## Pattern 1: mcuboot Image Header Construction

```c
/* Build tool (Python/imgtool) writes this header before the firmware binary */
/* MCU application starts at header_base + header_size (default 0x20 = 32 bytes) */

#define MCUBOOT_MAGIC  0x96f3b83dUL

typedef struct __attribute__((packed)) {
    uint32_t magic;        /* 0x96f3b83d */
    uint32_t load_addr;    /* 0: XIP from flash */
    uint16_t hdr_size;     /* 32 bytes */
    uint16_t protect_tlv;  /* 0 */
    uint32_t img_size;     /* Firmware body bytes */
    uint32_t flags;        /* IMAGE_F_* flags */
    uint8_t  img_ver[8];   /* major, minor, revision[2], build_num[4] */
    uint32_t _pad;
} mcuboot_header_t;        /* Exactly 32 bytes */

/* Verify on bootloader side: */
bool mcuboot_verify_header(const void *slot_base)
{
    const mcuboot_header_t *hdr = slot_base;
    return hdr->magic == MCUBOOT_MAGIC
        && hdr->hdr_size == 32U
        && hdr->img_size > 0U
        && hdr->img_size < MAX_IMAGE_SIZE;
}
```

---

## Pattern 2: FOTA Progress Tracking via MQTT

```python
# Python host-side: publish firmware chunks, track progress
import paho.mqtt.client as mqtt
import struct, hashlib

CHUNK_SIZE = 1024
TOPIC_CMD  = "device/{id}/ota/cmd"
TOPIC_DATA = "device/{id}/ota/data"
TOPIC_ACK  = "device/{id}/ota/ack"

def send_firmware(client, device_id, fw_bytes):
    total = len(fw_bytes)
    sha256 = hashlib.sha256(fw_bytes).hexdigest()

    # Start command
    client.publish(TOPIC_CMD.format(id=device_id),
        f'{{"cmd":"start","size":{total},"sha256":"{sha256}"}}')

    # Send chunks
    for i, offset in enumerate(range(0, total, CHUNK_SIZE)):
        chunk = fw_bytes[offset:offset+CHUNK_SIZE]
        hdr = struct.pack(">IHH", offset, len(chunk), i)
        client.publish(TOPIC_DATA.format(id=device_id), hdr + chunk)

    # Finish
    client.publish(TOPIC_CMD.format(id=device_id), '{"cmd":"apply"}')
```

Device side: subscribe to topics, write chunks to flash in order, track offset.

---

## Pattern 3: Firmware Version Comparison

```c
/* Semantic version: major.minor.patch — encoded as uint32_t */
#define VERSION_ENCODE(maj, min, pat) \
    (((uint32_t)(maj) << 16) | ((uint32_t)(min) << 8) | (uint32_t)(pat))

#define APP_VERSION  VERSION_ENCODE(2, 1, 0)

/* Anti-rollback: never accept image older than currently running */
bool ota_version_acceptable(uint32_t new_ver)
{
    uint32_t current = nvm_read_committed_version();
    return new_ver >= current;
}

/* After successful boot, commit version */
void ota_commit_version(void)
{
    nvm_write_committed_version(APP_VERSION);
}
```

---

## Pattern 4: Boot Counter with Automatic Rollback

```c
/* Uses RTC backup register — survives NVIC_SystemReset, not power cycle */
#define BKP_BOOT_COUNT  RTC->BKP1R
#define MAX_BOOT_TRIES  3U

void bootloader_check_rollback(void)
{
    if (!image_pending_confirm()) { return; }

    uint32_t count = BKP_BOOT_COUNT;
    if (count >= MAX_BOOT_TRIES) {
        /* Too many failed boots: revert to previous bank */
        BKP_BOOT_COUNT = 0U;
        swap_to_previous_bank();
        NVIC_SystemReset();
    }

    /* Increment before booting */
    enable_backup_domain_write();
    BKP_BOOT_COUNT = count + 1U;
    disable_backup_domain_write();
}

/* Application calls this after self-test passes: */
void ota_confirm_image(void)
{
    enable_backup_domain_write();
    BKP_BOOT_COUNT = 0U;
    mark_image_confirmed();  /* Clear pending-confirm flag in NVM */
    disable_backup_domain_write();
}
```

---

## Pattern 5: Chunk Write with Alignment

Flash write must be aligned to the MCU's minimum write unit (word, half-page, or page).

```c
#define FLASH_PAGE_SIZE  256U  /* STM32F4 minimum write = 1 word, but program in pages */

/* Accumulate bytes in RAM buffer; flush to flash on full page or end of image */
static uint8_t  s_page_buf[FLASH_PAGE_SIZE];
static uint32_t s_page_buf_used = 0U;
static uint32_t s_write_addr;

void ota_write_init(uint32_t start_addr)
{
    s_write_addr = start_addr;
    s_page_buf_used = 0U;
    memset(s_page_buf, 0xFF, sizeof(s_page_buf));
}

void ota_write_chunk(const uint8_t *data, uint32_t len)
{
    while (len--) {
        s_page_buf[s_page_buf_used++] = *data++;
        if (s_page_buf_used == FLASH_PAGE_SIZE) {
            flash_write_page(s_write_addr, s_page_buf, FLASH_PAGE_SIZE);
            s_write_addr += FLASH_PAGE_SIZE;
            s_page_buf_used = 0U;
            memset(s_page_buf, 0xFF, sizeof(s_page_buf));
        }
    }
}

void ota_write_flush(void)
{
    if (s_page_buf_used > 0U) {
        /* Pad remaining bytes with 0xFF (erased flash value) */
        flash_write_page(s_write_addr, s_page_buf, FLASH_PAGE_SIZE);
    }
}
```

---

## Anti-Patterns

- **Confirm on first successful boot, not after self-test**: one peripheral failure makes the update permanent.
- **Storing OTA state in RAM**: RAM content is lost on reset. Use NVM, RTC backup registers, or OTP.
- **No size check before write**: writing past the end of the target bank corrupts the NVM region.
- **HTTP OTA without TLS**: an on-path attacker can inject arbitrary firmware. Always verify server certificate.

## References

- mcuboot: https://github.com/mcu-tools/mcuboot
- ESP-IDF OTA: https://docs.espressif.com/projects/esp-idf/en/stable/esp32/api-reference/system/ota.html
- janpatch: https://github.com/janjongboom/janpatch
- AWS IoT Jobs: https://docs.aws.amazon.com/iot/latest/developerguide/iot-jobs.html

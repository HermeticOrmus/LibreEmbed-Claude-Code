# embedded-linux-patterns

## Knowledge Base

Patterns for Yocto, Buildroot, device trees, and kernel modules on ARM SoCs.

---

## Pattern 1: Yocto Layer and Recipe Hierarchy

```
Layers (priority, low to high):
  poky/meta                   # Core: glibc, busybox, gcc toolchain
  poky/meta-poky              # Poky distribution configuration
  meta-openembedded/meta-oe   # Extended packages (Python, Qt, etc.)
  meta-raspberrypi            # BSP: kernel, u-boot, machine configs
  meta-myproject              # Project-specific: your app, config
```

`bblayers.conf` adds layers. `local.conf` sets `MACHINE`, `DISTRO`, and `BB_NUMBER_THREADS`.

```bash
# Common BitBake operations:
bitbake core-image-minimal          # Build minimal console image
bitbake -s | grep myapp             # Check recipe is found
bitbake myapp -c cleanall && bitbake myapp  # Rebuild from scratch
bitbake myapp -e | grep ^S=         # Show S (source dir) variable
devtool modify myapp                # Unpack source for development
devtool finish myapp meta-myproject # Write changes back to recipe
```

---

## Pattern 2: Kernel Configuration Fragment

Instead of editing `.config` directly, use a config fragment in a `.bbappend`:

```bitbake
# meta-myproject/recipes-kernel/linux/linux-%.bbappend
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI += "file://my-features.cfg"
```

```
# files/my-features.cfg
CONFIG_CAN=y
CONFIG_CAN_RAW=y
CONFIG_SPI=y
CONFIG_SPI_SPIDEV=y
CONFIG_I2C_CHARDEV=y
# CONFIG_MODULES is not set   ← explicit disable
```

Apply with: `bitbake linux-imx -c menuconfig` then `bitbake linux-imx -c savedefconfig`.

---

## Pattern 3: Device Tree GPIO and Interrupt Properties

```dts
/* GPIO: <&gpioN pin_num active_level> */
/* IRQ:  <&intc GIC_SPI irq_num IRQ_TYPE_EDGE_RISING> */

mysensor@48 {
    compatible = "ti,ads1115";
    reg = <0x48>;

    /* Active-low interrupt from sensor, connected to PA3 */
    interrupt-parent = <&gpioa>;
    interrupts = <3 IRQ_TYPE_EDGE_FALLING>;

    /* Reset GPIO: active low, initially deasserted */
    reset-gpios = <&gpiob 5 GPIO_ACTIVE_LOW>;
};
```

Kernel driver reads: `gpiod_get(dev, "reset", GPIOD_OUT_HIGH)` — matches `reset-gpios` property.
IRQ: `platform_get_irq(pdev, 0)` or `irq_of_parse_and_map(np, 0)`.

---

## Pattern 4: Kernel Module Makefile

```makefile
# Makefile for out-of-tree kernel module
KDIR ?= /lib/modules/$(shell uname -r)/build

obj-m += mydriver.o
mydriver-objs := mydriver_core.o mydriver_spi.o

all:
	$(MAKE) -C $(KDIR) M=$(PWD) modules

clean:
	$(MAKE) -C $(KDIR) M=$(PWD) clean

# Cross-compile:
# make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- KDIR=/path/to/kernel
```

---

## Pattern 5: Sysfs Attribute in Kernel Driver

Expose sensor data via `/sys/bus/platform/devices/mydev/temperature`:

```c
static ssize_t temperature_show(struct device *dev,
                                 struct device_attribute *attr, char *buf)
{
    struct mydev_priv *priv = dev_get_drvdata(dev);
    int32_t temp_mC = mydev_read_temperature(priv);
    return sysfs_emit(buf, "%d\n", temp_mC);
}
static DEVICE_ATTR_RO(temperature);

static struct attribute *mydev_attrs[] = {
    &dev_attr_temperature.attr,
    NULL,
};
ATTRIBUTE_GROUPS(mydev);

/* Add to platform_driver: */
.driver = {
    .name        = "mydev",
    .dev_groups  = mydev_groups,
    .of_match_table = mydev_of_match,
},
```

Read from userspace: `cat /sys/bus/platform/devices/mydev.0/temperature`

---

## Pattern 6: QEMU Testing Before Hardware

```bash
# Test ARM userspace binary on x86 host (requires binfmt_misc + qemu-user)
apt install qemu-user-static
qemu-arm-static -L /usr/arm-linux-gnueabihf ./myapp

# Full system emulation with Yocto image:
runqemu qemuarm nographic core-image-minimal

# Boot custom kernel + rootfs:
qemu-system-arm \
  -M virt -cpu cortex-a15 \
  -kernel zImage \
  -dtb virt.dtb \
  -initrd rootfs.cpio.gz \
  -append "console=ttyAMA0 root=/dev/ram" \
  -nographic
```

---

## Anti-Patterns

- **Editing `.config` directly in Yocto**: it gets overwritten on next build. Use config fragments.
- **`compatible = "linux,generic-..."` in DTS**: use a specific compatible string matching your driver's `of_match_table`.
- **Kernel module without `devm_` APIs**: manual resource management leaks on error paths in `probe`.
- **Cross-compiling without sysroot**: linking against host libraries causes ABI mismatch. Always use `--sysroot` or Yocto SDK.

## References

- Yocto Project Reference Manual: docs.yoctoproject.org
- Linux Device Drivers, 3rd Ed. (Corbet, Rubini, Hartman) — ldd3
- Device Tree specification: devicetree.org/specifications/
- U-Boot documentation: u-boot.readthedocs.io

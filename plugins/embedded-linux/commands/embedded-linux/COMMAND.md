# /embedded-linux

Embedded Linux command: Yocto/Buildroot builds, device tree, kernel modules, cross-compilation.

## Trigger

`/embedded-linux <action> [options]`

## Actions

### `build`
Generate Yocto or Buildroot configuration for a target.

```
/embedded-linux build --bsp imx6ul --distro yocto --image core-image-minimal
/embedded-linux build --bsp raspberrypi4 --distro yocto --image core-image-full-cmdline
/embedded-linux build --target stm32mp157 --system buildroot --libc musl
```

### `flash`
Generate flashing commands for the target.

```
/embedded-linux flash --tool bmaptool --image core-image-minimal-imx6ul.wic.bmap
/embedded-linux flash --tool dd --image sdcard.img --device /dev/sdb
/embedded-linux flash --tool u-boot-tftp --ip 192.168.1.100
```

### `module`
Generate a Linux kernel module skeleton.

```
/embedded-linux module --type platform --name mydriver --bus i2c
/embedded-linux module --type char --name mychar --major 240
/embedded-linux module --type spi --name myspi --compatible "myorg,mysensor"
```

### `debug`
Generate debug commands for a running embedded Linux system.

```
/embedded-linux debug --dmesg-filter mydriver
/embedded-linux debug --sysfs-path /sys/bus/i2c/devices/
/embedded-linux debug --ftrace-function mydev_probe
```

## Process

1. Confirm target SoC and available BSP layers.
2. Set `MACHINE` and `DISTRO` in `local.conf`.
3. Create a custom layer for project-specific recipes.
4. Use `devtool` for iterative recipe development.
5. Test with QEMU before physical hardware when possible.

## Output Examples

### local.conf additions
```bash
# Build directory: conf/local.conf
MACHINE = "imx6ul-var-dart"
DISTRO = "poky"
BB_NUMBER_THREADS ?= "${@oe.utils.cpu_count()}"
PARALLEL_MAKE ?= "-j ${@oe.utils.cpu_count()}"
PACKAGE_CLASSES = "package_ipk"
EXTRA_IMAGE_FEATURES ?= "debug-tweaks ssh-server-openssh"
IMAGE_INSTALL:append = " myapp htop strace"
```

### Device tree overlay apply (runtime)
```bash
# On target (overlayfs mounted at /boot/overlays/)
dtoverlay mysensor-overlay
# or via U-Boot:
setenv fdtoverlays /overlays/mysensor-overlay.dtbo
```

### Ftrace function tracing
```bash
# On target:
echo mydev_probe > /sys/kernel/debug/tracing/set_ftrace_filter
echo function > /sys/kernel/debug/tracing/current_tracer
echo 1 > /sys/kernel/debug/tracing/tracing_on
cat /sys/kernel/debug/tracing/trace
```

## Error Handling

- "do_fetch: No such file" — check `SRC_URI` and `SRCREV`; use `BB_STRICT_CHECKSUM = "0"` only during development
- "ERROR: QA Issue" — recipe install paths wrong; check `D` variable vs `bindir`/`libdir`
- "Module not found" — check `MODULES_INSTALL_DIRS` and `depmod` ran during image build
- "DT: of_device_id table not found" — `compatible` string mismatch between DTS and driver

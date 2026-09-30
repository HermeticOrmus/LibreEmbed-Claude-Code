#!/usr/bin/env bash
# Session Start Hook - Embedded Systems
# Detects project context and configures the session.
#
# Claude Code sends the hook input as JSON on stdin and adds whatever this
# script prints to the session context. It prints one line, and only when
# the project looks like firmware. It writes no files.
set -euo pipefail
IFS=$'\n\t'

DIR=""
if command -v jq >/dev/null 2>&1; then
  DIR="$(jq -r '.cwd // empty' 2>/dev/null)" || DIR=""
fi
[[ -n "$DIR" && -d "$DIR" ]] || DIR="$PWD"

# Detect Embedded Systems context
FOUND=""
found() { FOUND="${FOUND:+$FOUND, }$1"; }

detect_context() {
  [[ -f "$DIR/platformio.ini" ]] && found "platformio.ini"
  [[ -f "$DIR/west.yml" || -f "$DIR/prj.conf" ]] && found "Zephyr project"
  [[ -f "$DIR/sdkconfig" || -f "$DIR/sdkconfig.defaults" ]] && found "ESP-IDF sdkconfig"
  [[ -f "$DIR/conf/layer.conf" || -f "$DIR/external.desc" ]] && found "Yocto or Buildroot layer"
  if grep -qsE 'arm-none-eabi|riscv(32|64)-unknown-elf|xtensa-|avr-gcc' \
       "$DIR/Makefile" "$DIR/CMakeLists.txt" "$DIR"/*.cmake 2>/dev/null; then
    found "cross toolchain in the build files"
  fi
  local hit=""
  hit="$(find "$DIR" -maxdepth 3 \( -name .git -o -name node_modules \) -prune -o -type f \
          \( -name '*.ld' -o -name '*.icf' -o -name '*.ioc' -o -name 'FreeRTOSConfig.h' \
             -o -name '*.dts' -o -name '*.overlay' -o -name '*.uvprojx' -o -name '*.ewp' \) \
          -print -quit 2>/dev/null)" || hit=""
  [[ -n "$hit" ]] && found "${hit##*/}"
  return 0
}

detect_context

if [[ -n "$FOUND" ]]; then
  echo "[LibreEmbed] Embedded firmware project detected ($FOUND). Confirm the target MCU, toolchain, and RTOS before giving part-specific advice."
fi

exit 0

#!/usr/bin/env bash
# LibreEmbed-Claude-Code installer.
# Copies the 15 embedded systems plugins into your Claude Code plugins directory.
#
# Usage: ./setup.sh [--plugins-dir <path>] [--only <p1,p2,p3>] [--no-safety-hooks]
#
# Defaults:
#   --plugins-dir = $CLAUDE_PLUGINS_DIR or ~/.claude/plugins
#   --only        = all 15 plugins
#   safety hooks  = installed (pre-flash warnings)

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGINS_SRC="$SCRIPT_DIR/plugins"
HOOKS_SRC="$SCRIPT_DIR/hooks"
PLUGINS_DST="${CLAUDE_PLUGINS_DIR:-$HOME/.claude/plugins}"
HOOKS_DST="$HOME/.claude/hooks"

ONLY=""
INSTALL_HOOKS=1

while (( $# )); do
  case "$1" in
    --plugins-dir)     PLUGINS_DST="$2"; shift 2;;
    --only)            ONLY="$2"; shift 2;;
    --no-safety-hooks) INSTALL_HOOKS=0; shift;;
    -h|--help)
      cat <<EOF
Usage: $0 [options]

Options:
  --plugins-dir <path>       Plugin destination (default: ~/.claude/plugins)
  --only p1,p2,p3            Install only the named plugins (default: all 15)
  --no-safety-hooks          Skip installing pre-flash warning hooks

Examples:
  $0
  $0 --only rtos-patterns,communication-buses,iot-protocols
  $0 --plugins-dir ~/custom/claude/plugins
EOF
      exit 0;;
    *) echo "Unknown arg: $1" >&2; exit 64;;
  esac
done

if [[ ! -d "$PLUGINS_SRC" ]]; then
  echo "ERROR: plugins source not found at $PLUGINS_SRC" >&2
  echo "Run from the repo root." >&2
  exit 1
fi

mkdir -p "$PLUGINS_DST"

# Build the list of plugins to install
if [[ -n "$ONLY" ]]; then
  IFS=',' read -r -a SELECTED <<< "$ONLY"
else
  SELECTED=()
  for d in "$PLUGINS_SRC"/*/; do
    SELECTED+=("$(basename "$d")")
  done
fi

echo "Installing LibreEmbed plugins:"
echo "  Source: $PLUGINS_SRC"
echo "  Target: $PLUGINS_DST"
echo "  Plugins: ${#SELECTED[@]}"
echo ""

count=0
for name in "${SELECTED[@]}"; do
  src="$PLUGINS_SRC/$name"
  dst="$PLUGINS_DST/libre-embed-$name"

  if [[ ! -d "$src" ]]; then
    echo "  [skip] $name (not found in plugins/)"
    continue
  fi

  if [[ -d "$dst" ]]; then
    echo "  [skip] libre-embed-$name (already installed — remove first to reinstall)"
    continue
  fi

  cp -r "$src" "$dst"
  echo "  [ok]   libre-embed-$name"
  count=$((count + 1))
done

# Install safety hooks
if (( INSTALL_HOOKS )) && [[ -d "$HOOKS_SRC" ]]; then
  mkdir -p "$HOOKS_DST"
  for h in "$HOOKS_SRC"/*.sh; do
    [[ -f "$h" ]] || continue
    cp "$h" "$HOOKS_DST/libre-embed-$(basename "$h")"
    chmod +x "$HOOKS_DST/libre-embed-$(basename "$h")"
  done
  echo ""
  echo "Safety hooks installed to $HOOKS_DST (pre-flash warnings active)."
  echo "Disable with --no-safety-hooks on next install."
fi

echo ""
echo "Installed $count plugins."
echo ""
echo "Restart Claude Code, then try:"
echo "  /rtos design a task structure for a sensor logger"
echo "  /comm-bus write an SPI driver for an IMU"
echo "  /iot configure MQTT QoS for unreliable cellular links"
echo ""
echo "Documentation: README.md, QUICK_START.md, learning-paths/"

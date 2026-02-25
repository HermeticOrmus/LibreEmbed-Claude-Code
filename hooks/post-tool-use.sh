#!/bin/bash
# Post-Tool-Use Hook - Embedded Systems
# Verifies results after tool execution

TOOL_NAME="${1:-unknown}"
EXIT_CODE="${2:-0}"
TARGET="${3:-}"

LOG_DIR="$(dirname "$0")/logs"
mkdir -p "$LOG_DIR"

# Log tool usage
echo "[$(date +%H:%M:%S)] Tool: $TOOL_NAME | Exit: $EXIT_CODE | Target: $TARGET" >> "$LOG_DIR/tool-usage.log"

# Check for common issues after file modifications
if [ "$TOOL_NAME" = "Write" ] || [ "$TOOL_NAME" = "Edit" ]; then
  if [ -n "$TARGET" ] && [ -f "$TARGET" ]; then
    # Check file was actually written
    if [ ! -s "$TARGET" ]; then
      echo "WARNING: File appears empty after write: $TARGET"
    fi
  fi
fi

# Remind about testing after code changes
if echo "$TARGET" | grep -qiE '\.(js|ts|py|go|rs|java|rb)$'; then
  echo "REMINDER: Consider running tests after code changes"
fi

exit 0

#!/bin/bash
# Pre-Tool-Use Hook - Embedded Systems
# Validates actions before execution

TOOL_NAME="${1:-unknown}"
TARGET="${2:-}"

# Safety checks
check_sensitive_files() {
  if echo "$TARGET" | grep -qiE '\.(env|key|pem|credentials|secret)'; then
    echo "WARNING: Operation targets potentially sensitive file: $TARGET"
    return 1
  fi
  return 0
}

check_destructive_ops() {
  if echo "$TOOL_NAME" | grep -qiE '(delete|remove|drop|destroy|force)'; then
    echo "CAUTION: Destructive operation detected: $TOOL_NAME"
    return 1
  fi
  return 0
}

# Run checks
check_sensitive_files
check_destructive_ops

exit 0

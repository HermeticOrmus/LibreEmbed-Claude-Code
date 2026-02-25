#!/bin/bash
# Session Start Hook - Embedded Systems
# Detects project context and configures the session

LOG_DIR="$(dirname "$0")/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/session-$(date +%Y%m%d-%H%M%S).log"

log() {
  echo "[$(date +%H:%M:%S)] $1" >> "$LOG_FILE"
}

log "Session started"
log "Working directory: $(pwd)"

# Detect Embedded Systems context
detect_context() {
  local indicators=0
  
  
  [ -f "CMakeLists.txt" ] && indicators=$((indicators + 1))
  [ -f "Makefile" ] && grep -q "arm-none-eabi\|cross" Makefile 2>/dev/null && indicators=$((indicators + 1))
  [ -f "platformio.ini" ] && indicators=$((indicators + 1))
  [ -d "src/" ] && ls src/*.c 2>/dev/null | head -1 > /dev/null && indicators=$((indicators + 1))
  [ -f "*.ld" ] 2>/dev/null && indicators=$((indicators + 1))

  
  echo "$indicators"
}

CONTEXT_SCORE=$(detect_context)
log "Context score: $CONTEXT_SCORE"

if [ "$CONTEXT_SCORE" -gt 0 ]; then
  log "Embedded Systems project detected"
  echo "[Embedded Systems] Project context detected. Relevant plugins activated."
else
  log "No Embedded Systems context found"
fi

# Check for project-specific configuration
if [ -f "CLAUDE.md" ]; then
  log "Found project CLAUDE.md"
fi

if [ -f ".claude/settings.json" ]; then
  log "Found Claude settings"
fi

log "Session start hook complete"

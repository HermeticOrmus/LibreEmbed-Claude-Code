#!/usr/bin/env bash
# Pre-Tool-Use Hook - Embedded Systems
# Validates actions before execution.
#
# Claude Code sends the hook input as JSON on stdin. This hook asks for
# confirmation (permissionDecision "ask") before:
#   - reading or writing a secrets file (.env, .pem, .key, .p12, .pfx,
#     anything named credentials or secret)
#   - a Bash command that flashes or erases a connected target
#   - a tool whose name says it deletes, removes, drops, destroys, or forces
# Anything else exits 0 with no output. Without jq it does nothing.
set -euo pipefail
IFS=$'\n\t'

command -v jq >/dev/null 2>&1 || exit 0

INPUT="$(cat)"
TOOL_NAME="$(jq -r '.tool_name // empty' <<<"$INPUT" 2>/dev/null)" || exit 0
TARGET="$(jq -r '.tool_input.file_path // .tool_input.notebook_path // .tool_input.path // empty' <<<"$INPUT" 2>/dev/null)" || TARGET=""
COMMAND="$(jq -r '.tool_input.command // empty' <<<"$INPUT" 2>/dev/null)" || COMMAND=""

shopt -s nocasematch

ask() {
  jq -cn --arg reason "$1" \
    '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "ask", permissionDecisionReason: $reason}}'
  exit 0
}

# Safety checks
check_sensitive_files() {
  [[ -n "$TARGET" ]] || return 0
  local base="${TARGET##*/}"
  # Templates carry no secrets.
  [[ "$base" =~ ^\.env\.(example|sample|template)$ ]] && return 0
  if [[ "$base" =~ ^\.env($|\.) || "$base" =~ \.(pem|key|p12|pfx)$ || "$TARGET" =~ (credentials|secret) ]]; then
    ask "LibreEmbed: $TOOL_NAME targets a file that may hold secrets or signing keys ($base). Confirm before it is read or changed."
  fi
}

check_flash_ops() {
  [[ "$TOOL_NAME" == "Bash" && -n "$COMMAND" ]] || return 0
  local s='[^;&|]*'   # stay inside one command of a pipeline or list
  local flash_re="(^|[;&|[:space:]])("
  flash_re+="openocd${s}(program|flash[[:space:]]+(write|erase)|mass_erase)"
  flash_re+="|st-flash${s}[[:space:]](write|erase)"
  flash_re+="|STM32_Programmer_CLI${s}[[:space:]](-w|-e|-d|--write|--erase|--download)([[:space:]]|$)"
  flash_re+="|pyocd[[:space:]]+(flash|load|erase)"
  flash_re+="|nrfjprog${s}--(program|eraseall|erasepage|recover)"
  flash_re+="|esptool(\.py)?${s}[[:space:]](write[-_]flash|erase[-_]flash|erase[-_]region)"
  flash_re+="|idf\.py${s}[[:space:]](flash|app-flash|erase[-_]flash)([[:space:]]|$)"
  flash_re+="|west[[:space:]]+flash"
  flash_re+="|dfu-util${s}[[:space:]]-D"
  flash_re+="|avrdude${s}-U[[:space:]]*[a-z]+:w:"
  flash_re+="|picotool[[:space:]]+load"
  flash_re+="|(pio|platformio)[[:space:]]+run${s}(-t|--target)[[:space:]]*(upload|erase)"
  flash_re+="|JLinkExe${s}-(CommanderScript|CommandFile)"
  flash_re+="|make${s}[[:space:]]flash([[:space:]]|$)"
  flash_re+=")"
  if [[ "$COMMAND" =~ $flash_re ]]; then
    ask "LibreEmbed: this command flashes or erases a connected target. Confirm the board, the image, and that the build passed its tests."
  fi
}

check_destructive_ops() {
  if [[ "$TOOL_NAME" =~ (delete|remove|drop|destroy|force) ]]; then
    ask "LibreEmbed: the tool name $TOOL_NAME suggests a destructive operation. Confirm before it runs."
  fi
}

# Run checks
check_sensitive_files
check_flash_ops
check_destructive_ops

exit 0

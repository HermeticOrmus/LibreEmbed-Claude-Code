#!/usr/bin/env bash
# Post-Tool-Use Hook - Embedded Systems
# Verifies results after tool execution.
#
# Claude Code sends the hook input as JSON on stdin. After a Write or Edit
# this hook tells Claude (additionalContext) when:
#   - the file is empty after the write
#   - firmware source changed for the first time in the session, as a
#     reminder to rebuild and run tests before flashing (once per session;
#     the marker lives in $TMPDIR, never in the plugin directory)
# Otherwise it exits 0 with no output. Without jq it does nothing.
set -euo pipefail
IFS=$'\n\t'

command -v jq >/dev/null 2>&1 || exit 0

INPUT="$(cat)"
TOOL_NAME="$(jq -r '.tool_name // empty' <<<"$INPUT" 2>/dev/null)" || exit 0
TARGET="$(jq -r '.tool_input.file_path // empty' <<<"$INPUT" 2>/dev/null)" || TARGET=""
SESSION="$(jq -r '.session_id // empty' <<<"$INPUT" 2>/dev/null)" || SESSION=""

case "$TOOL_NAME" in
  Write|Edit|MultiEdit) ;;
  *) exit 0 ;;
esac
[[ -n "$TARGET" ]] || exit 0

NOTES=""
note() { NOTES="${NOTES:+$NOTES }$1"; }

# Check the file was actually written
if [[ -f "$TARGET" && ! -s "$TARGET" ]]; then
  note "WARNING: $TARGET is empty after the $TOOL_NAME."
fi

# Remind about building and testing after firmware changes, once per session
if [[ -n "$SESSION" && "$TARGET" =~ \.(c|h|cc|cpp|hpp|s|S|ld|lds|icf|dts|dtsi|overlay)$ ]]; then
  MARKER="${TMPDIR:-/tmp}/libre-embed-hooks-${SESSION//[^A-Za-z0-9_-]/}.reminded"
  if [[ ! -e "$MARKER" ]] && : >"$MARKER" 2>/dev/null; then
    note "REMINDER: firmware source changed (${TARGET##*/}). Rebuild and run the tests before flashing a target."
  fi
fi

[[ -n "$NOTES" ]] || exit 0

jq -cn --arg ctx "$NOTES" \
  '{hookSpecificOutput: {hookEventName: "PostToolUse", additionalContext: $ctx}}'
exit 0

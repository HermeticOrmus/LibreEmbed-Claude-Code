# LibreEmbed Hooks

> Optional safety hooks for firmware work: a confirmation before flash, erase, and secret-file operations, embedded project detection at session start, and a check for empty files after edits.

## Overview

Firmware work has two expensive mistakes that an agent can make in one tool call: writing the wrong image to the board on your desk, and reading or rewriting a signing key. This plugin puts a confirmation in front of both. It is separate from the fifteen knowledge plugins so you can leave it out, and it stays silent unless one of its checks matches.

Claude Code sends every hook its input as JSON on stdin. The three scripts in `hooks/` read that JSON with `jq`, and `hooks/hooks.json` registers them through `${CLAUDE_PLUGIN_ROOT}`.

## What each hook does

| Event | Script | Behavior |
|---|---|---|
| `SessionStart` | `session-start.sh` | When the working directory looks like firmware (for example `platformio.ini`, a Zephyr `prj.conf`, an ESP-IDF `sdkconfig`, a linker script, a `.ioc` file, `FreeRTOSConfig.h`, or `arm-none-eabi` in the build files), prints one context line asking Claude to confirm the target MCU, toolchain, and RTOS before giving part-specific advice. Prints nothing otherwise. |
| `PreToolUse` | `pre-tool-use.sh` | Returns a `permissionDecision` of `ask` before a file tool touches `.env` files (templates such as `.env.example` excluded), `.pem`, `.key`, `.p12`, or `.pfx` files, or any path containing `credentials` or `secret`; before a Bash command that flashes or erases a target (OpenOCD `program`, `st-flash write`, `STM32_Programmer_CLI -w`, `pyocd flash`, `nrfjprog --program`, `esptool write_flash`, `idf.py flash`, `west flash`, `dfu-util -D`, `avrdude -U ...:w:`, `picotool load`, `pio run -t upload`, `make flash`, J-Link Commander scripts, and erase variants); and before any tool whose name contains delete, remove, drop, destroy, or force. Exits 0 with no output otherwise. |
| `PostToolUse` | `post-tool-use.sh` | After `Write` or `Edit`, tells Claude when the file is empty, and the first time firmware source (`.c`, `.h`, `.cpp`, `.s`, `.ld`, `.dts`, and similar) changes in a session, reminds it to rebuild and run the tests before flashing. The once-per-session marker lives in `$TMPDIR`, never in the plugin directory. |

No hook writes log files. Without `jq` on your `PATH`, the hooks do nothing.

## Install

```text
/plugin marketplace add HermeticOrmus/LibreEmbed-Claude-Code
/plugin install libre-embed-hooks@libre-embed
```

From a terminal: `claude plugin install libre-embed-hooks@libre-embed`. The repo's `./setup.sh` installs it with the other plugins; `./setup.sh --no-safety-hooks` leaves it out.

To turn it off later: `claude plugin disable libre-embed-hooks@libre-embed`.

## Test a hook by hand

```bash
echo '{"tool_name":"Bash","tool_input":{"command":"west flash"}}' | bash hooks/pre-tool-use.sh
echo '{"tool_name":"Read","tool_input":{"file_path":"keys/signing.pem"}}' | bash hooks/pre-tool-use.sh
echo '{"cwd":"'"$PWD"'"}' | bash hooks/session-start.sh
```

The first two print the `ask` decision as JSON; the third prints a context line only inside a firmware project.

## Limitations

- Flash detection matches command names and flags. A custom script that flashes under another name (for example `./tools/burn.sh`) is not recognized; add its name to `check_flash_ops` in `pre-tool-use.sh` if you want the prompt.
- The hooks ask for confirmation; they never deny a tool call outright.

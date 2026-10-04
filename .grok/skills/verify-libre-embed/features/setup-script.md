# Install from a clone with setup.sh

A user who cloned LibreEmbed-Claude-Code runs `./setup.sh` to register the checkout as a marketplace and install its plugins through the Claude Code CLI, or through Grok Build with `--grok`. The script can also list the pack, install a subset and uninstall.

## Sub-features

- `setup-list` prints the plugins in the pack.
- `setup-only` installs only the named plugins.
- `setup-all` installs every plugin.
- `setup-grok` does the same through the Grok Build CLI.
- `setup-uninstall` removes the pack's plugins and its marketplace.
- `setup-no-safety-hooks` installs the pack without the safety hooks plugin (`--no-safety-hooks`).

## How to get to it (user POV)

- `git clone https://github.com/HermeticOrmus/LibreEmbed-Claude-Code.git`, then `cd LibreEmbed-Claude-Code` and `./setup.sh`.
- `./setup.sh --list`, `./setup.sh --only rtos-patterns`, `./setup.sh --grok`, `./setup.sh --uninstall`.
- `./setup.sh --help` prints the options.
- `./setup.sh --no-safety-hooks` skips the safety hooks plugin.

## Driving it with control-libre-embed

Preconditions:

- A run with clean configs exists. Start one with `.grok/skills/verify-libre-embed/bin/control-libre-embed install --claude --only rtos-patterns` (or any `install`), so `setup.sh` runs against empty configs.

- **List the pack.** Run `.grok/skills/verify-libre-embed/bin/control-libre-embed setup --list`. The log lists the plugins in `.claude-plugin/marketplace.json` and ends in `exit 0`.
- **Install a subset.** Run `.grok/skills/verify-libre-embed/bin/control-libre-embed setup --only rtos-patterns`. The log ends in `exit 0`, and `CLAUDE_CONFIG_DIR="$(readlink -f ~/.local/share/verify-libre-embed/runs/latest)/scratch/claude-config" claude plugin list` shows `rtos-patterns@libre-embed` enabled.
- **Grok mode.** Run `.grok/skills/verify-libre-embed/bin/control-libre-embed setup --grok --only rtos-patterns`. The log ends in `exit 0`.
- **Uninstall.** Run `.grok/skills/verify-libre-embed/bin/control-libre-embed setup --uninstall`. The log ends in `exit 0`, and the same `claude plugin list` no longer shows `@libre-embed` plugins.
- **Proof.** Keep the `evidence/setup-<n>.log` files, then run `.grok/skills/verify-libre-embed/bin/control-libre-embed cleanup`.

## Gotchas

- `setup.sh` installs into whatever config `CLAUDE_CONFIG_DIR` and `GROK_HOME` point at. Run it through the helper, or it installs into your own setup.
- `--scope` is Claude Code only; with `--grok` it is ignored.
- `--plugins-dir` is accepted for old commands but no longer used.

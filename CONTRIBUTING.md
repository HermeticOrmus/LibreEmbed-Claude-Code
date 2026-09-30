# Contributing

Embedded is a wide field and no single bundle can cover it all. PRs are welcome — especially for vendor-specific HALs, additional RTOSes, regional certifications, and real-hardware worked examples.

## What we welcome

- **Bug fixes** in any plugin (agent, command, or skill content)
- **Vendor HAL support** (we lean on CMSIS today; vendor HALs like ST HAL, Microchip MCC, Nordic nRFx need their own sub-skills)
- **Additional RTOSes** (ThreadX, RT-Thread, NuttX, ChibiOS, embOS — depth varies today; PRs welcome to deepen)
- **Toolchain support** (Microchip XC32, Renesas e², IAR EWARM, Keil µVision — currently GCC-centric)
- **Worked examples on real hardware** — the more concrete board bring-ups, the more credible the bundle. Schematics + photos + the resulting firmware all welcome.
- **Regional certifications** (CCC China, KC Korea, ANATEL Brazil) — the safety-critical plugin is currently Western-cert-centric
- **Translations** of the learning paths (especially Chinese, Spanish, Portuguese, German — large embedded developer populations under-served by English-only resources)

## What we don't accept

- Closed-source dependencies in core plugin content (MIT-compatible only)
- Plugins that require a specific paid IDE without a free tier alternative
- Content that copies vendor documentation verbatim — vendor docs are vendor docs; the value here is the agent reasoning around them
- AI-generated content with no real-hardware verification — for embedded specifically, hallucinated register addresses or HAL function signatures are worse than no content

## Setup

```bash
git clone https://github.com/<your-username>/LibreEmbed-Claude-Code.git
cd LibreEmbed-Claude-Code
./setup.sh
```

Make changes, test against real or simulated hardware, then submit.

## Verifying plugin changes

For agent + command edits:

1. Make the edit
2. Validate it: `claude plugin validate plugins/<name>` (CI runs the same check, plus a clean install of every plugin, on each PR)
3. Start a session that loads your working copy: `claude --plugin-dir plugins/<name>` (no reinstall needed; plugin changes don't hot-reload, so restart this session after further edits)
4. Invoke the agent / command with a realistic embedded scenario
5. Confirm the response is more substantive than the templated baseline

For skill edits:

- Skills are reference material; verification is "does this answer the question someone would have when they hit this scenario?"
- Add at least one example showing the skill being applied if introducing a new pattern

## Branch + PR workflow

```
git checkout -b feat/<slug>     # new plugin or major content addition
git checkout -b fix/<slug>      # bug fix
git checkout -b deepen/<plugin> # deepening an existing thin plugin
git checkout -b docs/<slug>     # docs only
```

Commit messages: `type(scope): description` — e.g., `deepen(rtos-patterns): add Zephyr workqueue patterns + DPC equivalents`.

PR template:

```markdown
## Why
<motivation in 1-3 sentences — what problem does this solve, what gap does it close>

## What changed
<bulleted list of concrete changes>

## How to verify
<commands to run, or scenarios to pose to the agent + expected response shape>

## Real-hardware verification (if applicable)
<which board, which toolchain, which probe — the more specific the better>

## Notes
<follow-ups, related issues, depth assessment>
```

## Plugin-authoring conventions

Each plugin lives in `plugins/<name>/` with a manifest and three subdirectories, in the layout Claude Code loads:

```text
plugins/<name>/
├── .claude-plugin/
│   └── plugin.json   # name, version, description, author, keywords
├── README.md         # overview of what the plugin covers + when to use
├── agents/
│   └── <name>.md     # specialist agent prompt with capabilities + principles
├── commands/
│   └── <name>.md     # slash command logic with concrete code samples
└── skills/
    └── <name>/
        └── SKILL.md  # reference pattern library
```

A new plugin also needs an entry in `.claude-plugin/marketplace.json`, with the same one-sentence description as its `plugin.json`.

Frontmatter is what Claude Code reads to decide when to use a component, so write it as routing text:

- Agents: `name`, `description` in the form "Use this agent when <situations>. <What it returns>.", and `model: inherit`
- Commands: `description` (what running it does) and `argument-hint` when it takes arguments
- Skills: `name` and `description` in the form "<What it provides>. Use when <situations>."

### Agent prompts

Should include:

- A `name:` and `description:` frontmatter (see the routing-text forms above)
- A clear "Purpose" section
- "Core Principles" — what biases this agent has
- "Capabilities" — what it knows about, in detail
- Real-hardware grounding — reference specific MCUs, toolchains, probes by name where applicable
- Aim for 150-300 lines of substantive content

### Commands

Should include:

- A clear job-to-be-done framing
- At least one concrete code example with real types, real function names, real headers
- A worked example from problem statement to working code
- Awareness of common embedded traps (volatile, memory barriers, DMA cache coherency, etc.)
- Aim for 200-400 lines

### Skills

Should include:

- A pattern library, not a tutorial
- Cross-references to other plugins where relevant
- Common-mistakes section
- Real-board notes where applicable
- Aim for 100-200 lines

## The substance bar

LibreEmbed is being deepened to match LibreUIUX-Claude-Code substance — real agent expertise, real code, real hardware grounding. The per-plugin maturity matrix in [CHANGELOG.md](CHANGELOG.md) tracks which plugins are "depth-complete" vs. "to be deepened." If you're adding a new plugin, please contribute it at the depth-complete bar from the start.

## Code of conduct

See [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).

## License

By submitting a PR you agree your contribution is licensed under the same MIT license as the project. No CLA.

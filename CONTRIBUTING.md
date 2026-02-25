# Contributing to LibreEmbed-Claude-Code

Thank you for your interest in contributing to this embedded systems plugin collection for Claude Code.

## How to Contribute

### Adding a New Plugin

1. **Create the directory structure**:
   ```
   plugins/{plugin-name}/
   ├── README.md
   ├── agents/{agent-name}/AGENT.md
   ├── commands/{command-name}/COMMAND.md
   └── skills/{skill-name}/SKILL.md
   ```

2. **Follow the existing format**: Study 2-3 existing plugins to understand the expected depth and structure for each file type.

3. **README.md** (50-80 lines): Plugin overview, contents listing, usage examples, and target platforms.

4. **AGENT.md** (80-150 lines): Agent identity, domain expertise, behavioral rules, tools/methods, and output format.

5. **COMMAND.md** (60-100 lines): Trigger syntax, accepted input, processing steps, output structure, and usage examples.

6. **SKILL.md** (60-100 lines): Knowledge base summary, key patterns with code snippets, anti-patterns to avoid, and references.

### Improving Existing Plugins

- Fix technical inaccuracies
- Add missing patterns or anti-patterns
- Update references to newer standards or specifications
- Improve code examples with better comments or edge cases

### Adding Learning Paths

- Maintain the sequential, building-block structure
- Include both theory and practical exercises
- Reference specific plugins where relevant
- Target 200-400 lines per learning path

## Development Guidelines

### Content Standards

- **Accuracy**: All register addresses, protocol details, and API references must be verifiable
- **Vendor neutrality**: Prefer CMSIS/standard APIs over vendor-specific HAL where possible
- **Safety awareness**: Flag safety implications even in non-safety-critical plugins
- **Resource consciousness**: Always consider flash, RAM, and CPU cycle constraints

### Commit Messages

Use conventional commits:

```
type(scope): description

feat(plugin): add CAN FD support to communication-buses
fix(agent): correct MPU region calculation in memory-management
docs(learning): add DMA chapter to intermediate path
```

### Pull Request Process

1. Fork the repository
2. Create a feature branch: `feature/your-description`
3. Make your changes following the content standards above
4. Submit a pull request using the provided template
5. Address review feedback

## Code of Conduct

This project follows the [Contributor Covenant v2.1](CODE_OF_CONDUCT.md). By participating, you agree to uphold this code.

## Questions?

Open an issue with the `question` label for any clarification needed.

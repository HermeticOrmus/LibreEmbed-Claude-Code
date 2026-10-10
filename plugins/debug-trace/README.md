# Debug Trace

JTAG, SWD, printf debugging, trace analysis, fault handlers

## What's Included

### Agents
- **Debug Engineer** - Specialized agent for JTAG, SWD, printf debugging, trace analysis, fault handlers

### Commands
- `/debug-trace:debug-embedded` - Quick-access command for debug-trace workflows

### Skills
- **Debug Trace Patterns** - Pattern library and knowledge base for debug-trace

## Quick Start

1. Install it: `/plugin install debug-trace@libre-embed` (after `/plugin marketplace add HermeticOrmus/LibreEmbed-Claude-Code`)
2. Use the agent for guided, multi-step workflows
3. Use the command for quick, targeted operations
4. Reference the skill for patterns and best practices

## Usage Examples

```
# Generate debugger connection commands
/debug-trace:debug-embedded attach --probe stlink --target stm32f4x

# Inspect registers on a halted target
/debug-trace:debug-embedded halt --dump-registers

# Reference patterns from the skill
"Apply debug-trace-patterns patterns to this implementation"
```

## Key Patterns

- Follow established conventions for debug-trace
- Validate inputs before processing
- Document decisions and rationale
- Test outputs against requirements
- Iterate based on feedback

## Related Plugins

Check the main README for related plugins in this collection.

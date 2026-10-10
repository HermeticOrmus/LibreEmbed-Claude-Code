# Safety Critical

IEC 61508, DO-178C, MISRA C, static analysis, certification

## What's Included

### Agents
- **Safety Engineer** - Specialized agent for IEC 61508, DO-178C, MISRA C, static analysis, certification

### Commands
- `/safety-critical:safety` - Quick-access command for safety-critical workflows

### Skills
- **Safety Critical Patterns** - Pattern library and knowledge base for safety-critical

## Quick Start

1. Install it: `/plugin install safety-critical@libre-embed` (after `/plugin marketplace add HermeticOrmus/LibreEmbed-Claude-Code`)
2. Use the agent for guided, multi-step workflows
3. Use the command for quick, targeted operations
4. Reference the skill for patterns and best practices

## Usage Examples

```
# Check a source file against MISRA rules
/safety-critical:safety analyze --file src/motor_control.c --ruleset misra-2012

# Rewrite a function to comply with a rule
/safety-critical:safety enforce --function process_command --rule 15.5

# Reference patterns from the skill
"Apply safety-critical-patterns patterns to this implementation"
```

## Key Patterns

- Follow established conventions for safety-critical
- Validate inputs before processing
- Document decisions and rationale
- Test outputs against requirements
- Iterate based on feedback

## Related Plugins

Check the main README for related plugins in this collection.

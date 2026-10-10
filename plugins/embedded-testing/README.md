# Embedded Testing

Unit testing on target, HIL testing, mocking hardware

## What's Included

### Agents
- **Embedded Test Engineer** - Specialized agent for Unit testing on target, HIL testing, mocking hardware

### Commands
- `/embedded-testing:embedded-test` - Quick-access command for embedded-testing workflows

### Skills
- **Embedded Testing Patterns** - Pattern library and knowledge base for embedded-testing

## Quick Start

1. Install it: `/plugin install embedded-testing@libre-embed` (after `/plugin marketplace add HermeticOrmus/LibreEmbed-Claude-Code`)
2. Use the agent for guided, multi-step workflows
3. Use the command for quick, targeted operations
4. Reference the skill for patterns and best practices

## Usage Examples

```
# Generate unit tests for a sensor module
/embedded-testing:embedded-test unit --module sensor --hal i2c

# Generate mocks for an I2C interface
/embedded-testing:embedded-test mock --header hal_i2c.h --output test/mocks/

# Reference patterns from the skill
"Apply embedded-testing-patterns patterns to this implementation"
```

## Key Patterns

- Follow established conventions for embedded-testing
- Validate inputs before processing
- Document decisions and rationale
- Test outputs against requirements
- Iterate based on feedback

## Related Plugins

Check the main README for related plugins in this collection.

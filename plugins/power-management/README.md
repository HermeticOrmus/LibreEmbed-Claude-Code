# Power Management

Sleep modes, power budgeting, energy harvesting, battery

## What's Included

### Agents
- **Power Engineer** - Specialized agent for Sleep modes, power budgeting, energy harvesting, battery

### Commands
- `/power-management:power` - Quick-access command for power-management workflows

### Skills
- **Power Mgmt Patterns** - Pattern library and knowledge base for power-management

## Quick Start

1. Install it: `/plugin install power-management@libre-embed` (after `/plugin marketplace add HermeticOrmus/LibreEmbed-Claude-Code`)
2. Use the agent for guided, multi-step workflows
3. Use the command for quick, targeted operations
4. Reference the skill for patterns and best practices

## Usage Examples

```
# Estimate power use from an activity profile
/power-management:power analyze --mcu stm32l476 --active-current 8mA --active-ms 100 --interval-s 60

# Configure Stop2 sleep with an EXTI wake source
/power-management:power configure --mcu stm32l476 --mode stop2 --wakeup exti --pin PA0

# Reference patterns from the skill
"Apply power-mgmt-patterns patterns to this implementation"
```

## Key Patterns

- Follow established conventions for power-management
- Validate inputs before processing
- Document decisions and rationale
- Test outputs against requirements
- Iterate based on feedback

## Related Plugins

Check the main README for related plugins in this collection.

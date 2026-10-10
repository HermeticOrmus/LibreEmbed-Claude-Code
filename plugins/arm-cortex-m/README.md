# Arm Cortex M

ARM Cortex-M programming, CMSIS, HAL, startup code

## What's Included

### Agents
- **Cortex M Engineer** - Specialized agent for ARM Cortex-M programming, CMSIS, HAL, startup code

### Commands
- `/arm-cortex-m:cortex-m` - Quick-access command for arm-cortex-m workflows

### Skills
- **Cortex M Patterns** - Pattern library and knowledge base for arm-cortex-m

## Quick Start

1. Install it: `/plugin install arm-cortex-m@libre-embed` (after `/plugin marketplace add HermeticOrmus/LibreEmbed-Claude-Code`)
2. Use the agent for guided, multi-step workflows
3. Use the command for quick, targeted operations
4. Reference the skill for patterns and best practices

## Usage Examples

```
# Generate startup code and a linker script
/arm-cortex-m:cortex-m init --mcu stm32f407 --flash 1024K --sram 192K --ccm 64K

# Configure interrupt priority grouping
/arm-cortex-m:cortex-m configure --subsystem nvic --groups 4

# Reference patterns from the skill
"Apply cortex-m-patterns patterns to this implementation"
```

## Key Patterns

- Follow established conventions for arm-cortex-m
- Validate inputs before processing
- Document decisions and rationale
- Test outputs against requirements
- Iterate based on feedback

## Related Plugins

Check the main README for related plugins in this collection.

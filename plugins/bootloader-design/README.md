# Bootloader Design

Bootloader architecture, firmware update mechanisms, secure boot

## What's Included

### Agents
- **Bootloader Engineer** - Specialized agent for Bootloader architecture, firmware update mechanisms, secure boot

### Commands
- `/bootloader-design:bootloader` - Quick-access command for bootloader-design workflows

### Skills
- **Bootloader Patterns** - Pattern library and knowledge base for bootloader-design

## Quick Start

1. Install it: `/plugin install bootloader-design@libre-embed` (after `/plugin marketplace add HermeticOrmus/LibreEmbed-Claude-Code`)
2. Use the agent for guided, multi-step workflows
3. Use the command for quick, targeted operations
4. Reference the skill for patterns and best practices

## Usage Examples

```
# Design a dual-bank bootloader
/bootloader-design:bootloader design --mcu stm32f407 --banks dual --transport uart

# Generate image verification code
/bootloader-design:bootloader verify --method crc32

# Reference patterns from the skill
"Apply bootloader-patterns patterns to this implementation"
```

## Key Patterns

- Follow established conventions for bootloader-design
- Validate inputs before processing
- Document decisions and rationale
- Test outputs against requirements
- Iterate based on feedback

## Related Plugins

Check the main README for related plugins in this collection.

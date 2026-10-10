# Memory Management

Static allocation, memory pools, stack/heap analysis, MPU

## What's Included

### Agents
- **Memory Engineer** - Specialized agent for Static allocation, memory pools, stack/heap analysis, MPU

### Commands
- `/memory-management:memory` - Quick-access command for memory-management workflows

### Skills
- **Memory Mgmt Patterns** - Pattern library and knowledge base for memory-management

## Quick Start

1. Install it: `/plugin install memory-management@libre-embed` (after `/plugin marketplace add HermeticOrmus/LibreEmbed-Claude-Code`)
2. Use the agent for guided, multi-step workflows
3. Use the command for quick, targeted operations
4. Reference the skill for patterns and best practices

## Usage Examples

```
# Analyze memory usage from an ELF file
/memory-management:memory analyze --elf firmware.elf

# Generate a fixed-block memory pool
/memory-management:memory pool --type msg_t --count 32 --thread-safe freertos

# Reference patterns from the skill
"Apply memory-mgmt-patterns patterns to this implementation"
```

## Key Patterns

- Follow established conventions for memory-management
- Validate inputs before processing
- Document decisions and rationale
- Test outputs against requirements
- Iterate based on feedback

## Related Plugins

Check the main README for related plugins in this collection.

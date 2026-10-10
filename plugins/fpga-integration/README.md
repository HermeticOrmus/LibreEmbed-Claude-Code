# Fpga Integration

FPGA/MCU integration, HDL basics, soft cores, IP blocks

## What's Included

### Agents
- **Fpga Engineer** - Specialized agent for FPGA/MCU integration, HDL basics, soft cores, IP blocks

### Commands
- `/fpga-integration:fpga` - Quick-access command for fpga-integration workflows

### Skills
- **Fpga Patterns** - Pattern library and knowledge base for fpga-integration

## Quick Start

1. Install it: `/plugin install fpga-integration@libre-embed` (after `/plugin marketplace add HermeticOrmus/LibreEmbed-Claude-Code`)
2. Use the agent for guided, multi-step workflows
3. Use the command for quick, targeted operations
4. Reference the skill for patterns and best practices

## Usage Examples

```
# Design an AXI-Lite register interface
/fpga-integration:fpga design --module axi-lite-slave --regs 8 --data-width 32

# Generate a synthesis flow
/fpga-integration:fpga synthesize --tool vivado --part xc7a35tcpg236-1 --top my_top

# Reference patterns from the skill
"Apply fpga-patterns patterns to this implementation"
```

## Key Patterns

- Follow established conventions for fpga-integration
- Validate inputs before processing
- Document decisions and rationale
- Test outputs against requirements
- Iterate based on feedback

## Related Plugins

Check the main README for related plugins in this collection.

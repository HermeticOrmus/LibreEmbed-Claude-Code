# Embedded Linux

Yocto, Buildroot, device trees, kernel modules

## What's Included

### Agents
- **Embedded Linux Engineer** - Specialized agent for Yocto, Buildroot, device trees, kernel modules

### Commands
- `/embedded-linux:embedded-linux` - Quick-access command for embedded-linux workflows

### Skills
- **Embedded Linux Patterns** - Pattern library and knowledge base for embedded-linux

## Quick Start

1. Install it: `/plugin install embedded-linux@libre-embed` (after `/plugin marketplace add HermeticOrmus/LibreEmbed-Claude-Code`)
2. Use the agent for guided, multi-step workflows
3. Use the command for quick, targeted operations
4. Reference the skill for patterns and best practices

## Usage Examples

```
# Generate a Yocto build configuration
/embedded-linux:embedded-linux build --bsp imx6ul --distro yocto --image core-image-minimal

# Generate a kernel module skeleton
/embedded-linux:embedded-linux module --type platform --name mydriver --bus i2c

# Reference patterns from the skill
"Apply embedded-linux-patterns patterns to this implementation"
```

## Key Patterns

- Follow established conventions for embedded-linux
- Validate inputs before processing
- Document decisions and rationale
- Test outputs against requirements
- Iterate based on feedback

## Related Plugins

Check the main README for related plugins in this collection.

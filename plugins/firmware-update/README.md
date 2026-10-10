# Firmware Update

OTA updates, firmware versioning, rollback mechanisms

## What's Included

### Agents
- **Fota Engineer** - Specialized agent for OTA updates, firmware versioning, rollback mechanisms

### Commands
- `/firmware-update:firmware-update` - Quick-access command for firmware-update workflows

### Skills
- **Firmware Update Patterns** - Pattern library and knowledge base for firmware-update

## Quick Start

1. Install it: `/plugin install firmware-update@libre-embed` (after `/plugin marketplace add HermeticOrmus/LibreEmbed-Claude-Code`)
2. Use the agent for guided, multi-step workflows
3. Use the command for quick, targeted operations
4. Reference the skill for patterns and best practices

## Usage Examples

```
# Package a signed firmware image
/firmware-update:firmware-update package --tool imgtool --key ecdsa-p256.pem --version 2.1.0 --slot-size 0x70000

# Design firmware distribution over MQTT
/firmware-update:firmware-update distribute --transport mqtt --broker mosquitto --topic-prefix device/fw

# Reference patterns from the skill
"Apply firmware-update-patterns patterns to this implementation"
```

## Key Patterns

- Follow established conventions for firmware-update
- Validate inputs before processing
- Document decisions and rationale
- Test outputs against requirements
- Iterate based on feedback

## Related Plugins

Check the main README for related plugins in this collection.

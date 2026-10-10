# Sensor Integration

Sensor drivers, calibration, filtering, fusion algorithms

## What's Included

### Agents
- **Sensor Engineer** - Specialized agent for Sensor drivers, calibration, filtering, fusion algorithms

### Commands
- `/sensor-integration:sensor` - Quick-access command for sensor-integration workflows

### Skills
- **Sensor Patterns** - Pattern library and knowledge base for sensor-integration

## Quick Start

1. Install it: `/plugin install sensor-integration@libre-embed` (after `/plugin marketplace add HermeticOrmus/LibreEmbed-Claude-Code`)
2. Use the agent for guided, multi-step workflows
3. Use the command for quick, targeted operations
4. Reference the skill for patterns and best practices

## Usage Examples

```
# Generate a BME280 I2C driver
/sensor-integration:sensor driver --part bme280 --bus i2c --addr 0x76

# Generate two-point temperature calibration
/sensor-integration:sensor calibrate --method 2-point --units celsius --range "-40,85"

# Reference patterns from the skill
"Apply sensor-patterns patterns to this implementation"
```

## Key Patterns

- Follow established conventions for sensor-integration
- Validate inputs before processing
- Document decisions and rationale
- Test outputs against requirements
- Iterate based on feedback

## Related Plugins

Check the main README for related plugins in this collection.

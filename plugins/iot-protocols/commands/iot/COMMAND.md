# /iot

A quick-access command for iot-protocols workflows in Claude Code.

## Trigger

`/iot [action] [options]`

## Input

### Actions
- `analyze` - Analyze existing iot-protocols implementation
- `generate` - Generate new iot-protocols artifacts
- `improve` - Suggest improvements to current implementation
- `validate` - Check implementation against best practices
- `document` - Generate documentation for iot-protocols artifacts

### Options
- `--context <path>` - Specify the file or directory to operate on
- `--format <type>` - Output format (markdown, json, yaml)
- `--verbose` - Include detailed explanations
- `--dry-run` - Preview changes without applying them

## Process

### Step 1: Context Gathering
- Read relevant files and configuration
- Identify the current state of iot-protocols artifacts
- Determine applicable standards and conventions

### Step 2: Analysis
- Evaluate against iot-protocol-patterns patterns
- Identify gaps, issues, and opportunities
- Prioritize findings by impact and effort

### Step 3: Execution
- Apply the requested action
- Generate or modify artifacts as needed
- Validate changes against requirements

### Step 4: Output
- Present results in the requested format
- Include actionable next steps
- Flag any items requiring human decision

## Output

### Success
```
## Iot Protocols - [Action] Complete

### Changes Made
- [List of changes]

### Validation
- [Checks passed]

### Next Steps
- [Recommended follow-up actions]
```

### Error
```
## Iot Protocols - [Action] Failed

### Issue
[Description of the problem]

### Suggested Fix
[How to resolve the issue]
```

## Examples

```bash
# Analyze current implementation
/iot analyze

# Generate new artifacts
/iot generate --context ./src

# Validate against best practices
/iot validate --verbose

# Generate documentation
/iot document --format markdown
```

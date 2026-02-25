# /firmware-update

A quick-access command for firmware-update workflows in Claude Code.

## Trigger

`/firmware-update [action] [options]`

## Input

### Actions
- `analyze` - Analyze existing firmware-update implementation
- `generate` - Generate new firmware-update artifacts
- `improve` - Suggest improvements to current implementation
- `validate` - Check implementation against best practices
- `document` - Generate documentation for firmware-update artifacts

### Options
- `--context <path>` - Specify the file or directory to operate on
- `--format <type>` - Output format (markdown, json, yaml)
- `--verbose` - Include detailed explanations
- `--dry-run` - Preview changes without applying them

## Process

### Step 1: Context Gathering
- Read relevant files and configuration
- Identify the current state of firmware-update artifacts
- Determine applicable standards and conventions

### Step 2: Analysis
- Evaluate against firmware-update-patterns patterns
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
## Firmware Update - [Action] Complete

### Changes Made
- [List of changes]

### Validation
- [Checks passed]

### Next Steps
- [Recommended follow-up actions]
```

### Error
```
## Firmware Update - [Action] Failed

### Issue
[Description of the problem]

### Suggested Fix
[How to resolve the issue]
```

## Examples

```bash
# Analyze current implementation
/firmware-update analyze

# Generate new artifacts
/firmware-update generate --context ./src

# Validate against best practices
/firmware-update validate --verbose

# Generate documentation
/firmware-update document --format markdown
```

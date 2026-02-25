# /cortex-m

A quick-access command for arm-cortex-m workflows in Claude Code.

## Trigger

`/cortex-m [action] [options]`

## Input

### Actions
- `analyze` - Analyze existing arm-cortex-m implementation
- `generate` - Generate new arm-cortex-m artifacts
- `improve` - Suggest improvements to current implementation
- `validate` - Check implementation against best practices
- `document` - Generate documentation for arm-cortex-m artifacts

### Options
- `--context <path>` - Specify the file or directory to operate on
- `--format <type>` - Output format (markdown, json, yaml)
- `--verbose` - Include detailed explanations
- `--dry-run` - Preview changes without applying them

## Process

### Step 1: Context Gathering
- Read relevant files and configuration
- Identify the current state of arm-cortex-m artifacts
- Determine applicable standards and conventions

### Step 2: Analysis
- Evaluate against cortex-m-patterns patterns
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
## Arm Cortex M - [Action] Complete

### Changes Made
- [List of changes]

### Validation
- [Checks passed]

### Next Steps
- [Recommended follow-up actions]
```

### Error
```
## Arm Cortex M - [Action] Failed

### Issue
[Description of the problem]

### Suggested Fix
[How to resolve the issue]
```

## Examples

```bash
# Analyze current implementation
/cortex-m analyze

# Generate new artifacts
/cortex-m generate --context ./src

# Validate against best practices
/cortex-m validate --verbose

# Generate documentation
/cortex-m document --format markdown
```

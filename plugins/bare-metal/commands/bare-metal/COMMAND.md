# /bare-metal

A quick-access command for bare-metal workflows in Claude Code.

## Trigger

`/bare-metal [action] [options]`

## Input

### Actions
- `analyze` - Analyze existing bare-metal implementation
- `generate` - Generate new bare-metal artifacts
- `improve` - Suggest improvements to current implementation
- `validate` - Check implementation against best practices
- `document` - Generate documentation for bare-metal artifacts

### Options
- `--context <path>` - Specify the file or directory to operate on
- `--format <type>` - Output format (markdown, json, yaml)
- `--verbose` - Include detailed explanations
- `--dry-run` - Preview changes without applying them

## Process

### Step 1: Context Gathering
- Read relevant files and configuration
- Identify the current state of bare-metal artifacts
- Determine applicable standards and conventions

### Step 2: Analysis
- Evaluate against bare-metal-patterns patterns
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
## Bare Metal - [Action] Complete

### Changes Made
- [List of changes]

### Validation
- [Checks passed]

### Next Steps
- [Recommended follow-up actions]
```

### Error
```
## Bare Metal - [Action] Failed

### Issue
[Description of the problem]

### Suggested Fix
[How to resolve the issue]
```

## Examples

```bash
# Analyze current implementation
/bare-metal analyze

# Generate new artifacts
/bare-metal generate --context ./src

# Validate against best practices
/bare-metal validate --verbose

# Generate documentation
/bare-metal document --format markdown
```

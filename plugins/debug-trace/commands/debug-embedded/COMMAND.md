# /debug-embedded

A quick-access command for debug-trace workflows in Claude Code.

## Trigger

`/debug-embedded [action] [options]`

## Input

### Actions
- `analyze` - Analyze existing debug-trace implementation
- `generate` - Generate new debug-trace artifacts
- `improve` - Suggest improvements to current implementation
- `validate` - Check implementation against best practices
- `document` - Generate documentation for debug-trace artifacts

### Options
- `--context <path>` - Specify the file or directory to operate on
- `--format <type>` - Output format (markdown, json, yaml)
- `--verbose` - Include detailed explanations
- `--dry-run` - Preview changes without applying them

## Process

### Step 1: Context Gathering
- Read relevant files and configuration
- Identify the current state of debug-trace artifacts
- Determine applicable standards and conventions

### Step 2: Analysis
- Evaluate against debug-trace-patterns patterns
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
## Debug Trace - [Action] Complete

### Changes Made
- [List of changes]

### Validation
- [Checks passed]

### Next Steps
- [Recommended follow-up actions]
```

### Error
```
## Debug Trace - [Action] Failed

### Issue
[Description of the problem]

### Suggested Fix
[How to resolve the issue]
```

## Examples

```bash
# Analyze current implementation
/debug-embedded analyze

# Generate new artifacts
/debug-embedded generate --context ./src

# Validate against best practices
/debug-embedded validate --verbose

# Generate documentation
/debug-embedded document --format markdown
```

# /comm-bus

A quick-access command for communication-buses workflows in Claude Code.

## Trigger

`/comm-bus [action] [options]`

## Input

### Actions
- `analyze` - Analyze existing communication-buses implementation
- `generate` - Generate new communication-buses artifacts
- `improve` - Suggest improvements to current implementation
- `validate` - Check implementation against best practices
- `document` - Generate documentation for communication-buses artifacts

### Options
- `--context <path>` - Specify the file or directory to operate on
- `--format <type>` - Output format (markdown, json, yaml)
- `--verbose` - Include detailed explanations
- `--dry-run` - Preview changes without applying them

## Process

### Step 1: Context Gathering
- Read relevant files and configuration
- Identify the current state of communication-buses artifacts
- Determine applicable standards and conventions

### Step 2: Analysis
- Evaluate against comm-bus-patterns patterns
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
## Communication Buses - [Action] Complete

### Changes Made
- [List of changes]

### Validation
- [Checks passed]

### Next Steps
- [Recommended follow-up actions]
```

### Error
```
## Communication Buses - [Action] Failed

### Issue
[Description of the problem]

### Suggested Fix
[How to resolve the issue]
```

## Examples

```bash
# Analyze current implementation
/comm-bus analyze

# Generate new artifacts
/comm-bus generate --context ./src

# Validate against best practices
/comm-bus validate --verbose

# Generate documentation
/comm-bus document --format markdown
```

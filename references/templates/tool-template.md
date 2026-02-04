# Tool Skill Template

Use this template when generating tool skills with executable scripts.

```markdown
---
name: <tool-skill-name>
description: |
  <What this tool does - 1-2 sentences>
  Input: <expected input>
  Output: <what it returns>
  Use when: <trigger conditions>
---

# /<tool-skill-name>

<Brief description of what this tool does>

## Prerequisites

- <Runtime requirement, e.g., Python 3.8+>
- <Any setup needed, e.g., API keys>

## Script

```bash
python $SKILL_DIR/scripts/<script_name>.py <REQUIRED_ARG> [OPTIONS]
```

### Parameters

| Param | Required | Default | Description |
|-------|----------|---------|-------------|
| `<ARG>` | Yes | - | <description> |
| `--option` | No | <default> | <description> |

### Example

```bash
python $SKILL_DIR/scripts/<script_name>.py input.csv --format json
```

## Output Format

```json
{
  "status": "success",
  "data": {
    <output structure>
  },
  "error": null
}
```

## Failed Attempts (from original session)

| Attempt | Why it Failed | Lesson |
|---------|---------------|--------|
| <what was tried> | <why it didn't work> | <what to do instead> |

## Fallback

If the script is unavailable, implement equivalent functionality using:
- <Alternative approach 1>
- <Alternative approach 2>

## Common Pitfalls

- <Pitfall>: <How to avoid>
```

## When Generating Tool Skills

1. Create directory: `.claude/skills/<tool-name>/`
2. Write SKILL.md with above template
3. Create `scripts/` subdirectory
4. Write the actual script file with:
   - Argument parsing (argparse, yargs, etc.)
   - JSON output format: `{"status": "success/error", "data": {...}, "error": null}`
   - Error handling
5. Create `requirements.txt` if dependencies needed

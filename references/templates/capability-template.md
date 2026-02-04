# Capability Skill Template

Use this template when generating capability skills.

```markdown
---
name: <capability-skill-name>
description: |
  <Specific action description - 1-2 sentences>
  Input: <expected input>
  Output: <what it returns>
  Use when: <trigger conditions>
---

# /<capability-skill-name>

<What this skill does - ONE specific thing>

## Input

- **Required**: <required input>
- **Optional**: <optional parameters>

## Process

### Step 1: <step name> [MUST]

<content>

### Step 2: <step name> [SHOULD]

<content>

> **Can skip if**: <condition>

## Output

Returns: <description of output format>

Example:
```
<example output>
```

## Failed Attempts (from original session)

| Attempt | Why it Failed | Lesson |
|---------|---------------|--------|
| <what was tried> | <why it didn't work> | <what to do instead> |

## Data Sources

- Primary: <main data source>
- Fallback: <alternative if primary fails>

## Common Pitfalls

- <Pitfall 1>: <How to avoid>
```

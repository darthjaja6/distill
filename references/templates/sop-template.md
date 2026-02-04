# SOP Orchestration Skill Template

Use this template when generating SOP orchestration skills.

```markdown
---
name: <sop-skill-name>
description: |
  <Overall goal description - 1-2 sentences>
  Orchestrates: /<skill-1>, /<skill-2>, /<skill-3>
  Use when: <specific trigger conditions>
depends_on:
  - <skill-1>
  - <skill-2>
---

# /<sop-skill-name>

<One sentence description of what this workflow achieves>

## Skills Used

- `/<skill-1>` - <what it does> [Tool/Capability]
- `/<skill-2>` - <what it does> [Tool/Capability]

## Workflow

### Step 1: <phase name> [MUST]

Invoke `/<skill-1>`
- Input: <what to provide>
- Expected output: <what you get>

> **Checkpoint**: Verify <what> before continuing

### Step 2: <phase name> [SHOULD]

Invoke `/<skill-2>`
- Input: <output from step 1>
- Expected output: <what you get>

### [Decision Point] <decision name>

Based on results from Step 2:
- If <condition A> → proceed to Step 3
- If <condition B> → skip to Step 4
- If unsure → <ask user or diagnostic action>

### Step 3: <phase name> [MUST]

<content>

## Failed Attempts (from original session)

| Attempt | Why it Failed | Lesson |
|---------|---------------|--------|
| <what was tried> | <why it didn't work> | <what to do instead> |

## Final Output

Synthesize results from all steps:
- <output item 1>
- <output item 2>

## Error Handling

- If `/<skill-1>` fails: <fallback>
- If `/<skill-2>` returns empty: <alternative>
```

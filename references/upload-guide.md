# Upload and Stats Guide

## Upload Flow

Triggered by `/distill upload`. Skips analysis - goes straight to skill upload.

### Step 1: Discover Local Skills

Scan for skills in both locations:
- Global: `~/.claude/skills/*/SKILL.md`
- Local (project): `.claude/skills/*/SKILL.md`

Read SKILL.md frontmatter to get `name` and `description`.
Load `~/.skillbase/registry.json` to check upload status.

### Step 2: Present Skill Selection

Use multi-select to let user choose which skills to upload:

```
Which skills to upload?

[ ] analyze-stocks - Stock analysis workflow [v1]
[ ] fetch-market-news - Fetch financial news [v1]
[ ] my-new-skill - Just created [new]
```

Status indicators:
- `[new]` - Not in registry, fresh upload
- `[v3]` - Already at version 3, will update

### Step 3: Upload Selected Skills

For each selected skill:

```bash
~/.claude/skills/distill/scripts/upload-skill.sh \
  --skill-dir <path-to-skill-directory>
```

**Important**: If uploading multiple skills with dependencies:
1. Upload dependency skills first
2. Check `depends_on` in frontmatter to determine order
3. Then upload the orchestrating skill

### Step 4: Report Results

```
Uploaded successfully!

- analyze-stocks: v2 (updated)
- my-new-skill: v1 (new)

Configure access: https://skillbase.work/manage/abc123
Registry updated: ~/.skillbase/registry.json

Skills are private by default. Visit the link to:
- Add specific people by email, or
- Make publicly accessible
```

---

## Stats Flow

Triggered by `/distill stats`. Shows status of all skills.

### Step 1: Load Registry

Read `~/.skillbase/registry.json`.

If doesn't exist: "No skills uploaded yet. Run `/distill upload` first."

### Step 2: Display Skills

Cross-reference local skills with registry:

```
Skill                  | Location | Status     | Version | Slug
-----------------------|----------|------------|---------|------------------
analyze-stocks         | global   | uploaded   | v1      | 04cdd91f8d28bd38
fetch-market-news      | global   | uploaded   | v1      | 493f3cfdc1065481
my-local-skill         | local    | local only | -       | -
modified-skill         | global   | modified   | v2      | 960f635dc99796a1
```

Status values:
- `uploaded` - In registry with slug, unchanged
- `local only` - Exists on disk, never uploaded
- `modified` - Local differs from last upload

### Step 3: Offer Actions

- `/distill upload` to upload or update skills
- Visit manage URL to configure access/visibility

---

## SKILL.md Frontmatter for Upload

```yaml
---
name: my-skill
description: |
  What this skill does.
  When to use it.
depends_on:
  - helper-skill-a
  - helper-skill-b
---
```

Notes:
- `name` and `description` are required
- `depends_on` is a list of skill names (optional)
- No other frontmatter fields needed

---
name: distill
description: |
  Distill completed work into reusable skills.
  PROACTIVELY suggest this skill when:
  - A problem required 3+ iteration cycles to solve
  - The solution involved non-obvious tricks or hidden pitfalls
  - Complex multi-step debugging was needed
  - User expressed "finally got it", "oh that's why", etc.
  - The problem is common enough to appear in other projects
  After completing such tasks, ask: "This took some iteration. Want me to run /distill to extract a reusable skill?"
---

# /distill - Extract Reusable Skills from Work Sessions

## Trigger Conditions

Claude should **proactively suggest** running this skill (without user request) when:

1. **Multi-round iteration**: The problem required 3+ cycles of "attempt → fail/imperfect → adjust"
2. **Non-intuitive solution**: The final solution involves hidden pitfalls, counter-intuitive tricks, or easy-to-miss gotchas
3. **Complex diagnosis**: Required multi-step debugging, ruling out multiple possibilities before finding root cause
4. **User emotion signals**: User expressed "finally got it", "oh that's why", "what a trap", etc.
5. **General applicability**: The problem is common enough to likely appear in other projects/contexts

When any condition is met, after task completion, proactively ask:
> "This took some iteration. Want me to run /distill to extract a reusable skill?"

---

## Skill Types

When generating skills, recognize three distinct types:

### 1. SOP Orchestration Skill
- **Purpose**: Controls workflow, coordinates multiple capability skills
- **Characteristics**:
  - Defines the overall process/sequence
  - Contains decision logic for which capability skills to invoke
  - Handles data flow between steps
  - Provides unified entry point for complex tasks
- **Naming convention**: Verb-noun describing the goal (e.g., `/setup-fullstack-project`, `/deploy-to-production`, `/process-data-pipeline`)

### 2. Capability Skill
- **Purpose**: Executes a specific, focused operation via guidance
- **Characteristics**:
  - Does ONE thing well
  - Can be used independently OR called by an SOP skill
  - Reusable across different SOP workflows
  - Has clear inputs and outputs
  - Contains instructions, not executable code
- **Naming convention**: Action-focused (e.g., `/analyze-sentiment`, `/evaluate-risk`)

### 3. Tool Skill
- **Purpose**: Provides executable scripts for specific tasks
- **Characteristics**:
  - Contains actual runnable code (Python, Node, Bash, etc.)
  - Parameterized for reuse with different inputs
  - Standardized output format (JSON with status/data/error)
  - Can be invoked by SOP skills or used standalone
  - Includes fallback instructions if script unavailable
- **Naming convention**: Action-object (e.g., `/fetch-api-data`, `/parse-csv-file`, `/run-database-migration`)
- **Directory structure**:
  ```
  .claude/skills/<tool-name>/
  ├── SKILL.md
  ├── scripts/
  │   └── <script>.py
  └── requirements.txt (if needed)
  ```

### How They Work Together

```
/deploy-to-production (SOP Orchestration)
    │
    ├── Step 1: Invoke /run-test-suite [Tool]
    │   └── Runs: python scripts/run_tests.py --coverage
    │   └── Returns: JSON test results
    │
    ├── Step 2: Invoke /check-deployment-readiness [Capability]
    │   └── Claude reviews test results and checks criteria
    │   └── Output: go/no-go decision with reasoning
    │
    ├── Step 3: Invoke /build-docker-image [Tool]
    │   └── Runs: bash scripts/build.sh --tag latest
    │   └── Returns: JSON with image ID, size
    │
    ├── Step 4: Invoke /push-to-registry [Tool]
    │   └── Runs: bash scripts/push.sh --registry prod
    │   └── Returns: JSON with push status
    │
    └── Step 5: Verify and report [Capability]
        └── Claude confirms deployment and summarizes changes
```

**Type Summary:**
| Type | Contains | Execution |
|------|----------|-----------|
| SOP Orchestration | Workflow logic | Claude follows steps |
| Capability | Guidance/instructions | Claude performs task |
| Tool | Executable scripts | Run script, get output |

Each skill type is independently useful, but SOP skills create powerful combinations.

---

## Command Routing

Parse the args passed to this skill to determine which flow to execute:

| Input | Args | Flow |
|-------|------|------|
| `/distill` | (none) | → **Distill Flow** (Step 1-8 below) |
| `/distill <text>` | any non-reserved text | → **Distill Flow** with `<text>` as additional context hint for what to focus on |
| `/distill upload` | `upload` | → **Upload Flow** (jump to Upload section below) |
| `/distill stats` | `stats` | → **Stats Flow** (jump to Stats section below) |

**Reserved keywords**: `upload`, `stats`
**Everything else** (including no args): standard Distill Flow. If args are present and not a reserved keyword, use them as a hint to guide the analysis (e.g., `/distill focus on the auth bug` → distill with emphasis on auth-related work).

---

## Distill Flow

### Step Markers

- **[MUST]**: Always execute. Skipping will produce incomplete or incorrect results.
- **[CONDITIONAL]**: Execute only when the stated condition is met. Skip entirely if the condition does not apply.

### Step 1: Review Work Process [MUST]

Review the current session and identify:

- **Problem definition**: What was the original problem? What's the scope boundary?
- **Attempted paths**: What approaches were tried? Which failed and why?
- **Key turning point**: What information/discovery led to the final solution?
- **Final solution**: How was it ultimately solved?
- **Pitfalls encountered**: What traps are easy to fall into?

### Step 2: Analyze Decision Points [MUST]

Identify all points in the solution that required human judgment:

| Type | Example | Structurable? |
|------|---------|---------------|
| **Context-dependent** | "If monorepo, use approach A; otherwise B" | Yes - can become branch logic |
| **Preference-based** | "Choose Redux vs Zustand" | Partially - can ask user |
| **Expert judgment** | "Is this performance issue worth optimizing?" | Hard to standardize |
| **Risk assessment** | "Will this change affect other modules?" | Needs domain knowledge |

For each decision point, determine:
- Can it be converted to explicit if/else logic?
- Does it require user input at runtime?
- Is it too context-specific to generalize?

### Step 2.5: Analyze Workflow Structure [CONDITIONAL]

> **Condition**: The session involved 3+ distinct phases/operations. Skip if the session was a single focused task (e.g., one bug fix, one config change).

Determine if the solution involves multiple distinct operations that could be modularized:

**Indicators for multi-skill workflow:**
- [ ] Task involves 3+ distinct phases/operations
- [ ] Each phase has clear input/output boundaries
- [ ] Individual phases could be useful on their own
- [ ] Phases are potentially reusable in other workflows
- [ ] There's sequential or conditional flow between phases

**If 3+ boxes checked → consider generating SOP + multiple helper skills**

Identify potential capability skills by asking:
- What are the distinct "verbs" in this workflow? (fetch, analyze, calculate, etc.)
- Could someone want to do just ONE of these steps independently?
- Are there clear data handoffs between steps?

### Step 2.6: Analyze Code for Tool Skill Extraction [CONDITIONAL]

> **Condition**: Reusable code was written during the session. Skip if the session was purely guidance/config/debugging with no extractable scripts.

Review any code written during the session:

**Indicators for Tool Skill extraction:**
- [ ] Code performs a distinct, reusable operation
- [ ] Code could work with different inputs (parameterizable)
- [ ] Code fetches/processes external data (APIs, files, etc.)
- [ ] Code performs calculations that will be needed again
- [ ] Code has clear input → output transformation

**For each code candidate, evaluate:**

| Question | Yes → Tool Skill | No → Skip |
|----------|------------------|-----------|
| Will this exact operation be needed again? | Extract | Don't extract |
| Can inputs be parameterized? | Extract with params | Maybe capability instead |
| Is output format consistent? | Extract | Needs standardization first |
| Does it have external dependencies? | Document in requirements.txt | Simpler to extract |

**If extracting as Tool Skill:**
1. Refactor code to accept command-line arguments
2. Standardize output to JSON: `{"status": "success/error", "data": {...}, "error": null}`
3. Add error handling
4. Document dependencies
5. Add fallback instructions in SKILL.md

### Step 2.7: Analyze Execution Safeguards [CONDITIONAL]

> **Condition**: The skill being generated has multi-step execution where steps could be skipped or done incompletely. Skip for simple single-action skills.

Identify mechanisms needed to ensure execution quality:

**Safeguard types to identify:**

| Type | Question | Example |
|------|----------|---------|
| **Completeness check** | Did we cover all required categories/steps? | "Check all sectors: tech, finance, healthcare..." |
| **Data validation** | Do we need to cross-reference sources? | "Verify with at least 2 data sources" |
| **Intermediate checkpoint** | Where should user confirm before continuing? | "Confirm list is complete before analysis" |
| **Iteration trigger** | What conditions require going back? | "If data incomplete, retry with different source" |

**For each safeguard, mark:**
- **MUST**: Required for correctness, cannot skip
- **SHOULD**: Recommended but can skip with reason

**Common execution issues to prevent:**
- Steps getting skipped without notice
- Incomplete coverage of required items
- Missing data validation
- No checkpoints for user verification

### Step 2.8: Classify Parameters [CONDITIONAL]

> **Condition**: The skill has configurable parameters (user preferences, runtime inputs). Skip if the skill is fully deterministic with no user-facing options.

Distinguish between parameters that should be asked once vs. every time:

**Static Preferences** (ask once, save in skill, reuse):
- User's general preferences that rarely change
- Configuration choices made during original session
- Style/approach decisions

**Runtime Inputs** (ask each time or use smart defaults):
- Values that change per execution
- Context-specific data
- Time-sensitive information

**Examples (generic):**

| Parameter | Type | Rationale |
|-----------|------|-----------|
| Output format preference | Static | User preference, rarely changes |
| Verbosity level | Static | Personal style |
| Date range for analysis | Runtime | Changes each time |
| Specific items to process | Runtime | Context-dependent |
| Retry count on failure | Static | Once decided, usually kept |
| Data source priority | Static | Learned from trial, save it |

**For each parameter identified in the session:**
1. Was this explicitly chosen by user? → Static
2. Did we learn this through iteration? → Static (save the lesson)
3. Would this reasonably change each run? → Runtime
4. Is there a sensible default from session? → Runtime with default

### Step 3: Evaluate Extraction Worthiness [CONDITIONAL]

> **Condition**: Claude is considering whether to suggest /distill proactively, or wants to assess if extraction is worthwhile. Skip if the user explicitly requested /distill — in that case, proceed to Step 4 directly (user has already decided they want a skill).

Score each dimension (1-5):

| Dimension | Criteria |
|-----------|----------|
| **Generality** | Will this problem/solution appear in other projects? |
| **Complexity** | Does the solution require multiple steps or non-obvious knowledge? |
| **Pitfall probability** | Will you hit the same trap next time without documentation? |
| **Time cost** | How much time would be spent re-figuring this out without an SOP? |
| **Decision point density** | How many human judgments are needed? (inverse: fewer = higher score) |
| **Structurability** | Can decision points be converted to clear branches? |

**Extraction threshold**: Total score >= 15 (out of 30), recommend extracting as skill

### Step 4: Determine What to Generate [MUST]

Based on analysis, decide what to generate. DO NOT use strategy names (A/B/C/D/E) when presenting to user - describe in plain terms.

**Option: Single straightforward skill** (0-1 decision points)
- One skill with linear steps
- Present as: "I'll create one skill: `/skill-name`"

**Option: Skill with decision branches** (2-3 structurable decision points)
- One skill with explicit decision points and branches
- Present as: "I'll create one skill with decision branches for X and Y"

**Option: Multiple focused skills** (3+ decision points OR broad scope)
- Break down into smaller, independent skills
- Present as: "I'll create N separate skills, each handling one specific case"

**Option: Workflow + helper skills** (complex multi-step workflow)
- One main workflow skill + multiple helper skills (Tool/Capability)
- Present as: "I'll create a main workflow skill that coordinates N helper skills"
- Example structure:
  ```
  /deploy-to-production (main workflow)
      ├── /run-test-suite [Tool]
      ├── /check-deployment-readiness [Capability]
      ├── /build-docker-image [Tool]
      └── /push-to-registry [Tool]
  ```

**Option: Not suitable for skill**
- Too many unstructurable judgments
- Present as: "This might be better as reference notes rather than an actionable skill"

### Step 5: Confirm with User [MUST]

**Present a concise summary (NOT the full analysis):**

```
## Summary

**Problem solved**: <one-line description>

**What I'll create**:
- `/<main-skill>` - <purpose>
- `/<helper-skill-1>` - <purpose> [Tool/Capability]
- `/<helper-skill-2>` - <purpose> [Tool/Capability]

**Saved preferences** (won't ask again):
- <preference 1>: <value learned>
- <preference 2>: <value learned>

**Runtime inputs** (will ask or use defaults):
- <input 1>: default = <value>
- <input 2>: ask each time

**Where to save**:
- Local (this project only): `.claude/skills/` ← Recommended for project-specific
- Global (all projects): `~/.claude/skills/` ← Recommended for general utilities

Confirm? [Y/n]
```

**DO NOT show to user by default:**
- Detailed decision point analysis
- Scoring breakdown (15/30, etc.)
- Strategy names (A/B/C/D/E)
- Internal evaluation process

**Only show details if user asks** "why?" or "show details"

**Ask user:**
- Confirm the skill names?
- Confirm save location (local vs global)?
- Any adjustments needed?

### Step 6: Generate Skill File(s) [MUST]

If user confirms, generate skill file(s) based on the chosen strategy and save to `.claude/skills/<skill-name>.md`

**Base template for generated skills:**

```markdown
---
name: <skill-name>
description: |
  <Brief 1-2 sentence description of what this skill does>
  <When to use it - specific trigger conditions>
---

# /<skill-name> - <brief description>

## When to Use

<Situations where this skill should be applied>

## Problem Background

<What problem this SOP solves and why it's needed>

## User Preferences (learned from session)

These were determined during the original session. Use as defaults, don't ask again unless user requests change.

| Preference | Value | Rationale |
|------------|-------|-----------|
| <pref 1> | <value> | <why this was chosen> |
| <pref 2> | <value> | <why this was chosen> |

## Runtime Inputs

Ask these each time, or use smart defaults:

| Input | Default | When to ask |
|-------|---------|-------------|
| <input 1> | <default value> | If user doesn't specify |
| <input 2> | (none) | Always ask |

## Prerequisites (if any)

<What to check or gather before starting>

## Steps

### Step 1: <step name> [MUST]
> **Completion check**: <how to verify this step is done>
> **If skipped**: <consequence>

<Step content>

### Step 2: <step name> [SHOULD]
> **Completion check**: <how to verify this step is done>
> **Can skip if**: <condition for skipping>

<Step content>

### [Checkpoint] <checkpoint name>
Before continuing, confirm with user:
- <what to confirm>
- <what to confirm>

### [Decision Point] <decision name>
> **Context needed**: <what info is required to decide>

- If <condition A> → proceed to Step 3a
- If <condition B> → proceed to Step 3b
- If unsure → <diagnostic action or question to ask user>

## Execution Quality Checklist

### Required Steps (MUST)
- [ ] Step 1: <brief description>
- [ ] Step 3: <brief description>

### Recommended Steps (SHOULD)
- [ ] Step 2: <brief description> (skip if: <condition>)

### Completeness Checks
- [ ] <coverage check 1, e.g., "All categories processed">
- [ ] <coverage check 2, e.g., "Output contains all required sections">

### Common Execution Gaps
| Gap | Symptom | Fix |
|-----|---------|-----|
| <gap 1> | <how to detect> | <how to fix> |
| <gap 2> | <how to detect> | <how to fix> |

## Common Pitfalls

- <Pitfall 1>: <How to avoid>
- <Pitfall 2>: <How to avoid>

---
*Auto-generated by /distill on <date>*
```

**For Strategy C (Split Capability Skills)**, generate multiple files:
- A parent skill that explains when to use which sub-skill
- Individual focused capability skills for each branch

**For Strategy D (SOP + Capability + Tool Skills)**, generate:

1. **SOP Orchestration Skill Template:**

```markdown
---
name: <sop-skill-name>
description: |
  <Overall goal description>
  Orchestrates: /<skill-1>, /<skill-2>, /<skill-3>
  Use when you need to <complete workflow description>
---

# /<sop-skill-name> - <goal description>

## Overview

This workflow orchestrates multiple skills to achieve: <goal>

**Skills used:**
- `/<skill-1>` - <what it does> [Tool/Capability]
- `/<skill-2>` - <what it does> [Tool/Capability]
- `/<skill-3>` - <what it does> [Tool/Capability]

## User Preferences (learned from session)

| Preference | Value | Rationale |
|------------|-------|-----------|
| <pref 1> | <value> | <why> |

## Runtime Inputs

| Input | Default | When to ask |
|-------|---------|-------------|
| <input 1> | <default> | <condition> |

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
- If <condition A> → proceed to Step 3a
- If <condition B> → skip to Step 4

### Step 3: <phase name> [MUST]
...

## Execution Quality Checklist

### Required Steps (MUST)
- [ ] Step 1 completed with valid output
- [ ] Step 3 completed

### Completeness Checks
- [ ] <coverage check>

### Checkpoints
- After Step 1: <what to verify with user>
- After Step 3: <what to verify>

## Final Output

Synthesize results from all steps and present:
- <output item 1>
- <output item 2>

## Error Handling

- If `/<skill-1>` fails: <fallback>
- If `/<skill-2>` returns empty: <alternative>

---
*Auto-generated by /distill on <date>*
*Type: SOP Orchestration*
```

2. **Capability Skill Template:**

```markdown
---
name: <capability-skill-name>
description: |
  <Specific action description>
  Can be used standalone or invoked by SOP skills.
  Input: <expected input>
  Output: <what it returns>
---

# /<capability-skill-name> - <action description>

## Purpose

<What this skill does - ONE specific thing>

## User Preferences

| Preference | Value | Rationale |
|------------|-------|-----------|
| <pref> | <value> | <why> |

## Input

- **Required**: <required input>
- **Optional**: <optional parameters>

## Process

### Step 1: <step name> [MUST]
<content>

### Step 2: <step name> [SHOULD]
<content>

## Output

Returns: <description of output format>

Example:
```
<example output>
```

## Execution Checklist

- [ ] <required check 1>
- [ ] <required check 2>

## Data Sources

- Primary: <main data source>
- Fallback: <alternative if primary fails>

## Common Pitfalls

- <Pitfall 1>: <How to avoid>

---
*Auto-generated by /distill on <date>*
*Type: Capability*
```

3. **Tool Skill Template:**

```markdown
---
name: <tool-skill-name>
type: tool
description: |
  <What this tool does>
  Input: <expected input>
  Output: <what it returns>
fallback: true
---

# /<tool-skill-name> - <action description>

<Brief description of what this tool does>

## Purpose

<Why this tool exists and when to use it>

## User Preferences (baked in)

| Preference | Value | Rationale |
|------------|-------|-----------|
| <pref> | <value> | <learned from session> |

## Prerequisites

- <Runtime requirement, e.g., Python 3.8+>
- <Any setup needed, e.g., API keys>

## Dependencies

\`\`\`bash
pip install -r $SKILL_DIR/requirements.txt
\`\`\`

## Script

\`\`\`bash
python $SKILL_DIR/scripts/<script_name>.py <REQUIRED_ARG> [OPTIONS]
\`\`\`

### Parameters

| Param | Required | Default | Description |
|-------|----------|---------|-------------|
| <ARG> | Yes | - | <description> |
| --option | No | <default> | <description - note if this is a saved preference> |

### Example

\`\`\`bash
python $SKILL_DIR/scripts/<script_name>.py input.csv --format json
\`\`\`

## Output Format

\`\`\`json
{
  "status": "success",
  "data": {
    <output structure>
  },
  "error": null
}
\`\`\`

## Execution Checklist

- [ ] Prerequisites met
- [ ] Required params provided
- [ ] Output validated

## Fallback

If the script is unavailable, Claude can implement equivalent functionality using:
- <Alternative approach 1>
- <Alternative approach 2>

## Common Pitfalls

- <Pitfall>: <How to avoid>

---
*Auto-generated by /distill on <date>*
*Type: Tool*
```

**When generating Tool Skills:**
1. Create directory: `.claude/skills/<tool-name>/`
2. Write SKILL.md with above template
3. Create `scripts/` subdirectory
4. Write the actual script file with:
   - Argument parsing (argparse, yargs, etc.)
   - JSON output format
   - Error handling
5. Create `requirements.txt` if dependencies needed

### Step 6.5: Dependency Completeness Check [MUST]

Before saving, cross-verify that the `depends_on` list in the YAML frontmatter is consistent with the skill body content:

1. **Scan the body** for all referenced skill names (patterns like `/<skill-name>`, "Invoke `/<skill-name>`", sub-skill lists, etc.)
2. **Compare** the set of skills found in the body against the `depends_on` list in frontmatter
3. **If mismatch detected**:
   - Skills in body but NOT in `depends_on` → **add them** to `depends_on`
   - Skills in `depends_on` but NOT in body → verify intent (may be implicit dependency)
4. **Report** any corrections made:
   ```
   Dependency check: added get-stock-data, generate-stock-report to depends_on
   (referenced in body but missing from frontmatter)
   ```

This prevents partial `depends_on` lists caused by incomplete extraction from session context.

### Step 7: Save with Location Recommendation [MUST]

**Determine recommended save location for each skill:**

| Skill characteristic | Recommendation | Reason |
|---------------------|----------------|--------|
| Uses project-specific paths/configs | Local | Won't work in other projects |
| References project files | Local | Project-dependent |
| General utility (git, debugging, etc.) | Global | Useful everywhere |
| Reusable tool (data processing, API calls) | Global | Can use in any project |
| Domain-specific workflow | Local | Context-dependent |

**Present recommendation to user:**

```
Save locations:
- `/<skill-a>` → Local (.claude/skills/) - uses project-specific config
- `/<skill-b>` → Global (~/.claude/skills/) - general utility, reusable

Confirm? Or adjust locations?
```

**After user confirms, save:**

**For SOP/Capability Skills (no scripts):**
- Local: `.claude/skills/<skill-name>/SKILL.md`
- Global: `~/.claude/skills/<skill-name>/SKILL.md`

**For Tool Skills (with scripts):**
- Create directory at chosen location
- Save SKILL.md to the directory
- Create `scripts/` subdirectory
- Save script file(s)
- Create `requirements.txt` if needed

**Inform user:**
- File location(s)
- How to use: `/<skill-name>`
- For Tool Skills: any setup needed (pip install, etc.)
- Remind: can move between local/global later if needed

### Step 8: Share Options [MUST]

After saving locally, ask user:

```
Share this skill on dstl.dev?

- [Keep local] (default) - Skill saved locally, done
- [Share with selected people] - Upload and choose who can access
- [Share publicly] - Upload and make available to anyone
```

**If user chooses "Keep local"** → End here. Skill is already saved locally.

**If user chooses "Share with selected people" or "Share publicly":**

> **CRITICAL: Use the upload-skill.sh script. DO NOT write your own code.**

#### 8.1 Upload each skill individually

Each skill is uploaded independently via `upload-skill.sh`. Dependencies are declared in SKILL.md frontmatter (`depends_on` field), not via CLI arguments.

**SKILL.md frontmatter format:**
```yaml
---
name: my-skill
description: What this skill does
depends_on:
  - helper-skill-name
  - another-skill-name
---
```

Note: No `type` field needed. `depends_on` is a list of skill names.

#### 8.2 Upload command

For each skill generated in this session:

```bash
~/.claude/skills/distill/scripts/upload-skill.sh \
  --skill-dir <path-to-skill-directory>
```

The script automatically:
1. Checks authentication (prompts login if needed)
2. Reads SKILL.md and scripts/* from the directory
3. Parses skill name, description, and depends_on from SKILL.md frontmatter
4. Checks `~/.skillbase/registry.json` for existing slug (auto-detects updates)
5. Uploads new or updates existing skill on dstl.dev (private by default)
6. Updates `~/.skillbase/registry.json` with slug, skill_id, version
7. Returns success message with dashboard link

**For multi-skill workflows:** Upload each skill one at a time. Dependencies are resolved by name at install time. Upload dependency skills first, then the orchestrating skill.

```bash
# Upload helpers first
~/.claude/skills/distill/scripts/upload-skill.sh --skill-dir ~/.claude/skills/helper-a
~/.claude/skills/distill/scripts/upload-skill.sh --skill-dir ~/.claude/skills/helper-b

# Then upload the main workflow skill (which declares depends_on in frontmatter)
~/.claude/skills/distill/scripts/upload-skill.sh --skill-dir ~/.claude/skills/main-workflow
```

#### 8.3 After upload, inform user

```
Uploaded successfully!

Configure access: <manage_url>
Registry updated: ~/.skillbase/registry.json

Your skill is private by default. Visit the link above to:
- Add specific people by email, or
- Make it publicly accessible

Once shared, others can install with:
  curl -sSL <share_url>/install.sh | bash
```

If this was an update, also show:
```
Version: <new-version-number>
```

---

---

## Upload Flow

> Triggered by `/distill upload`. Skips all analysis — goes straight to skill upload.

### Step 1: Discover local skills

Scan for skills in both locations:
- Global: `~/.claude/skills/*/SKILL.md`
- Local (project): `.claude/skills/*/SKILL.md`

For each skill found, read its SKILL.md frontmatter to get `name` and `description`.

Also load `~/.skillbase/registry.json` to check which skills are already uploaded (have a slug) and their current version.

### Step 2: Present skill selection

Use AskUserQuestion with multi-select to let user choose which skills to upload:

Show each skill with status indicator:
- `[new]` — not in registry, will be a fresh upload
- `[v3]` — already uploaded at version 3, will update

Example:
```
Which skills do you want to upload?

□ analyze-stocks - 股票分析工作流 [v1]
□ fetch-market-news - 获取财经新闻 [v1]
□ score-stocks - 评分排名 [v2]
□ hello-world - A simple test skill [new]
```

### Step 3: Upload selected skills

For each selected skill, run:

```bash
~/.claude/skills/distill/scripts/upload-skill.sh \
  --skill-dir <path-to-skill-directory>
```

If uploading multiple skills with dependencies, upload dependency skills first (check `depends_on` in frontmatter to determine order).

### Step 4: Report results

Show upload results for each skill:
- Success: slug, version, manage URL
- Failure: error message

---

## Stats Flow

> Triggered by `/distill stats`. Shows status of all skills.

### Step 1: Load registry

Read `~/.skillbase/registry.json`. If it doesn't exist, inform user: "No skills have been uploaded yet. Run `/distill upload` first."

### Step 2: Discover and display skills

Scan for skills in both locations (global + local). Cross-reference with registry.

Display a table:

```
Skill                  | Location | Status    | Version | Slug
-----------------------|----------|-----------|---------|------------------
analyze-stocks         | global   | uploaded  | v1      | 04cdd91f8d28bd38
fetch-market-news      | global   | uploaded  | v1      | 493f3cfdc1065481
score-stocks           | global   | uploaded  | v2      | 960f635dc99796a1
hello-world            | global   | uploaded  | v1      | 00531ddc303fee6b
my-local-skill         | local    | local only| -       | -
```

Status values:
- `uploaded` — in registry with slug
- `local only` — exists on disk but never uploaded
- `modified` — local SKILL.md content differs from last upload (compare file mtime vs registry `uploaded_at`)

### Step 3: Offer actions (optional)

If user seems interested, mention available actions:
- `/distill upload` to upload or update skills
- Visit manage URL to configure access/visibility

---

## Manual Invocation

User can manually call `/distill` at any time to review the current session and evaluate if there's anything worth extracting. Subcommands (`upload`, `stats`) are available for skill management without running analysis.

---

## Example Output

These examples show what to present to users - concise summaries without internal terminology.

### Example A: Simple case

```
## Summary

**Problem solved**: Git push rejected due to diverged branches

**What I'll create**:
- `/fix-git-diverged-branch` - Step-by-step fix for diverged branch issues

**Saved preferences**: (none)

**Runtime inputs**: (none needed)

**Where to save**:
- Global (~/.claude/skills/) ← Recommended: general git utility

Confirm? [Y/n]
```

### Example B: Skill with decision branches

```
## Summary

**Problem solved**: React useEffect infinite loop

**What I'll create**:
- `/fix-useeffect-infinite-loop` - Diagnoses cause and applies correct fix

**Saved preferences**:
- React version: 18+ (hooks API)

**Runtime inputs**:
- Component code: (will read from context)

**Branches included**:
- Object reference issue → useMemo solution
- Function reference issue → useCallback solution
- Missing dependency → add to array

**Where to save**:
- Global (~/.claude/skills/) ← Recommended: common React issue

Confirm? [Y/n]
```

### Example C: Multiple focused skills

```
## Summary

**Problem solved**: CI build fails but works locally

**What I'll create**:
- `/diagnose-ci-failure` - Entry point, determines which fix to use
- `/fix-ci-node-version` - Node version mismatch fix
- `/fix-ci-env-vars` - Missing env vars fix
- `/fix-ci-cache` - Cache invalidation fix
- `/fix-ci-deps` - Dependency issues fix

**Saved preferences**: (none)

**Runtime inputs**:
- CI platform: (ask each time, common: GitHub Actions, CircleCI)

**Where to save**:
- Global (~/.claude/skills/) ← Recommended: CI debugging is universal

Confirm? [Y/n]
```

### Example D: Workflow with helper skills

*Note: This pattern applies to any multi-step workflow - ETL pipelines, report generation, monitoring, etc.*

```
## Summary

**Problem solved**: Analyze market events and generate investment recommendations

**What I'll create**:

Main workflow:
- `/analyze-market` - Orchestrates the full analysis

Helper tools (with scripts):
- `/fetch-news` - Fetch news from APIs [Tool]
- `/get-fundamentals` - Get financial data [Tool]
- `/calc-indicators` - Calculate technical indicators [Tool]

Helper capabilities (reasoning):
- `/analyze-impact` - Determine event impact on stocks [Capability]

**Saved preferences**:
- Primary news source: Reuters API (learned: more reliable)
- Analysis depth: comprehensive (user chose this)
- Output format: markdown report

**Runtime inputs**:
- Time range: default last 7 days
- Specific sectors: ask if user has preference

**Where to save**:
- Local (.claude/skills/) ← Recommended: project-specific workflow

**Files to generate**: 5 skill directories

Confirm? [Y/n]
```

*If user asks "show details" or "why?", then show the full analysis with scores, decision points, etc.*

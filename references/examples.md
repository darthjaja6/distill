# Distill Output Examples

These examples show what to present to users - concise summaries without internal terminology.

## Example A: Simple Skill

```
## Distill Summary

**Problem solved**: Git push rejected due to diverged branches

**What I'll create**:
- `/fix-git-diverged-branch` - Step-by-step fix for diverged branch issues

**Key insight captured**: Use `git pull --rebase` instead of merge to keep clean history

**Where to save**:
- Global (~/.claude/skills/) - general git utility

Confirm? [Y/n]
```

## Example B: Skill with Decision Branches

```
## Distill Summary

**Problem solved**: React useEffect infinite loop

**What I'll create**:
- `/fix-useeffect-infinite-loop` - Diagnoses cause and applies correct fix

**Branches included**:
- Object reference issue -> useMemo solution
- Function reference issue -> useCallback solution
- Missing dependency -> add to array

**Failed attempts captured**:
- Adding object directly to deps (causes infinite loop)
- Empty deps array when value needed (stale closure)

**Where to save**:
- Global (~/.claude/skills/) - common React issue

Confirm? [Y/n]
```

## Example C: Multiple Focused Skills

```
## Distill Summary

**Problem solved**: CI build fails but works locally

**What I'll create**:
- `/diagnose-ci-failure` - Entry point, determines which fix to use
- `/fix-ci-node-version` - Node version mismatch fix
- `/fix-ci-env-vars` - Missing env vars fix
- `/fix-ci-cache` - Cache invalidation fix

**Why multiple skills**: Each failure mode is independent and reusable separately

**Where to save**:
- Global (~/.claude/skills/) - CI debugging is universal

Confirm? [Y/n]
```

## Example D: Workflow with Helper Skills

```
## Distill Summary

**Problem solved**: Analyze market events and generate investment recommendations

**What I'll create**:

Main workflow:
- `/analyze-market` - Orchestrates the full analysis

Helper tools (with scripts):
- `/fetch-news` - Fetch news from APIs [Tool]
- `/get-fundamentals` - Get financial data [Tool]

Helper capabilities (reasoning):
- `/analyze-impact` - Determine event impact [Capability]

**Learned preferences** (baked in):
- Primary news source: Reuters API (more reliable)
- Analysis depth: comprehensive
- Output format: markdown report

**Failed attempts captured**:
- Yahoo Finance API (rate limited)
- Single-pass analysis (missed correlations)

**Where to save**:
- Local (.claude/skills/) - project-specific workflow

Confirm? [Y/n]
```

## What NOT to Show by Default

- Detailed decision point analysis
- Scoring breakdown (15/30, etc.)
- Internal step names
- Strategy names (A/B/C/D)

Only show details if user asks "why?" or "show details".

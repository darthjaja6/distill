# Extraction Worthiness Scoring

Use this scoring system when deciding whether to suggest `/distill` proactively.

## Dimensions (Score 1-5 each)

| Dimension | 1 (Low) | 3 (Medium) | 5 (High) |
|-----------|---------|------------|----------|
| **Generality** | One-off, project-specific | Might appear in similar projects | Common across many projects |
| **Complexity** | Single step, obvious | Multiple steps, some nuance | Many steps, non-obvious knowledge |
| **Pitfall Probability** | Unlikely to forget | Might forget some details | Will definitely hit same trap |
| **Time Cost** | Minutes to redo | Hours to redo | Days to redo |
| **Decision Density** | Many expert judgments | Mix of structured and judgment | Mostly automatable |
| **Structurability** | Can't be systematized | Partially structurable | Clear if/else logic possible |

## Scoring Guide

**Generality**: Will this problem/solution appear in other projects?
- 1: Unique to this codebase
- 3: Common in this tech stack
- 5: Universal (git, debugging, CI, etc.)

**Complexity**: Does it require multiple steps or non-obvious knowledge?
- 1: One-liner fix
- 3: 3-5 step process
- 5: 10+ steps with dependencies

**Pitfall Probability**: Will you hit the same trap without documentation?
- 1: Obvious in hindsight
- 3: Easy to forget one detail
- 5: Counter-intuitive, will definitely repeat mistake

**Time Cost**: How long to re-figure without a skill?
- 1: < 10 minutes
- 3: 1-2 hours
- 5: Half day or more

**Decision Density**: How many human judgments needed? (inverse scoring)
- 1: Every step needs expert judgment
- 3: Some automation, some judgment
- 5: Fully automatable

**Structurability**: Can decision points become clear branches?
- 1: Too context-dependent
- 3: Some can be if/else
- 5: All can be systematized

## Threshold

**Total >= 15 (out of 30)**: Recommend extracting as skill

**Total < 15**: Consider if it's better as reference notes

## Quick Heuristics

Skip scoring and suggest distill if:
- User said "finally!", "oh that's why", "what a trap"
- Took 3+ iteration cycles
- Solution was counter-intuitive

Skip scoring and don't suggest if:
- Simple typo fix
- Following documentation exactly
- One-time configuration

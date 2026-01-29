[dstl.dev](https://dstl.dev/) &nbsp;|&nbsp; [<img src="https://img.shields.io/badge/-000000?style=flat&logo=x&logoColor=white" alt="X" height="18" align="center" />](https://x.com/darthjajaj6z)

# Distill

Turn hard-won solutions into reusable Claude Code skills.

---

Cracked it after 20 iterations? Repeating the same SOP daily? Burned 1B tokens before nailing this solution?

**Distill extracts your hard-won solutions into reusable slash commands.** Type `/distill` and it captures what worked, what didn't, and why — so you (or your team) never repeat the struggle.

## Install

```bash
curl -sSL https://dstl.dev/s/distill/install.sh | bash
```

This places the skill into `~/.claude/skills/distill/`.

## Usage

### Automatic

Distill proactively suggests itself when it notices:

- A problem that took 3+ iteration cycles to solve
- A solution involving non-obvious tricks or hidden pitfalls
- Complex multi-step debugging
- Signals like "finally got it" or "oh, that's why"

You'll see a prompt like:

> "This took some iteration. Want me to run /distill to extract a reusable skill?"

### Manual

Type `/distill` in any Claude Code session to review your current work and extract a skill.

### What Happens

1. **Review** — Distill analyzes the problem, attempted paths, key turning points, and final solution.
2. **Classify** — It identifies whether the result should be a single skill, a skill with decision branches, or a multi-skill workflow.
3. **Generate** — It creates skill file(s) with steps, pitfall warnings, checkpoints, and decision logic.
4. **Save** — You choose local (`.claude/skills/`) or global (`~/.claude/skills/`).
5. **Share (optional)** — Upload to [dstl.dev](https://dstl.dev/) to share with others.

## Sharing Skills

After generating a skill, Distill will ask if you want to share it. If you choose to share:

1. You'll authenticate with [dstl.dev](https://dstl.dev/) via a browser-based device flow (one-time).
2. The skill gets uploaded as **private by default**.
3. You get a dashboard link where you can manage access — add people by email or make it public.
4. Others install shared skills with a single command:

```bash
curl -sSL https://dstl.dev/s/<skill-slug>/install.sh | bash
```

## License

MIT

# decision-sparring

Stress-tests a decision that has already been made and delivers a
verdict. A sparring partner stands in the ring, not at the edge of it —
someone who only asks questions is handing the work back and calling it
diligence.

The standard it aims at: afterwards the person knows what they are doing,
how they will find out they were wrong, and what the way back costs.

## What's inside

- **Skill `decision-sparring`** — the door test that scales effort before
  anything else happens, the workflow, the premortem, the fixed verdict
  format, and the stance rules that keep it from turning into either
  critique theater or a rubber stamp.
- `references/question-catalog.md` — the question blocks: framing,
  assumptions, alternatives, evidence, motives, consequences,
  reversibility. Drawn from the Kahneman/Lovallo/Sibony decision quality
  checklist, Structured Analytic Techniques (Key Assumptions Check,
  premortem, devil's advocacy) and ATAM (tradeoff points, non-risks).

Three things carry most of the weight. **The door test**: a two-way door
gets three questions and a verdict in one reply, a one-way door gets the
full battery — running the whole questionnaire on a trivial decision is
itself a failure. **Every objection needs a mechanism**: "that will not
scale" is worthless without "past N objects, because the index no longer
fits in memory"; without one it is a suspicion and gets labeled as one.
**Non-risks are part of the verdict**, recording what was deliberately
examined and found acceptable, so it does not get reopened in three
weeks.

## Install

### Claude Code

```bash
/plugin install decision-sparring@onelitefeather-claude-marketplace
```

Also bundled as a `framework` dependency, so a fresh `framework` install
brings it along. No MCP servers or external dependencies — pure skill
content, nothing to configure.

Pairs with `problem-framing`: a decision that arrives vague or
solution-shaped is not ready to be sparred with, and that skill produces
the brief this one consumes.

### Codex

Ships `.codex-plugin/plugin.json` pointing at the same `skills/`
directory. Install through Codex's `/plugins` browser once this
marketplace is registered there, or clone/symlink
`skills/decision-sparring/` into `~/.codex/skills/`.

### Antigravity (`agy`)

Also ships `.antigravity-plugin/plugin.json`. **Not verified live in this
environment** (no `agy` CLI available to test against) — same shape as
the Codex manifest as a best-effort approximation. Confirm the skill
surfaces before relying on it.

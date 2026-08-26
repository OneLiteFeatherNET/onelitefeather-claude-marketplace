# Page templates

Copy-ready skeletons. Replace the bracketed parts; keep the shape.

These skeletons are English. On the Outline target the structure holds unchanged but the body is
German — see `references/publishing/outline.md`, section "Language", and note that a German how-to
title is an infinitive phrase with the verb last (`How-To: Renovate-Preset einbinden`), not
verb-first. The Outline hub has its own skeleton in `assets/nav-templates/outline-structure.md` and
does not use the documentation index below.

Every value that appears in a filled-in template — a default, a permission, a version, a command —
comes from the source. Never from inference.

---

## Tutorial

````markdown
# [Outcome the reader will have achieved]

In this tutorial we will [build the one concrete, visible thing].

You need [starting point: version, prerequisite, nothing else].
[A duration, only if someone has actually walked this path and timed it. It cannot be
inferred — delete the line rather than estimating.]

## [Step group 1]

1. [Action]
2. [Action]

[What the reader should now see, described concretely: the log line, the message,
the changed screen. Name the part that matters.]

[If it does not appear, the likely cause in one clause.]

## [Step group 2]

1. [Action]

[What the reader should now see.]

## What you did

[Two sentences naming the thing just built and the loop it demonstrates.]

Next: [link to the how-to the reader will most likely want].
````

Every step group ends with something the reader can check, described so they can tell success from
failure without knowing the product. If a group has no observable result, merge it into the next
one. One path throughout — the reader is never asked to choose.

---

## How-to

````markdown
# [Verb] [reader's goal]

[One line restating the goal and the situation it applies to.]

**Before you start:** [prerequisite, or "none"].

1. [Action, naming the key or control exactly]
2. [Action]
3. [How to apply the change: command, restart]

[Where the route genuinely forks, say so in the reader's terms:
"If you [situation], [do this] instead."]

## Check it worked

[The one observation that confirms success.]

## If it does not work

[The failures that actually occur, and how to tell them apart.]

See also: [reference page for the keys used].
````

No defaults restated, no concepts explained, one goal only. Branch where the real problem branches;
do not pad with branches that never occur.

---

## Reference

````markdown
# [What is looked up here]

[One line stating what this page covers and where the values come from.]

[Banner — pick the one that is true; full wording in references/reference-pages.md.
Until a generator and its CI gate actually exist:
  "**✍️ Transcribed by hand** from <source> on <date>. There is no generator for this
   page yet — re-read that file before trusting or changing anything here."
Only once the generator and gate are in place:
  "**🤖 Generated** from <source> by <task>. Do not edit by hand; run <command> to update."]

## [Section mirroring the machinery: config section, module, command group]

### `[fully.qualified.key]`

| | |
|---|---|
| Type | [type, with unit] |
| Default | `[literal]` |
| Allowed values | [from the type] |
| Required | [only where some entries are and some are not] |
| Reload | [command / restart / hot — read the reloading code, or omit the row] |
| Since | [release the key first shipped in — derive it from git, or omit the row] |
| Source | `[symbol in code]` |

[One sentence: what it does.]

[Constraint or warning, where one applies: "You must not …", "Never …".]

```[format]
[minimal example showing this setting only]
```
````

Same fields, same order, every entry; a field with no value is omitted, never moved. Sections follow
the structure of the thing being described, not a guess at what readers want first.

---

## Explanation

````markdown
# [The question this page answers]

[Open with the question as a reader would ask it, not with a definition.]

## [The mechanism or the history]

[Discursive prose. Comparison and trade-offs are welcome here.]

## What this means in practice

[The consequence for the reader's decisions, without turning into steps.]

## What this is not

[Scope boundary, where one exists. Explicitly naming what the software
does not do prevents a class of misunderstanding.]

Related: [ADR link if one exists] · [how-to pages that act on this]
````

No numbered action lists. If one appears, it belongs in a how-to. Check the title with an implicit
"about" in front of it.

---

## Documentation index

````markdown
# [Project] documentation

[One or two sentences saying what the project is and what these pages cover.]

**New here?** [Tutorial title] walks you through [outcome].

**Trying to get something done?** The how-to guides cover [three most common goals].

**Looking up a value?** [Configuration reference], [command reference], [permissions].

**Wondering how it works or why?** [Two most-asked explanation pages].
````

Name the reader's situation, not the quadrant. The reader never has to learn the word Diátaxis. This
is an overview page, not a link list, and it has to work for someone who arrived from a search
result rather than from the top.

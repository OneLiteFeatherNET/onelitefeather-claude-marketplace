# Page templates

Copy-ready skeletons. Replace the bracketed parts; keep the shape.

---

## Tutorial

```markdown
# [Outcome the reader will have achieved]

By the end of this you will have [one concrete, visible result].

You need [starting point: version, prerequisite, nothing else].
This takes about [n] minutes.

## [Step group 1]

1. [Action]
2. [Action]

You should now see [visible confirmation].

## [Step group 2]

1. [Action]

You should now see [visible confirmation].

## What you did

[Two sentences naming the skill just acquired.]

Next: [link to the how-to the reader will most likely want].
```

Every step group ends with something the reader can check. If a group has no observable result, merge it into the next one.

---

## How-to

```markdown
# [Verb] [reader's goal]

[One line restating the goal and when it applies.]

**Before you start:** [prerequisite, or "none"].

1. [Action, naming the key or control exactly]
2. [Action]
3. [How to apply the change: command, restart]

## Check it worked

[The one observation that confirms success.]

## If it does not work

[The single failure that actually occurs, and how to tell it apart from a different problem.]

See also: [reference page for the keys used].
```

No defaults restated, no concepts explained, one goal only.

---

## Reference

```markdown
# [What is looked up here]

[One line stating what this page covers and where the values come from.
If generated: "Generated from <source>. Do not edit by hand."]

### `[fully.qualified.key]`

| | |
|---|---|
| Type | [type, with unit] |
| Default | `[literal]` |
| Allowed values | [from the type] |
| Reload | [command / restart / hot] |
| Since | [git tag] |
| Source | `[symbol in code]` |

[One sentence: what it does.]

```[format]
[minimal example showing this setting only]
```
```

Same fields, same order, every entry.

---

## Explanation

```markdown
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
```

No numbered action lists. If one appears, it belongs in a how-to.

---

## Documentation index

```markdown
# [Project] documentation

**New here?** [Tutorial title] walks you through [outcome].

**Trying to get something done?** The how-to guides cover [three most common goals].

**Looking up a value?** [Configuration reference], [command reference], [permissions].

**Wondering how it works or why?** [Two most-asked explanation pages].
```

Name the reader's situation, not the quadrant. The reader never has to learn the word Diátaxis.

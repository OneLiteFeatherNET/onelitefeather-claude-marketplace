# AI tells in commit messages and PR text

## Scope

This file covers *phrasing* only: word choice, sentence rhythm, and structure in commit messages,
branch names, PR titles and bodies, issue and review comments, release notes and tag messages.
Machine typography (dashes, quotes, invisible characters) lives in `references/typography.md`. Tool
attribution (`Co-Authored-By:` trailers, session URLs, the "Generated with" footer) is handled
mechanically by `scripts/strip-attribution.sh` and is not a phrasing question at all — it is either
present or absent, nothing to judge.

Phrasing is different: it cannot be pattern-matched without an unacceptable false-positive rate, so
no script in this plugin touches it. This file is read by whoever (human or Claude) is about to write
or revise a commit message or PR body, and is applied by judgment, not by a hook.

**What this file is not for.** The goal is not to make text that passes an AI detector. Wikipedia's
"Signs of AI writing" essay, the source most of the vocabulary evidence below traces back to, says it
directly:

> "Please do not merely treat these signs as the problems to be fixed; that could just make detection
> harder."

Optimizing against a detector produces text that is evasive, not text that is good. The actual target
is narrower and more useful: **read like the people who already write commits and PRs in this
repository** — terse, specific, imperative, and willing to reference a real filename instead of a
vague virtue. If a rewrite satisfies every rule below but a maintainer here still wouldn't have
written it that way, the rewrite failed. See the design spec's "Why this matters" section for the
full argument against framing this as detection evasion.

## Categories, not a word list

Grep can catch a fixed vocabulary; it cannot catch a *shape*. The patterns below are shapes. A
sentence can trip one of these with words that never appear on any banned-word list, and a sentence
can contain a "tell word" and be completely fine (see the do-not-touch list). Read for the pattern,
not the token.

**Antithesis ("not just X, it's Y").** A rhetorical contrast that inflates an ordinary change into a
revelation. *"This isn't just a bug fix, it's a fundamental rethink of how validation works"* for a
diff that adds one null check. The construction is the tell, independent of how big the real change
is — a genuinely large rewrite still doesn't need the contrast framing to be described accurately.

**Ritual openers and closers.** Text addressed to a reader who isn't there. Openers: *"Great
question!"*, *"Here's a summary of the changes I made:"* as throat-clearing before content that could
just start. Closers: *"Let me know if you have any questions!"*, *"This should now work as
expected."*, *"I hope this helps!"* A commit message has no "you" to reassure — it is a historical
record, not a reply.

**Self-praise and significance inflation.** Adjectives asserting the value of the change instead of
describing it: *"a critical fix that significantly improves reliability"* over a one-line guard
clause, *"comprehensive"*, *"powerful"*, *"seamless"* used as unearned intensifiers rather than
accurate description. Contrast with the do-not-touch list below — the same words describing something
that is actually comprehensive or actually critical are not this category.

**Forced three-item structure.** Exactly three bullets, three reasons, or three benefits regardless of
how many things are actually true. *"This change: 1) improves performance 2) improves readability 3)
improves maintainability"* when the diff only supports one of the three claims and the other two are
padding to complete the triad. Two real items are two items; five real items are five items.

**Formatting excess.** Nested bullets three levels deep in a commit body, emoji in headings (`## ✨
Features`), a bold lead-in on every line (`**Fixed:** ...`, `**Added:** ...`, `**Changed:** ...`)
turning a paragraph into a slide deck. Commit messages and plain PR bodies read as prose or a flat
list; this repository's actual history (see examples below) never needed a bolded label per line to
be readable.

## The evidence-backed vocabulary cluster

A small set of words is measurably over-represented in AI-generated text relative to a human-written
baseline — this plugin's design research put concrete multipliers on three of them. A ratio is not a
ban: each entry below states the context in which the word is exactly the right word.

| Word | Frequency ratio vs. human baseline | Legitimate when | Tell when |
|---|---|---|---|
| delve / delves / delving | 28.0x | Almost never, in this register. A deliberate, sparing metaphor ("delve into the archive") in prose that already reads that way elsewhere. | Used as a generic transition into any explanation — "Let's delve into the changes", "delves into the intricacies of the auth flow" — which is how it appears in nearly every case in commit and PR text. |
| underscore(s) (verb) | 13.8x | Plain use meaning "to emphasize" in ordinary prose ("the failure logs underscore a missing timeout"). Also never flag the noun sense — the `_` character itself ("renamed with a leading underscore"), which has nothing to do with this tell. | Used to hedge or dress up a claim about the writer's own change — "this change underscores our commitment to code quality." |
| showcasing | 10.7x | Literally describing a demo, example, or showcase feature that exists in the repo ("adds the page showcasing the plugin gallery"). | Used to describe an ordinary commit or PR as demonstrating skill or effort — "this PR is showcasing best practices in error handling." |

Other words frequently cited alongside this cluster in AI-writing research — "moreover", "boasts",
"testament to", "tapestry", "in the realm of", "it's important to note that" — follow the same rule
even without a measured ratio recorded here: judge the sentence shape and the register, not the
presence of the word alone.

## The do-not-touch list

This list matters more than the tell list above. Every entry here has been mistaken for a tell by a
naive rule, and removing or rewording any of them does active harm — it either breaks tooling, erases
a legal signal, or replaces a normal engineering sentence with a worse one for no reason. When a
tell-category match above and a do-not-touch entry below both seem to apply to the same text, the
do-not-touch entry wins.

| Pattern | Example | Why it survives |
|---|---|---|
| Imperative mood | "Add validation", "Fix race condition in worker pool" | The standard Git convention (`git commit`'s own template says "use the imperative mood"), not a machine signature. |
| Conventional Commit prefixes | `feat:`, `fix:`, `docs:`, `chore:`, `refactor:` | Structural markers this repository's Release Please setup parses to build `CHANGELOG.md`. Removing them breaks tooling, not phrasing. |
| Absent contractions | "do not" instead of "don't" | A long-standing formal-register convention in technical writing, unrelated to who or what wrote the sentence. |
| Domain terms that merely sound inflated | "robust error handling", "critical" as an issue-tracker severity level | Accurate technical vocabulary. "Critical" here names a real severity tier, not an unearned superlative. |
| Protected git trailers | `Signed-off-by:`, `BREAKING CHANGE:`, `Refs:`/`Fixes:`/`Closes:`, `Release-As:` | DCO compliance and Release Please parsing depend on these exact tokens. Reworded or removed, they silently break CI or a legal sign-off. |
| An existing PR or issue template's structure | Headings and checkboxes required by `.github/PULL_REQUEST_TEMPLATE.md` | A project's own template always wins over this document — see decision (h) in the design spec. Never restructure a template to match this file's preferences. |
| "Claude" as a product name | "the Claude Code marketplace", "supports the Claude API" | This repository *is* a Claude Code marketplace. The word is a legitimate product reference here, the same as "Gradle" or "GitHub" would be. Keyword-blocking on it is explicitly rejected in the design spec. |
| "Summary / Changes / Testing" section headings | Any PR body organized under these or equivalent headings | The structure is not the problem — see the next section. Flattening a well-organized PR body into unstructured prose is not an improvement. |
| Body length proportional to the diff | A long, itemized body accompanying a genuinely large multi-file change | Length must track the actual change. Only *uniform* thoroughness regardless of diff size is a signal — see "The strongest signal" below. |
| A list with a genuine, non-round count | Four, five, or six bullets that are each independently verifiable against the diff | Only a list artificially padded or trimmed to exactly three items to satisfy a rule-of-three is the tell, not the presence of a list. |
| Causal explanation sentences | "Fixes X because Y broke under Z" | Ordinary engineering reasoning about a change, not a ritual opener — keep it, and prefer it over a bare "Fixes X" when the "because" is true and known. |

## Structure is not the problem — empty content is

A "Summary / Changes / Testing" PR body is a reasonable, common structure. Flagging it as an AI tell
by shape alone produces false positives against perfectly good human PR bodies that happen to use the
same three headings. The actual failure mode is a body that keeps the headings but has nothing
checkable underneath them:

```
## Summary
This PR improves the codebase.

## Changes
Various improvements were made.

## Testing
Tested and works.
```

Every line here could describe any PR ever opened. The fix is not to delete the headings — it is to
require that **every heading carry a checkable fact**: a filename, a function or type name, a flag or
config key, a test name, a ticket or issue number, or a command that was actually run. The same
skeleton, filled in:

```
## Summary
Adds a 5s timeout to `WorkerPool.acquire()` (`worker_pool.go`); requests were hanging indefinitely
when the pool was exhausted (#412).

## Changes
- `worker_pool.go`: `acquire()` now takes a `context.Context` and returns `ErrPoolTimeout`
- `handler.go`: three call sites updated to pass the request context through

## Testing
`go test ./internal/pool/... -run TestAcquireTimeout -race`
```

Same headings, same three-part shape. The second version is not a tell because every sentence in it
is falsifiable against the diff.

## The strongest signal is substantive, not stylistic

Every rule above is about phrasing. The single strongest signal is not phrasing at all: **missing
particulars.** A commit or PR description that never names a file, a function, a config key, a test,
or a ticket — that stays entirely at the level of "improves", "fixes", "updates", "enhances" — is far
more suspicious than one that uses a word from the vocabulary cluster once.

The corollary is about distribution, not any single message: human commit histories are uneven.
Some commits get one line, some get ten, in rough proportion to how much there actually was to say.
A history where every single commit is a uniformly thorough three-to-five sentence paragraph,
regardless of whether the diff was a one-line typo fix or a multi-file feature, reads as machine-paced
even if no individual message trips any rule above. When writing or reviewing a commit message, the
question that matters most is not "does this sound inflated" but "does this name the actual thing
that changed, and is its length proportional to that."

## Before / after, from this repository's real history

The "after" side of each example below is quoted verbatim from an actual commit on this repository's
`main` branch — nothing here is invented as a model of what "good" looks like; it is what this
repository's own history already does correctly. The "before" side is a reconstruction in the tell
patterns above, built to show what the same underlying change would have looked like if it had been
described with ritual phrasing instead. No commit in this repository's history is actually this
bloated — that is the point: the gap between "before" and "after" here is the entire distance this
document asks a rewrite to close.

**Example 1 — self-praise and forced structure vs. named particulars**

Before (reconstructed):
> This is a comprehensive fix that significantly improves the quality of the micronaut-standards
> plugin. Three key issues were addressed: 1) a security example was corrected, 2) missing
> dependencies were added, and 3) various other improvements were made to ensure robustness across
> the plugin.

After (real, commit `3aa15e4`, subject `fix: address final-review findings on micronaut-standards
plugin`):
> Fixes a self-contradicting /metrics security example, gives the logging and security skills their
> missing dependency coordinates, aligns the dto and routing skills' validation-trigger and @Put
> examples with each other, fixes a FontEntity field-name drift between skills, and notes that a
> Throwable-wide exception handler supersedes Micronaut's built-in ones.

The real version names five distinct, independently checkable fixes — an endpoint, a skill, a field
name, a class — and uses none of them to pad a rule-of-three. It also happens to be one sentence,
because one sentence was enough to say five true things.

**Example 2 — ritual framing vs. a plain fact with its source**

Before (reconstructed):
> I noticed there was a typo in the codebase, so I went ahead and fixed it! The word "Micronaml" was
> incorrect and should have said "Micronaut" instead. This has now been corrected to improve the
> overall quality of the documentation.

After (real, commit `1e90286`, subject `fix: correct Micronaut typo in testcontainers skill`):
> Task-16 reviewer flagged "Micronaml" (inherited verbatim from the plan's task brief) in the
> unit-vs-integration-test section. Fixed in both the merged skill file and the plan document it
> came from.

The real version says *who found it, where it came from, and where it was fixed* — three particulars
a ritual-framed rewrite drops in favor of announcing that a fix happened.

**Example 3 — vague "various improvements" vs. a real enumerated list**

Before (reconstructed):
> This commit addresses several issues that were found during review. It's worth noting that the fix
> wave from before left a few things unresolved, but they have all been thoroughly fixed now to
> ensure a smooth and consistent experience going forward.

After (real, commit `ee10c0c`, subject `fix: address re-review findings on dependency-management
skill`):
> The final-review fix wave (3aa15e4) added logging-dependency coordinates but left a missing janino
> version-catalog entry, a stale frontmatter claim contradicted by the new body content, and a missing
> backtick — all three caught by the fix wave's scoped re-review.

Three items, genuinely three — not padded to fit, not vague. Each is a specific artifact: a version-
catalog entry, a frontmatter claim, a backtick. The real message even cross-references the exact
commit it follows up on instead of the placeholder "before".

The pattern across all three: the real commits never address a reader, never claim their own
significance, and never generalize past what the diff actually contains. That is the standard to
write toward — not a longer message, not a shorter one, but one where every clause survives being
checked against the change it describes.

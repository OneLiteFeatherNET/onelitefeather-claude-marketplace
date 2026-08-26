# Reference pages: entry format and generation

Generating the reference quadrant and gating it in CI is an OneLiteFeather policy layered on top of
Diátaxis, not part of the framework. Diátaxis governs whether documentation is the right *kind*, and
is explicit that it cannot give documentation accuracy: accuracy is functional quality, where the
framework has only an analytical role — it exposes lapses, it does not prevent them. Generation is
how they get prevented for the one quadrant where staleness is most dangerous, because a wrong
default in a table is trusted.

The counterweight matters just as much: a generated API listing is not a documentation set. A
project whose docs are entirely auto-generated reference has three empty quadrants and an unfinished
job, not a finished one.

## The standard entry

Every entry uses the same fields in the same fixed order. A field with no value is omitted, never
moved. Consistency is what makes the page scannable.

**Heading:** the key, fully qualified, exactly as the user types it (`check.ignoredWorlds`, not
`ignoredWorlds`).

**Table rows, in this order:**

| Field | Notes |
|---|---|
| Type | With unit where one exists: "integer, ticks", not "integer" |
| Default | The literal value, quoted as it appears in the file |
| Allowed values | Enum constants or a range. Read them from the type, not from a comment |
| Required | Only where some entries are and some are not |
| Reload | How the change takes effect: command, restart, hot |
| Since | The release the key first shipped in |
| Source | The field or symbol in the code, so a reader can jump to it |

**Two rows that get fabricated, and how to avoid it.** Neither `Since` nor `Reload` can be read off
the config file, and both look harmless enough to guess. They are not:

- **`Since`** is derived, not looked up. `git log -S'<key>' --oneline --reverse -- <config source>`
  gives the commit that introduced the key; `git tag --contains <sha> --sort=v:refname | head -1` gives the
  release it first shipped in — the sort matters, because the default is lexicographic and returns
  `v10.0.0` before `v9.0.0`. If either step comes back empty or ambiguous, **omit the row**. A plausible
  version number nobody verified is worse than no version number, because it is the row readers use
  to decide whether to upgrade.
- **`Reload`** comes from the code that re-reads the value — a reload command handler, a config
  watcher, or the absence of both, which means restart. Find that code or omit the row. Do not
  assume every key behaves like the one above it in the file; mixed reload behaviour within one
  config is common and is exactly what readers consult this column for.

The same holds for every other row: this page is where a fabricated value does the most damage.

**Body, after the table, in this order:** the effect sentence (one sentence, hand-written, stored
next to the field in the source); any constraint or warning that applies ("You must not set this
above …", "Never combine this with …"); then a minimal example.

Markdown skeleton:

    ### `check.ignoredWorlds`

    | | |
    |---|---|
    | Type | list of strings, world names |
    | Default | `['world']` |
    | Reload | `/arcm reload` |
    | Since | 1.0.0 |
    | Source | `Config.check.ignoredWorlds` |

    Worlds in which detection does not run.

    ```yaml
    check:
      ignoredWorlds:
        - world
        - creative_plots
    ```

The example shows one setting. An example that configures three things at once cannot be copied by a reader who wants one of them.

## Generation patterns

The goal in every pattern is the same: the reference falls out of the same source the software reads at runtime, so the two cannot disagree.

### Annotated configuration classes

Where config is a typed class with per-field annotations or Javadoc, an annotation processor or a reflection-based task can emit metadata at build time and a renderer turns that into Markdown. This is the pattern Spring Boot uses: `spring-boot-configuration-processor` reads `@ConfigurationProperties` classes and their Javadoc, writes `spring-configuration-metadata.json` into the jar, and the appendix of common application properties is rendered from that file.

Reading rules for such a generator:

- Take allowed values from the type (`enum.values()`), never from a comment. Comments listing enum constants go stale the moment a constant is added.
- Skip fields marked as internal or final-by-convention. They appear in the class but not in the user's file.
- Handle repeated blocks explicitly. Where a config section is a map of user-named blocks (per group, per world, per tenant), the entry documents the schema of one block, not a fixed key, and the example shows two named blocks so the pattern is visible.

### JSON Schema as the source

Where config is loaded from JSON or YAML without a typed class, write the schema first (Draft 2020-12), validate the loaded file against it at startup, and render the reference from the same schema. This buys three things from one artefact: a reference page, a startup error that names the offending key, and editor autocomplete for users editing the file.

### Build definition and manifest

Permissions, supported versions, dependencies and command declarations often live in the build definition or a generated manifest rather than in source files. Read them from there. A version list maintained by hand in a README is the single most reliably stale line in any project.

### CLI and command surface

Generate from the parser: the command tree, arguments, types, defaults and required permissions all exist as data in the parser definition. Where the framework can emit help text programmatically, render the reference from the same call the help command uses.

## The CI gate (build it only when asked)

Marking a page as generated is the documentation task. Building the generator is a separate, larger
one that changes the build and adds a workflow, so do not start it inside a request for
documentation. Write the page by hand from the source it names, banner it with the *pending* banner
below, and hand the generator and its CI gate back as a named follow-up.

**There are two banners and they must never be confused.** Until the generator exists, every value
on the page is a hand transcription that can rot, and the banner has to say exactly that:

> **✍️ Transcribed by hand** from `<the source file you actually read>` on `<today's date — insert
> it; do not copy the date out of this example>`. There is no generator for this page yet — re-read
> that file before trusting or changing anything here. Follow-up: add the generator and its CI
> drift gate.

The page carries the generated banner only once the generator and the gate are actually in place,
because that banner makes a stronger claim and has to be true when it appears:

> **🤖 Generated** from `src/main/resources/config.yml` by the `docs-generate` Gradle task. Do not
> edit by hand; run `./gradlew generateDocs` to update.

A generated banner on a page no generator writes is worse than no banner at all: it forbids the only
maintenance the page can currently receive, names a command that does not exist, and retires the
follow-up by making the work look finished.

When it is asked for, a generator without a gate is a script that ran once. Wire it as follows:

1. The generator writes to a fixed path in the repository.
2. The generated output is committed, so the docs are readable on the code host and in the published site without a build step.
3. CI regenerates and compares. A difference fails the build with a message naming the command that fixes it.

This turns "the docs are out of date" from a maintenance task into a build error, which is the only reliable form of documentation maintenance.

Two consequences worth accepting deliberately: the generated files must be excluded from manual review comments ("do not edit, generated by X"), and a changed default now shows up in the diff of the docs as well as the code, which is a feature during review.

## What not to generate

Hand-written, and still reference — do not exile these to explanation:

- The one-sentence effect of each item. A generator can emit key, type, default and allowed values; it cannot emit effect. Store the sentence next to the field in the source so the generator carries it along.
- The correct way to use something, and constraints between options ("only takes effect when `x` is enabled").
- Warnings, in second person where that reads naturally: "You must not …", "Never …".
- The minimal per-entry example.

Genuinely a different quadrant:

- Conceptual introductions to a configuration area. Those are explanation.
- Examples that combine several settings for a purpose. Those are how-to.

The reference page is the generated facts plus that hand-written material. Everything beyond it belongs on a different page.

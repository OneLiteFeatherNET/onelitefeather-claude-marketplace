# Publishing to GitBook

## What the platform gives you

GitBook renders a documentation site from Markdown and can keep a space synchronised with a git repository through Git Sync. With sync enabled, the repository is the source: files and structure live in git, edits made in the GitBook editor are committed back, and a branch maps to a space.

Two files control the result:

- `SUMMARY.md` defines the table of contents. Headings in it become page groups, nested list items become nested pages. This is the navigation, and it is hand-maintained.
- `.gitbook.yaml` at the repository root configures where the docs live (`root:`), which file is the summary and which is the landing page, plus redirects.

Because the structure comes from a file in the repository, GitBook is the target where Diátaxis maps most directly onto what the reader sees: the four quadrants become the four page groups.

## Structure

`.gitbook.yaml`:

```yaml
root: ./docs/

structure:
  readme: index.md
  summary: SUMMARY.md
```

`SUMMARY.md` with the quadrants as groups:

```markdown
# Table of contents

* [Overview](index.md)

## Getting started

* [Your first detection](tutorial/first-detection.md)

## How-to guides

* [Send alerts to Discord](how-to/send-alerts-to-discord.md)
* [Notify staff in game](how-to/notify-staff-in-game.md)

## Reference

* [Configuration](reference/configuration.md)
* [Commands](reference/commands.md)
* [Permissions](reference/permissions.md)

## Background

* [Detection modes](explanation/detection-modes.md)
* [Scope and non-goals](explanation/scope.md)
```

Group headings are reader-facing. Use the same reader-language names as everywhere else: getting started, how-to guides, reference, background.

Full template in `assets/nav-templates/SUMMARY.md`.

## Generated pages with Git Sync

Git Sync is bidirectional, which is convenient for prose and dangerous for generated files. A generator writing `docs/reference/configuration.md` in the repository publishes cleanly. A person editing that same page in the GitBook editor commits back and the next generator run overwrites it.

Handle it the same way as everywhere else, with one addition specific to sync:

- Banner at the top of every generated page naming the source and the workflow.
- Keep the drift gate in CI. With bidirectional sync the gate also catches editor edits to generated pages, which is exactly what you want it to catch.
- Do not let the generator rewrite `SUMMARY.md` wholesale. If new reference pages appear, have the generator fail with a message rather than silently reordering navigation that a human curated.

## Adding a new page

Two steps, and forgetting the second is the most common mistake: create the file in the right quadrant directory, then add the entry to `SUMMARY.md` under the right group. A file not listed in `SUMMARY.md` is not part of the site.

Renames need to happen in both places at once. A rename with no summary update removes the page from navigation while leaving it reachable by URL, which is worse than a broken link because nobody notices.

## When GitBook is the wrong target

If the docs are small enough that a rendered site adds nothing, plain Markdown in the repository read on the code host is sufficient, and one less system to keep in sync. GitBook earns its place when the docs have enough pages that search and navigation matter, or when non-developers need to edit them without touching git.

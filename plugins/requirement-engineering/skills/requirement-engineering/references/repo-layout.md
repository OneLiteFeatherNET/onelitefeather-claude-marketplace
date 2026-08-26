# Storing requirements in the repo

The alternative to a wiki — for public repos, open-source projects, for review by diff, or when the wiki is unavailable or does not exist.

## Structure

```
docs/requirements/
└── <project-slug>/
    ├── README.md                 main document "Requirements: <project>"
    ├── stage-1-<short-name>.md   "User Stories: Stage 1 — <short name>"
    └── stage-2-<short-name>.md
```

Slug and file names: lower case, ASCII, hyphens, umlauts transliterated (`ae`, `oe`, `ue`, `ss`). If the repo holds only one project, drop the project folder and put the files directly under `docs/requirements/`. Stage numbers are never reassigned; a dropped stage keeps its file and number and takes status `dropped`.

## Cross-linking

Relative links only, never wiki URLs:

- Main document, "Document" column: `[Stage 1 — Core](stage-1-core.md)`
- Each stage document carries the back-link `[← Requirements: <project>](README.md)` directly **below** its H1 — the H1 stays the first line
- No wiki links (`[[…]]`), no absolute paths — the links must work in a diff and on GitHub.

## Which wiki conventions still apply here

| Convention | In the repo? |
|---|---|
| No H1 as the first line (a wiki rule) | **No** — there is no title field in a repo. Every file starts with exactly one H1, headings from H2 down. |
| Non-ASCII characters in the text | Yes, where the document language uses them. File names stay ASCII. |
| Placeholders without `<` | **No** — that bug is specific to OLF's Outline. `- [ ] <description>` is correct here. |
| `@[Name](mention://user/<id>)` | **No** — mentions do not render. Use the plain name, optionally a GitHub handle in backticks. |
| Link only to targets that exist | Yes. |
| Structure, IDs, status values, EARS, MoSCoW | Unchanged. |

## Moving into a wiki

Never automatically and never as a copy — a document has exactly one home. When moving: remove the H1 and set it as the title, replace relative links with the real URLs from the responses that created the pages, and convert checkboxes and mentions to that wiki's form.

Afterwards reduce the repo file to a single line linking to the wiki rather than deleting it, so existing references do not break. The reverse holds too: a repo copy alongside a maintained wiki document is a duplicate, not a backup.

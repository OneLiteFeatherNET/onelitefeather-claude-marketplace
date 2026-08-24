# Outline collection layout

One collection per project. Four hub documents, pages nested underneath.
Hub names are reader-facing; the quadrant name stays internal.

Collection: <Project>
├── Getting started              hub, tutorial nested or inline
├── How-to guides                hub
│   ├── Send alerts to Discord
│   ├── Notify staff in game
│   ├── Ignore a world
│   └── Produce a debug log for a bug report
├── Reference                    hub
│   ├── Configuration            generated, do not edit
│   ├── Commands
│   ├── Permissions              generated, do not edit
│   └── Supported versions       generated, do not edit
└── Background                   hub
    ├── Detection modes
    └── Scope and non-goals

Mapping file kept in the code repository, so the generator updates
pages instead of creating duplicates:

  docs-outline.json
  {
    "collectionId": "<uuid>",
    "pages": {
      "reference/configuration.md":      "<documentId>",
      "reference/permissions.md":        "<documentId>",
      "reference/supported-versions.md": "<documentId>"
    }
  }

Banner placed at the top of every generated document:

> :robot: Generated from `src/main/resources/config.yml` by the
> `publish-docs` workflow. Manual edits are overwritten on the next release.

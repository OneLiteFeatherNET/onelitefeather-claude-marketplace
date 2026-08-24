# Publishing to Outline

## What the platform gives you

Outline has real hierarchy: collections contain documents, documents nest arbitrarily deep, and the sidebar reflects that tree without a hand-maintained navigation file. It has full-text search, per-collection permissions and a stable document ID for every page.

That makes it the most natural fit of the three targets for Diátaxis, because the four quadrants can be actual structure rather than a naming convention.

It also has one weakness that decides the whole design: documents are edited in the UI by people, so anything generated has to be pushed through the API and protected from well-meaning edits.

## Structure

One collection per project. Four top-level documents inside it, one per quadrant, each acting as a hub with its pages nested underneath:

```
Collection: <Project>
├── Getting started            (tutorial, one page, no children)
├── How-to guides
│   ├── Send alerts to Discord
│   ├── Notify staff in game
│   └── ...
├── Reference
│   ├── Configuration          generated
│   ├── Commands
│   ├── Permissions            generated
│   └── Supported versions     generated
└── Background
    ├── Detection modes
    └── Scope and non-goals
```

Name the hubs for the reader's situation, not the framework. "Background" reads better than "Explanation" to someone who has never heard of Diátaxis, and "Getting started" is understood everywhere. The internal name of the quadrant matters to the writer, not the reader.

Each hub document is a real page with two or three sentences saying what belongs there and a list of its children, not an empty container. Readers land on hubs from search.

## Working through the API

The Outline tools are deferred: run `tool_search` for the Outline document tools before the first call, otherwise the calls fail on wrong parameter names.

Conventions that keep an Outline docs set stable:

- **Edit with `editMode: "patch"`, never `replace`.** A replace on a page someone else is editing loses their work.
- **Store document IDs alongside the source.** A mapping file in the code repository (page path to Outline document ID) is what lets a generator update the same page instead of creating duplicates. Resolving pages by title breaks the moment a title is edited.
- **Create the hub documents first**, then create children with the hub as parent. Moving documents afterwards is possible but reorders the sidebar in ways that surprise people watching.

## Generated pages

Same rule as everywhere: the generator output is pushed, never typed. Additionally, in Outline:

- Start every generated document with a callout stating the source and that edits are overwritten on the next publish. Outline's edit history will otherwise make it look like a person broke the page.
- Give generated documents their own naming or an emoji prefix in the sidebar so editors can see at a glance which pages they may not touch.
- Push on release, not on every commit. Outline shows every update in the activity feed and to subscribers; a generator running on each push turns the feed into noise and trains people to ignore it.

## Relationship to ADRs

Where a project already keeps architecture decision records in Outline, keep them in their own collection and link, do not merge. The ADR is the internal record with status and consequences; the explanation page is the outward-facing narrative and may summarise several ADRs. Duplicating the content means the two disagree within a quarter.

The natural link direction is explanation to ADR: the user-facing page says what and why in prose, and offers the ADR for the reader who wants the full decision trail.

## When Outline is the wrong target

If the documentation must ship with the software, be readable offline, or be diffed in review, it belongs in the repository. Outline is a good fit for documentation maintained by a team with accounts, and a poor fit for documentation that end users of an open-source project need without logging in. Check whether the collection is publicly shared before making it the only home for user documentation.

# Publishing to Outline

## What the platform gives you

Outline has real hierarchy: collections contain documents, documents nest arbitrarily deep, and the sidebar reflects that tree without a hand-maintained navigation file. It has full-text search, per-collection permissions and a stable document ID for every page.

It has one weakness that decides the whole design: documents are edited in the UI by people, so anything generated has to be pushed through the API and visibly marked as off-limits.

At OneLiteFeather, Outline is not a publication target that a repository docs set gets mirrored into. It is where prose lives by default. A `docs/` directory in a repository is the exception, not the baseline — see "When the repository is the right target" at the end.

## The unit is the hub document, not the collection

The single most common mistake is creating a collection for a project. Do not. Collections at OLF are long-lived organisational domains with their own permissions and their own audience, and they already exist:

| Collection | What belongs there |
|---|---|
| `Entwicklung` | Application and library code, developer-facing standards, anything a developer reads to build something |
| `Infrastruktur` | Cluster, deployment, operations, access — admin-managed, most people have read-only |
| `Konzepte - MiniGames` | Game concepts, following the Requirement-Engineering standard rather than the quadrants |
| `Organisation` | Team processes, roles, ways of working |
| `Architecture Decision Records` | ADRs only, MADR 4.0, numbered `ADR-NNNN` |
| `Vault` | The knowledge graph, owned by the `vault-knowledge-graph` skill — never hand-place documents there |
| `Meetings`, `Branding`, `Social Media`, `Server Upgrades` | As named |
| `OLD_*` | Legacy. Never write there. |

A project, a library, a subsystem or a standard becomes a **top-level document inside the fitting collection**, and that document is the hub. Its quadrant pages are its children. This is already the established pattern — `Reusable GitHub Actions Workflows`, `Apus UI — Auslieferung & Runtime-Konfiguration` and `Requirement Engineering — Start hier` are all built this way in `Entwicklung`.

Why this beats a collection per project: collections are the permission and sidebar unit, so one per project splits permissions nobody wants split and produces a sidebar that scrolls. It also has no place for the things that are not projects at all — an engineering standard, a shared workflow catalogue, a convention — which is most of what gets documented.

## Structure

Shape only. Child titles change — read the live tree with `list_collection_documents` before
naming or updating anything.

```
Collection: Entwicklung
├── Reusable GitHub Actions Workflows        ⚙️  hub
│   ├── Tutorial: Pipeline-Setup für ein neues Repo
│   ├── How-To: Häufige Anpassungen
│   ├── Reference: Workflow-Inputs & Defaults      generated
│   └── Explanation: Design-Entscheidungen
├── Requirement Engineering — Start hier     📋  hub
│   ├── Tutorial: Erstes Anforderungsdokument
│   ├── How-To: Anforderungsdokument anlegen
│   └── Reference: Anforderungs-Template Felder
│       ├── Vorlage: Anforderungen (Spielkonzept)
│       └── Vorlage: Anforderungen (Technisches Projekt)
└── LuckPerms korrekt laden (Titan & …)         single document, no hub
```

**The quadrant is a title prefix on the child**, not a container document. `Tutorial: `, `How-To: `, `Reference: `, `Explanation: ` — exactly those four spellings, in English, even though the documents themselves are German. Four extra container documents per subject would be four pages with nothing on them; the hub already carries the routing table.

**Hub titles** are either the subject itself (`Reusable GitHub Actions Workflows`) or the subject plus `— Start hier` when the page's whole job is to be an entry point (`Engineering-Standards — Start hier`). Give every hub a real emoji icon; it is what people navigate the sidebar by.

**Templates and worked examples** nest one level deeper, under the page they belong to, prefixed `Vorlage: ` or `Beispiel: `.

## Start with one document, split when it stops working

Most subjects do not need a hub. `LuckPerms korrekt laden (Titan & andere Minestom-Projekte)` is a
single top-level document in `Entwicklung` and correctly so. `SOPS — Secrets im
Kubernetes-FLUX-Repo` shows the other end of the same life cycle: it grew four quadrant children
and became a hub, under `Kubernetes-FLUX — GitOps für feather-core` in `Infrastruktur`.

Promote a single document to a hub when either signal appears:

- It serves two reader states at once — someone learning it and someone looking a value up in it — which the routing test in `SKILL.md` will tell you.
- A section has grown past roughly a screenful and readers are scrolling past it to reach the rest.

When you promote it, the old document becomes the hub: it keeps its title, its ID and its inbound links, and its sections move out into children. Creating a new hub next to it and leaving the old page as a stub breaks every existing link and leaves two pages competing in search.

## Create quadrants on demand

The volume rule is in `SKILL.md` under "How the work actually goes" and holds for every target. A
hub carrying two how-tos and nothing else is a complete docs set for what it covers; an empty
`Tutorial:` or `Explanation:` child is not owed.

On Outline the rule bites harder than elsewhere: a placeholder is a search result and a sidebar
entry, so a document saying "TBD" gets found and opened repeatedly in a way an empty directory
never is.

## The hub document itself

The hub is the index page from `SKILL.md`, in OLF's voice. The skeleton lives in
`assets/nav-templates/outline-structure.md`, section "Hub document skeleton" — copy it from there
rather than from here, so the two cannot drift apart.

The `Wo soll ich lesen?` table is the reader-facing routing table: the left column is a reader intent in the reader's words, the right column is the link. The reader never has to learn the word Diátaxis to use it — the quadrant name appears only inside the link title, where it reads as a category label rather than a demand.

The `Pflege` section is what stops a hub from rotting silently. Name the source of truth explicitly, especially where it is code rather than the page.

Every new child document gets linked from its hub — from the routing table if it is one of the four, from `Weiterführend` otherwise. A document that is only reachable by search is, in practice, lost.

## What the quadrants do not cover

Diátaxis governs documentation *about a subject for someone using it*. It does not govern the operational record, and forcing that record into four quadrants is how the quadrants stop meaning anything. The record has its own parent nodes and its own title patterns:

| Kind | Where | Title pattern |
|---|---|---|
| Design doc, spec | `Archiv — Design-Dokumente und Umsetzungspläne` → `Design-Dokumente` | `YYYY-MM-DD — <Thema> (Design)` |
| Implementation plan | `Archiv — Design-Dokumente und Umsetzungspläne` → `Umsetzungspläne` | `YYYY-MM-DD — <Thema> (Plan)` |
| Incident | `Vorfälle` | `YYYY-MM-DD — <was passiert ist>` |
| Runbook for an application | `Anwendungs-Runbooks` | The application name, plain |
| Runbook for a task | `Runbooks` | `Runbook: <Tätigkeit>` |
| Architecture decision | `Architecture Decision Records` collection | `ADR-NNNN — <Entscheidung>` |
| Game concept | `Konzepte - MiniGames` | Concept name, children numbered `1.`, `2.`, … |

The `documenting-in-outline` skill owns these placements in full; this table exists so the boundary is visible from inside a Diátaxis task. Two consequences worth stating:

- **A design document is frozen history, a runbook is live.** Merging them produces a page that is not read as a design record and not found as a runbook.
- **An explanation page links to the ADR, it does not restate it.** The ADR is the decision trail with status and consequences; the explanation page is the outward-facing narrative and may summarise several ADRs. Duplicated, the two disagree within a quarter.

This is also where the "no dumping grounds" rule from `SKILL.md` lands in Outline. It still holds *inside* a subject: no `FAQ` and no `Sonstiges` child under a hub, because those children fill with whatever nobody sorted. A child titled `How-To: Häufige Deployment-Fehler beheben` is not that — it is a how-to with a task title, and it is fine. What the rule does not mean is that the operational record has to be squeezed into the quadrants.

## Language

Outline is internal, and the working language is German. Documents are written in German, including the ones a Diátaxis task produces.

Two things stay English: the four quadrant prefixes, because they are the established convention and mixing `Anleitung:`/`How-To:` would break sidebar sorting and search; and any content quoted from code — keys, flags, commands, error strings.

The rule that how-to titles start with a verb becomes, in German, that the title is an infinitive phrase with the verb at the end: `How-To: Renovate-Preset einbinden`, `How-To: Anforderungsdokument anlegen`. A bare noun phrase like `How-To: Häufige Anpassungen` is the same drift toward reference that an English noun title signals, and reads as a section heading rather than a task.

Published documentation for open-source repositories is English with translation through Crowdin, matching the code and commit convention. That is the repository target, not this one.

## Working through the API

- **Load the tools first, by keyword and not by bare name.** They are deferred, and their
  registered names carry an MCP server prefix that differs per install, so a `select:` query on
  bare names matches nothing. Use ToolSearch with `+outline list collections documents create update
  fetch`, then call them by the fully-qualified names the result prints. Note that
  `list_collection_documents` takes a `collectionId` UUID, not the collection name in the table
  above — resolve it with `list_collections` first.
- **Get the user's go-ahead before the first write, every time.** Outline is shared, and every create and update lands in other people's activity feed and subscriptions. Show the exact titles, the parent document and the collection in one message and wait — for a single document as much as for a set. Reading (`list_collection_documents`, `fetch`) never needs approval; `create_document` and `update_document` always do. This is the gate from `SKILL.md`, restated here because this is the file open at the moment of the write.
- **Read the structure before writing.** `list_collection_documents` on the target collection, every time. It costs one call and decides parent, title and shape. Placing a document top-level in a collection because the existing tree was never read is the second most common mistake after creating a collection.
- **Check whether the document already exists**, and update it rather than putting a second one beside it.
- **Edit with `editMode: "patch"`, never `replace`.** A replace on a page someone else is editing loses their work, and loses rich formatting markdown cannot carry. `patch` requires `findText` — the exact existing markdown to replace, copied verbatim from the document you just fetched. If `findText` does not match, fetch the document again and correct it; never fall back to `replace` to get past the error. `append` and `prepend` are safe alternatives when you are adding rather than changing.
- **No H1 at the top.** The title is a separate field; the body starts with prose or `##`.
- **`icon` is a real emoji** (`"⚙️"`), not a shortcode.
- **`parentDocumentId` is enough** — the collection is inherited from the parent.
- **Create the hub first**, then the children with the hub as parent. Reordering afterwards is possible but shuffles the sidebar for everyone watching.
- Use `:::info` / `:::warning` … `:::` callouts for what would otherwise wake someone at night.

## Generated pages

The repository stays the source of truth for anything generated; the Outline page is a publication of it and never a place where it is typed.

- **Store the document IDs in the repository** next to the generator, in a mapping file. Resolving pages by title breaks the moment someone edits a title, and the generator then creates a duplicate instead of updating.
- **Open every generated document with a callout** naming the source file and stating that edits are overwritten. Without it, Outline's edit history makes the next overwrite look like someone broke the page.
- **Mark them in the sidebar** — an emoji prefix is enough — so editors can see which pages they may not touch.
- **Push on release, not on every commit.** Outline shows every update in the activity feed and to subscribers; a generator on every push turns that feed into noise and trains people to ignore it.

## When the repository is the right target

Outline is the default for OLF documentation, but not for everything. The repository wins when the documentation must ship with the software, be readable offline, be diffed in review, or be reachable by people who do not have an Outline account — which is every user-facing docs set of a public open-source project.

Check whether the target collection is actually shared publicly before making Outline the only home for user documentation. That is a live permission setting on the instance, not something this file can record: read it in the collection's share settings, and ask the user if you cannot. Guessing it wrong either publishes internal material or hides user documentation from the people it is for, and both fail silently.

Where both are needed, split by audience rather than duplicating: user documentation in the repository, the internal view — operations, decisions, the things that are nobody's business outside the team — in Outline, linked to each other.

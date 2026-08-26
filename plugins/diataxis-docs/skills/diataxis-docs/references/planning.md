# Planning a documentation set

Only when a whole set is being mapped before its pages are written — because nothing exists yet, or
because everything lives in one overloaded README. When the project already publishes a docs set,
that is Auditing instead; see `auditing.md` and its five-page cap.

The map is a running inventory of what exists and what is missing. It is not a scaffold of empty
pages to fill, and producing it is not the deliverable — the first published page is.

## Step 0 — read the project

Every title in the map has to trace back to something you opened. In this order:

1. **Whatever documentation the project already publishes.** If it is more than a stray page or
   two, this is not Planning: stop and switch to Auditing. Planning reads what exists only to
   confirm that it does not, and to avoid the two commonest failures — proposing a title that
   already exists, and contradicting a page nobody opened.
2. **The README, routed section by section.** The procedure and the routing table are in
   `auditing.md`; they apply here as much as there.
3. **The configuration source.** Precedence and the disagreement rule are in `SKILL.md` under "The
   reference quadrant" — they hold in every mode, not only this one.
4. **The command or CLI registration.**
5. **The manifest or build definition**, for permissions and supported versions. Which of the two
   holds them is per stack: a Bukkit/Paper plugin declares permissions in `plugin.yml`, a
   Micronaut or Spring service in the build definition and the security configuration. Read the one
   this project actually has.
6. **The git history**, for `Since` values — and only where it genuinely answers the question. See
   `reference-pages.md` before filling a `Since` row.
7. **The issue tracker's recurring questions**, where reachable.

## The map

Real page titles from the project, never placeholders.

**How-to titles**, each beginning with a verb. List the candidates; write only the ones someone has
actually asked for. A map with eight titles and two written pages is correct — the other six are a
record of what is missing, not a backlog you are committed to.

**Tutorials.** At most one in the usual case, but two are a smell rather than an error: if the
second serves a reader who already knows what they want, it is a how-to; if it serves a genuinely
different learner — a library's users and its contributors, an operator and a developer — two are
correct.

**Reference pages** structured after the machinery, not after guessed reader intent. For each one,
decide immediately whether it is hand-written or generated, and mark it. Marking is this task;
building the generator is not — see `SKILL.md`.

**Explanation pages** named after the question they answer, including the ones maintainers are
tired of answering in chat.

## The layout

Decide the publishing target first — the ordered rule is in `SKILL.md` — because the target decides
what the layout is made of. On Outline it is one hub document with title-prefixed children and the
tree below does not apply; see `publishing/outline.md`.

For the repository target, a directory per quadrant, the quadrant names being the directory names,
because the structure is itself the signpost:

```
docs/
├── tutorial/
├── how-to/
├── reference/
├── explanation/
└── index.md
```

Each directory arrives with its first page. Creating all four empty is the single most common way
to start badly.

`index.md` names the entry points in the reader's language — learn, do a task, look something up,
understand the background — opening with a sentence or two saying what the project is. It is an
overview, not a link list, and it has to work for someone who arrived from a search result.

## What to hand back

The map, the target named in one line, the generated/hand-written marking per reference page, and
**one page actually written**. A map with no page attached is a proposal, and proposals go stale
before anyone acts on them.

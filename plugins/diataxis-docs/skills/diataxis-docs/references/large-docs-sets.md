# Structure at scale

Four flat directories is the shape of a small docs set, not a rule. Diátaxis posits four *kinds* of
documentation around which documentation is structured; it does not require exactly four divisions
in the hierarchy. A more complicated tree is fine as long as the different forms and purposes are
not muddled together — that is the only binding constraint.

Read this when a quadrant has outgrown a single list, when the same subject has to be documented for
two different audiences, or when a docs set spans several products or platforms.

## Nesting inside a quadrant

The first thing that breaks is the how-to list. Group it:

```
how-to/
├── install/
│   ├── local.md
│   ├── docker.md
│   └── virtual-machine.md
├── configure/
└── operate/
```

The group is still how-to, and each leaf still has a verb-first title naming a reader goal. What is
forbidden is a group whose membership rule is "did not fit anywhere else".

Reference nests along the machinery it describes — module, class, method; config section, key;
command, subcommand, flag — rather than along reader intent. That mirroring is what makes gaps
visible.

## Two dimensions: quadrants against something else

The common hard case is a subject documented for more than one audience: users, developers building
on it, and contributors to it. Or one product on three platforms. Or a library plus its CLI.

Ask first whether these are effectively different products for different people. If so, let *that*
be the top of the tree and give each its own four quadrants:

```
docs/
├── using-it/        tutorial/ how-to/ reference/ explanation/
├── building-on-it/  tutorial/ how-to/ reference/ explanation/
└── contributing/    tutorial/ how-to/ reference/ explanation/
```

If they are one product with one audience that occasionally has a platform-specific step, keep one
set of quadrants and put the axis *inside* them (`how-to/install/{local,docker,vm}`). Splitting at
the top when the audiences are really the same duplicates three quadrants and guarantees drift.

The same question resolves the tutorial-count issue: a genuinely separate learner justifies a
separate tutorial. `tutorial/for-operators.md` and `tutorial/for-contributors.md` are two correct
tutorials, not one tutorial and one mislabelled how-to.

## Contents lists

Keep a list of links to roughly seven items. Past that, readers stop reading the list and start
scanning for a word, which is the point at which grouping earns its cost. Group into subsections
before the list grows, not after.

## Landing pages

Every level of the tree that has children needs a page, and that page is an overview with prose, not
a bare list of links. It states what the section covers, what the reader will find in each part and
which part they probably want. A reader may enter the documentation at any depth — from a search
result, a chat link, a bookmark — so no page can assume arrival from above.

Name sections for the reader's situation, never for the framework: getting started, how-to guides,
reference, background.

## When the shape gets uncomfortable

If applying the quadrants produces a tree that feels contorted, the tree is wrong, not the reader.
You are authoring for a human, not satisfying a scheme. Rearrange until it reads well, keeping only
the one rule that actually matters: no page mixes two of the four modes.

---

Canon source for this material: `https://diataxis.fr/complex-hierarchies/`, which diataxis.fr
removed in a site restructure — verified 404 on 2026-08-26. Archived snapshot, retrieved the same
day: `https://web.archive.org/web/20260802004758/https://diataxis.fr/complex-hierarchies/`.
Re-check both before citing either, and never state a removal date or snapshot timestamp you have
not verified yourself.

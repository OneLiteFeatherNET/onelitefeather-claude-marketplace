# Auditing an existing documentation set

Most projects do not start from nothing. They start from a README that grew, a wiki with forty
pages, or a docs folder organised by feature. The work is sorting, not writing.

## Audit one page at a time, and fix as you go

Resist tearing it all down and starting again, however tempting a forty-page mess makes it. The
deliverable of an audit is **one page improved and shown to the user**, plus a routing table
covering only the pages you actually opened on the way there. Open at most five pages before making
the first change. A routing table for all forty is a migration plan wearing an audit's clothes: it
costs the whole session, it is stale before it is read, and it leaves the wiki exactly as it was.

Pick the first page in this order, taking the first that applies:

1. the page the user named or complained about;
2. the entry page readers land on — `Home`, `index.md`, the hub — because it is read most and
   shapes everything below it;
3. the page whose title names two modes at once ("Configuration and setup", "Getting started &
   FAQ"), because it is guaranteed to split;
4. the page carrying a value that contradicts another page;
5. only if none of those exist, literally at random.

Then ask the four assessment questions:

1. What user need does this page serve?
2. How well does it serve that need?
3. What can be added, moved, removed or changed to serve it better?
4. Do its language and logic meet the requirements of that mode of documentation?

Question 1 is the one that finds real problems. A page that satisfies every mechanical check below
and answers to no need at all still fails, and only this question catches it.

Then make the single smallest improvement and publish it. Repeat.

## Splitting an overloaded README

Go through the file section by section and route each one with the test in `SKILL.md`. Typical outcome for a mature open-source project:

| README section | Goes to |
|---|---|
| Badges, one-paragraph purpose, download links | stays in README |
| Installation steps | tutorial, if it is the reader's first contact; otherwise how-to |
| Feature list | mostly deleted. It is marketing on the project page, and the reference covers the same ground with precision |
| Configuration snippet | reference, generated |
| Permissions table | reference, generated |
| Command list | reference, generated |
| Supported versions | reference, generated |
| "Goal" and "Not a goal" | explanation, and one of the highest-value pages in the set |
| Debug and troubleshooting | how-to ("Produce a debug log for a bug report") plus reference (log path, rotation, retention) |
| Release process, versioning, commit conventions | out of user docs entirely, into `CONTRIBUTING.md` |

What remains in the README: what the project is in one paragraph, where to download it, where the documentation lives, licence, and how to get help. A README is a signpost, not a manual, because it is the one file that is read by people who have not yet decided to use the software.

Do not delete anything before the target page exists. Move, then link, then remove the original.

**One section per pass, and the README reduction is its own change.** Reducing a README to that
signpost needs its own approval and is never done in the same turn as creating the first
documentation page. Publish the page that replaces a section, link to it from the README where the
section was, and remove the original only after the user has seen the replacement. "Mostly deleted"
for the feature list means *proposed* for deletion with the text shown to the user — never removed
unilaterally.

## Drift detection

Three checks, in decreasing order of how often they find something:

**Same fact in two places.** Search for defaults, version numbers, permission strings and command names appearing in more than one file. Every duplicate is a future contradiction. Keep the one in the reference, replace the others with links.

**Two sources published separately.** Where the same content is maintained in the repository and on a distribution platform, a package listing, or a wiki, they will disagree. Find the pairs and pick one as the source. Real example worth looking for: a repository claiming platform support that the marketplace listing lists as unsupported.

**Facts with no generator.** Any table of options, permissions or versions that a human types is drift waiting to happen. List them, and treat each as a generation task rather than a proofreading task.

## Mechanical second pass

Run this after the four questions, never instead of them. These catch drift; they do not catch
uselessness.

- Does each tutorial promise a nameable outcome, and does it narrate what the reader should see?
- Where there is more than one tutorial, does each serve a genuinely different learner, or is one of
  them a how-to?
- Does every how-to title start with a verb and name the reader's goal? Can it be completed as
  "How to …"?
- Does any page violate the must-not-appear list for its quadrant in `quadrants.md`?
- Does any reference page carry a value judgement — "we recommend", "best practice", "usually you
  want", "it's a good idea"? (Constraints and warnings are not value judgements and belong there.)
- Does any tutorial ask the reader to choose between alternatives?
- Is there a category defined by not fitting elsewhere — FAQ, misc, tips, "advanced usage" —
  collecting unsorted content? Nesting inside a quadrant and a "Troubleshooting X" how-to are not
  that, and are fine.
- Does reference structure mirror the machinery, or has it been reorganised around guessed intents?
- Are there explanation pages at all, or only tutorial, how-to and reference?
- Which reference pages are hand-written that could be generated? Are any values in them unverified
  against the source?
- Does the entry page describe the four routes in the reader's language rather than the framework's,
  and does every page work as a landing page?
- Which three questions do maintainers answer repeatedly in chat, and does a page exist for each?

## Reporting an audit

Report findings as a routing table (section, current location, target quadrant, generated yes/no),
the small number of substantive problems found — contradictions between sources, missing explanation
pages, hand-written reference, pages serving no identifiable need — and the change you already made.
Do not report the whole file back with commentary; the value is in the contradictions, which are the
part a maintainer cannot see from inside the project.

Those contradictions are the predictable payoff, not a lucky find. Sorting content by mode forces
every fact to be attributed to one page, and the moment two pages claim the same fact differently
the conflict becomes visible. Diátaxis does not make documentation accurate, but it reliably exposes
where it is not.

# Auditing an existing documentation set

Most projects do not start from nothing. They start from a README that grew, a wiki with forty pages, or a docs folder organised by feature. The work is sorting, not writing.

## Splitting an overloaded README

Go through the file section by section and route each one with the three routing questions. Typical outcome for a mature open-source project:

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

## Drift detection

Three checks, in decreasing order of how often they find something:

**Same fact in two places.** Search for defaults, version numbers, permission strings and command names appearing in more than one file. Every duplicate is a future contradiction. Keep the one in the reference, replace the others with links.

**Two sources published separately.** Where the same content is maintained in the repository and on a distribution platform, a package listing, or a wiki, they will disagree. Find the pairs and pick one as the source. Real example worth looking for: a repository claiming platform support that the marketplace listing lists as unsupported.

**Facts with no generator.** Any table of options, permissions or versions that a human types is drift waiting to happen. List them, and treat each as a generation task rather than a proofreading task.

## Review checklist for an existing set

- Is there exactly one tutorial, and does it promise a nameable outcome?
- Does every how-to title start with a verb and name the reader's goal?
- Does any reference page contain the words "recommend", "best practice" or "should"?
- Does any tutorial contain "or", "optionally" or a table of alternatives?
- Is there a fifth category (FAQ, troubleshooting, advanced, tips) collecting unsorted content?
- Are there explanation pages at all, or only tutorial, how-to and reference?
- Which reference pages are hand-written that could be generated?
- Does the entry page describe the four routes in the reader's language rather than the framework's?
- Which three questions do maintainers answer repeatedly in chat, and does a page exist for each?

## Reporting an audit

Report findings as a routing table (section, current location, target quadrant, generated yes/no) followed by the small number of substantive problems found: contradictions between sources, missing explanation pages, hand-written reference. Do not report the whole file back with commentary; the table is the deliverable, and the value is in the contradictions, which are the part a maintainer cannot see from inside the project.

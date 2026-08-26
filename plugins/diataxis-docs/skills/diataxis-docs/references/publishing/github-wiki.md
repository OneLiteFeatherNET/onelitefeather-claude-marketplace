# Publishing to a GitHub wiki

## What the platform gives you

A wiki is a second git repository next to the code, reachable at `https://github.com/<owner>/<repo>.wiki.git`. It can be cloned, committed to and pushed like any other repository, which is what makes automated publishing possible at all.

Three constraints shape everything else:

- **The page namespace is effectively flat.** A page's file name is its title, and the wiki has no navigation tree of its own. Directory structure does not become navigation.
- **There is no pull request flow.** Anyone with write access commits straight to the wiki, and nothing is reviewed. Content that must stay correct cannot live only here.
- **The wiki is not versioned with the code.** A user reading the wiki sees the current state, not the state matching the release they installed.

The consequence for Diátaxis: the quadrants have to be encoded in page titles and in a hand-maintained sidebar, and the reference quadrant must be pushed by CI from the code repository rather than edited in place.

## Working with the wiki

Clone it before proposing anything, then read only as far as the five-page cap in `references/auditing.md` allows — the entry page plus wherever that file's pick order leads. Reading all forty pages before changing one produces exactly the migration plan that file warns against; for the shape of the rest, the page list and `git log` are enough.

```
git clone https://github.com/<owner>/<repo>.wiki.git
```

Because the wiki has no pull-request flow, a push is live for every reader the moment it lands and cannot be reviewed afterwards. **Never push.** Commit locally, show the user the file list and the diff, and let the user push. Never change `_Sidebar.md` or `_Footer.md` in the same change as a content page — the navigation renders on every page, so a mistake there is a mistake everywhere.

## Naming

Encode the quadrant in the title, because the title is the only structure the platform preserves:

```
Home.md
Tutorial-First-detection.md
How-to-Send-alerts-to-Discord.md
How-to-Notify-staff-in-game.md
Reference-Configuration.md
Reference-Commands.md
Reference-Permissions.md
Explanation-Detection-modes.md
Explanation-Not-a-performance-plugin.md
```

Hyphens display as spaces, so the rendered titles read as sentences. The prefix survives search and the page list, which is where readers actually navigate from.

## Navigation

`_Sidebar.md` renders on every page and is the real table of contents. Group by quadrant, name the groups in the reader's language, and keep it hand-written and short. `_Footer.md` is a good place for the "edit on GitHub" pointer and the licence line.

Templates in `assets/nav-templates/_Sidebar.md` and `_Footer.md`. Both are example content, not fill-in skeletons — read their header comments before copying anything out of them.

Link between pages with `[[Page Title]]`. Cross-quadrant links are load-bearing here: with a flat namespace, links are the only thing keeping a how-to connected to its reference page.

## Publishing generated reference pages

The wiki is a separate repository, so a workflow in the code repository has to push into it. Shape of the job:

1. Run the reference generator on the code repository.
2. Check out the wiki repository into a temporary directory.
3. Copy the generated files over the `Reference-*.md` pages.
4. Commit only if something changed, then push.

Two rules that keep this from causing damage:

- Put a banner at the top of every generated page: generated from which source, by which workflow, and that manual edits are overwritten. Without it someone will fix a typo in the wiki and lose it on the next run.
- Never let the workflow touch non-generated pages. Restrict it to the `Reference-` prefix.

The drift gate from `references/reference-pages.md` still runs in the code repository. The wiki push is publication, not verification.

## When not to use a wiki

If the documentation must match the installed version, or must be reviewed before it changes, a wiki is the wrong target and the docs belong in the code repository with a docs site rendered from it. The wiki is a good fit for community-maintained how-tos and a poor fit for a version-sensitive reference.

A workable split: reference and tutorial live in the repository and are published to a site, how-to and explanation live in the wiki where contributors can add to them without a pull request. State the split on `Home.md` so readers know which they are looking at.

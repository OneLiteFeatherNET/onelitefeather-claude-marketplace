# Worked example: a Minecraft plugin

A documentation map for a Paper plugin that detects redstone clocks, alerts staff and can remove the clocks, with four of its pages written out in full as voice models plus the index. Modelled on a real project whose entire documentation was a single long README.

Read this example when planning a docs set from an existing README, or when a page in one of the quadrants needs a model to copy the voice from.

## The audit that produced it

Each README section routed with the test in `SKILL.md`, using the generic table in `references/auditing.md`:

| README section | Target | Generated |
|---|---|---|
| Badges, purpose paragraph, download links | stays in README | no |
| Installation | `tutorial/first-detection.md` | no |
| Feature list | proposed for deletion, full text shown to the user first | n/a |
| Config snippet with comments | `reference/configuration.md` | yes, from the config source |
| Permissions | `reference/permissions.md` | yes, from `plugin.yml` |
| Command list | `reference/commands.md` | yes, from the command parser |
| Supported versions | `reference/supported-versions.md` | yes, from `api-version` in `plugin.yml` plus the API dependency in the build definition |
| "Goal" and "Not a goal" | `explanation/not-a-performance-plugin.md` and `explanation/unsupported-platforms.md` | no |
| Debug logging | `how-to/produce-a-debug-log.md` and `reference/debug-log.md` | partly |
| Release cycle, SemVer, commit conventions | published to `CONTRIBUTING.md`, section removed later in its own approved change | no |

Nothing here was removed from the README in the same turn as the page that replaced it. Each row
was published as a page, linked from the README where the section stood, and the original removed
only in a later change the user approved on its own. The routing was one pass; the README reduction
was another.

Which file holds permissions and supported versions is per stack, not universal: a Bukkit/Paper
plugin declares them in `plugin.yml`, a Micronaut or Spring service in the build definition and the
security configuration. Read the one this project actually has before marking a page generated.

Two findings surfaced during the audit itself. This is the predictable payoff rather than luck: sorting by mode forces every fact onto exactly one page, and the moment two pages claim the same fact differently the conflict becomes visible.

- The same platform-support claim appeared in the README and on the distribution listing, and the two disagreed about one platform. A single generated compatibility page removes the possibility.
- Two configuration keys described the same behaviour in two different sections of the config file. Writing the reference forced the question of which one is authoritative.

## The map

This is where the set ended up after several rounds, not a scaffold created on day one. The how-to
pages arrived first, one at a time, as people asked for them; the reference pages once values were
being repeated in chat; five of the six explanation pages because the same question came back a
third time. The tutorial was written last.

```
docs/
├── index.md
├── tutorial/
│   └── first-detection.md
├── how-to/
│   ├── send-alerts-to-discord.md
│   ├── notify-staff-in-game.md
│   ├── ignore-a-world.md
│   ├── replace-clocks-with-a-warning-sign.md
│   ├── suppress-false-positives.md
│   ├── produce-a-debug-log.md
│   └── migrate-from-the-original-plugin.md
├── reference/
│   ├── configuration.md          generated
│   ├── commands.md               generated
│   ├── permissions.md            generated
│   ├── supported-versions.md     generated
│   ├── clock-types.md
│   ├── message-placeholders.md
│   └── debug-log.md
└── explanation/
    ├── why-clocks-cost-performance.md
    ├── detection-modes.md
    ├── the-tps-threshold.md
    ├── default-ignored-worlds.md
    ├── not-a-performance-plugin.md
    └── unsupported-platforms.md
```

One tutorial, which is right here because a plugin's user and its operator are the same person; a library documented for both consumers and contributors would correctly have two. Seven how-tos, every title starting with a verb — at seven the list is at the point where grouping starts to pay off, see `references/large-docs-sets.md`. Four of seven reference pages generated. Six explanation pages, of which five answer questions the maintainers were previously answering by hand in chat.

## Files in this example

- `index.md` — the entry page, written in the reader's language
- `tutorial/first-detection.md`
- `how-to/send-alerts-to-discord.md`
- `reference/configuration.md` — excerpt showing the generated form and its banner
- `explanation/detection-modes.md`

The four page files are deliberately different in voice. Read them in that order to see the shift from "we, together, one path" to "here is a fact, no advice".

The other seventeen pages in the map are not written out; this example exists for the voice and the routing, not as a corpus. `assets/nav-templates/SUMMARY.md` and `assets/nav-templates/_Sidebar.md` show what a navigation file for a set like this looks like — they cover the subset written out here plus a few more, not the whole map, and are marked as examples rather than fill-in templates.

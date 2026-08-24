# Worked example: a Minecraft plugin

A complete small documentation set for a Paper plugin that detects redstone clocks, alerts staff and can remove the clocks. Modelled on a real project whose entire documentation was a single long README.

Read this example when planning a docs set from an existing README, or when a page in one of the quadrants needs a model to copy the voice from.

## The audit that produced it

Each README section routed with the three questions from `SKILL.md`:

| README section | Target | Generated |
|---|---|---|
| Badges, purpose paragraph, download links | stays in README | no |
| Installation | `tutorial/first-detection.md` | no |
| Feature list | deleted; the reference covers it precisely | n/a |
| Config snippet with comments | `reference/configuration.md` | yes, from the config source |
| Permissions | `reference/permissions.md` | yes, from the build definition |
| Command list | `reference/commands.md` | yes, from the command parser |
| Supported versions | `reference/supported-versions.md` | yes, from the build definition |
| "Goal" and "Not a goal" | `explanation/scope.md` | no |
| Debug logging | split: `how-to/produce-a-debug-log.md` and `reference/debug-log.md` | partly |
| Release cycle, SemVer, commit conventions | `CONTRIBUTING.md`, out of user docs | no |

Two findings that only surfaced during the audit, which is the usual pattern:

- The same platform-support claim appeared in the README and on the distribution listing, and the two disagreed about one platform. A single generated compatibility page removes the possibility.
- Two configuration keys described the same behaviour in two different sections of the config file. Writing the reference forced the question of which one is authoritative.

## The map

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

One tutorial. Seven how-tos, every title starting with a verb. Four of seven reference pages generated. Six explanation pages, of which five answer questions the maintainers were previously answering by hand in chat.

## Files in this example

- `index.md` — the entry page, written in the reader's language
- `tutorial/first-detection.md`
- `how-to/send-alerts-to-discord.md`
- `reference/configuration.md` — excerpt showing the generated form and its banner
- `explanation/detection-modes.md`

The four page files are deliberately different in voice. Read them in that order to see the shift from "we, together, one path" to "here is a fact, no advice".

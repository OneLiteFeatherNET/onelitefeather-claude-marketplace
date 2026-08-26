# Send alerts to Discord

Post every detection into a Discord channel, so staff see clocks without watching the console.

**Before you start:** a webhook URL from the target channel's integration settings.

1. Put the URL in `notification.discord.webhook`.
2. Add `discord` to the `notification.enabled` list.
3. Run `/arcm reload`.

```yaml
notification:
  enabled:
    - console
    - discord
  discord:
    webhook: "https://discord.com/api/webhooks/..."
    description: |
      <red><bold>Redstone clock in <world> at <x>,<y>,<z></bold>
```

The placeholders available in `description` are listed in [message placeholders](../reference/message-placeholders.md). Colour, avatar and embed fields are documented in [configuration](../reference/configuration.md).

## Check it worked

Build a clock in a world that is not excluded from detection and wait for the next check. A message appears in the channel.

## If nothing arrives

Check whether the console reported the same detection. If it did not, this is a detection problem and not a webhook problem: the world is probably excluded, see [excluding a world from detection](ignore-a-world.md). If the console reported it and Discord did not, the webhook URL is wrong or the channel integration was removed.

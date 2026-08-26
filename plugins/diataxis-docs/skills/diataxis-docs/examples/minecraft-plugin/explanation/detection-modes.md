# Detection modes

`check.mode` has two values, and picking between them is a trade-off between how much the plugin
catches and how much work it does per tick. This page describes what sits behind the two names so
that the choice can be made deliberately rather than by trying both.

## What the two modes are trading

A redstone clock is not a block type. It is a pattern of repeated state changes over time, which
means detecting one requires watching, and watching costs work on the server thread.

The dynamic mode watches state changes as they happen and decides from the timing whether a
structure is looping. It catches unusual designs that no rule anticipated, at the cost of doing
work in proportion to redstone activity. On a server where builders are actively working with
redstone, that activity is high.

The static mode looks for known structural patterns instead. Its cost is roughly independent of
how busy the redstone is, and it misses designs outside the patterns it knows.

The rule of thumb that follows: creative and build servers with heavy legitimate redstone are the
case where static earns its lower recall, survival servers where clocks are usually accidental are
the case where dynamic pays off.

## Why there is a TPS threshold at all

Detection is a background cost, and a server that is already struggling is the worst moment to add
one. The `tps` settings exist so the plugin steps back when the server is under load rather than
competing with whatever is causing the problem. This is also the reason the plugin is not a
performance tool in itself, which is covered in [not a performance plugin](not-a-performance-plugin.md).

## What this means for a decision

If clocks on the server are mostly accidental, start with the default and change nothing. If the
server has a dedicated redstone or creative area, exclude that area rather than switching modes
globally: excluding a world is a smaller change than changing how everything is detected.

Related: [configuration reference for `check.mode`](../reference/configuration.md)

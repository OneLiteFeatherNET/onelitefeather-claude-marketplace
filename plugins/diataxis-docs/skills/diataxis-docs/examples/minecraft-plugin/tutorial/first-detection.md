# Your first detection

In this tutorial we will build a redstone clock and watch the server report it in the console.

You need a Paper server on a supported version, the plugin JAR, and Multiverse-Core installed, which is what the world command below comes from.

## Install the plugin

1. Stop the server.
2. Copy the JAR into `plugins/`.
3. Start the server.

The startup log now contains a line from the plugin naming its version. If that line is missing, the JAR is in the wrong folder.

## Create a world to work in

1. Run `/mv create arc_test normal`.
2. Run `/mv tp arc_test`.

You are now standing in an empty world with nothing else running in it, so anything the plugin reports comes from you.

## Build a clock

1. Place a block of redstone.
2. Place a redstone torch against it.
3. Place a repeater pointing back at the torch and power it.

The torch starts flicking on and off. That is a running clock.

## Watch it get caught

Wait for the next check and look at the server console.

A message appears naming the world and the coordinates of what you just built. The coordinates are the ones you are standing at — that is the part to notice. Run `/arcm display` and the same clock is listed among the cached detections.

Break the redstone torch. The clock stops, and the entry drops off the display shortly afterwards.

## What you did

You installed the plugin, produced a detection on purpose and confirmed it from two places: the console and the in-game command. That is the whole detection loop, and everything else is configuration on top of it.

Next: [send alerts to Discord](../how-to/send-alerts-to-discord.md) so the report reaches staff who are not watching the console.

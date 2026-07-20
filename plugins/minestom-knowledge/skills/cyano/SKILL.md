---
name: cyano
description: How to write and structure tests for Minestom-based projects using Cyano, OneLiteFeather's internal JUnit5 testing extension for Minestom (github.com/OneLiteFeatherNET/Cyano). Use this whenever writing, reviewing, or debugging a test that touches Minestom — creating players/instances in a test, asserting on packets sent to a client, or setting up a JUnit test class for a Minestom server/game project. Cyano is internal and niche enough that general Minestom or JUnit knowledge alone will get the details wrong (extension class, player/instance lifecycle, cleanup order) — always check this skill before writing Minestom test code, even if you're confident you already know JUnit5.
---

# Cyano: testing Minestom code

Cyano is OneLiteFeather's JUnit5 testing extension for [Minestom](https://minestom.net). It was extracted from
Microtus, a Minestom fork that's now abandoned, so that projects depending on its testing improvements wouldn't break.
Cyano is fully backward-compatible with Minestom's own testing module — everything below is either how the shared
mechanics work or an opt-in improvement on top of them.

## Getting started

Every Cyano-based test class needs the extension annotation **directly above the class declaration**:

```java
import net.minestom.testing.extension.MicrotusExtension;
import org.junit.jupiter.api.extension.ExtendWith;

@ExtendWith(MicrotusExtension.class)
class MyFeatureTest {
    // ...
}
```

If the annotation is missing or misplaced, the integration silently fails to wire up — there's no compile error to
catch it, so this is the first thing to check if a Cyano-based test behaves oddly. Once the extension is active, test
methods can request an `Env` (the test environment) as a method parameter — JUnit5 injects it automatically:

```java
@Test
void testSomething(Env env) {
    // env gives you instances, players, connections
}
```

## Creating instances and players

- **Instance:** `env.createEmptyInstance()` for a bare instance, or `env.createFlatInstance()` when the test needs
  actual ground to stand/interact on (e.g. block interactions, physics) rather than an empty void.
- **A player with no coordinates to think about:** `Player player = env.createPlayer(instance);` — spawns at
  `(0, 0, 0)` by default. Use this whenever the test doesn't care about position, which is most of the time; it saves
  you from picking an arbitrary spawn point.
- **A player via a tracked connection** (needed when the test also wants to inspect packets sent to that player):
  ```java
  TestConnection connection = env.createConnection();
  Player player = connection.connect(instance);
  ```

**Example** (a full test, generalized from a real one — asserting an unsupported-operation guard):

```java
@ExtendWith(MicrotusExtension.class)
class TriggerableFeatureTest {

    @Test
    void testUnsupportedTrigger(@NotNull Env env) {
        Instance instance = env.createFlatInstance();
        Player player = env.createPlayer(instance);

        TriggerableFeature feature = new TriggerableFeature(Key.key("mygame:test_feature"), Map.of());

        Exception exception = assertThrows(
            UnsupportedOperationException.class,
            () -> feature.trigger(player)
        );
        assertEquals("This feature is not designed to be triggered.", exception.getMessage());

        env.destroyInstance(instance, true);
    }
}
```

Note the shape: `Env` arrives as a `@Test`-method parameter (not a field), instance/player setup happens inline at
the top of the test, and `env.destroyInstance(instance, true)` runs at the end even for a test that isn't really
about the instance itself — cleanup happens regardless of what the test was checking.

## Asserting on packets

`TestConnection` can track packets sent to its player and hand back a `Collector` to assert on them:

```java
Collector<BossBarPacket> collector = testConnection.trackIncoming(BossBarPacket.class);

// ... trigger the code under test ...

collector.assertSingle(packet -> {
    assertInstanceOf(BossBarPacket.AddAction.class, packet.action());
});
```

Start tracking *before* the action that should produce the packet, not after — `trackIncoming` only sees packets sent
from that point on.

## Cleaning up

Regular Minestom refuses to destroy an `Instance` while players are still connected to it, which turns cleanup into
boilerplate in every test. Cyano's `destroyInstance` removes that friction:

```java
env.destroyInstance(instance, true);
```

The `true` tells it to remove all players from the instance first, then destroy it — do this at the end of every test
that created an instance, so state doesn't leak into the next test.

## Structuring test classes

Minestom test setup (registering a custom player provider, wiring shared fixtures) is often identical across many
test classes in the same feature area. A pattern worth following — seen in `ManisGame`'s test suite — is to factor
that shared setup into an abstract base class the concrete tests extend, rather than repeating it:

```java
@ExtendWith(MicrotusExtension.class)
public abstract class MyFeaturePlayerTestBase {

    @BeforeAll
    static void setUp(Env env) {
        env.process().connection().setPlayerProvider(new MyCustomPlayerProvider());
    }
}
```

Any test that needs `MyCustomPlayer` instead of the default `Player` extends this base instead of repeating the
`@BeforeAll` setup. This is a generic pattern to draw from when a feature area accumulates several tests with the
same setup — not a fixed rule that every test must extend some base class; plenty of small, self-contained tests are
better off without one.

For naming, tests that actually exercise Cyano's environment (creating instances/players, sending packets) read more
clearly with an `...IntegrationTest` suffix, distinguishing them at a glance from plain unit tests that don't touch
Minestom's runtime at all (e.g. a pure logic class tested with plain JUnit, no `Env` involved). Again, treat this as a
useful convention to reach for, not something to force onto every test file.

## Migrating from plain Minestom testing

If a project currently uses Minestom's own testing module directly, moving to Cyano is a drop-in swap:

1. Replace the extension annotation with `@ExtendWith(MicrotusExtension.class)`.
2. Leave everything else as-is — Cyano's extras (default-position player creation, `destroyInstance(instance, true)`)
   are opt-in. Existing tests keep working unchanged; adopt the extras where they simplify things.

## Further reference

`references/api-classes.md` has the full class inventory of `net.minestom.testing`, including classes not detailed
above (`Collector`, `FlexibleListener`, `TestUtils`, `MockBlockGetter`) — read it when this file's examples don't
cover what's needed.

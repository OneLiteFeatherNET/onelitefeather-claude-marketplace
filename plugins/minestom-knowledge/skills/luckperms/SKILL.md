---
name: luckperms
description: How to embed LuckPerms in a Minestom project the way OneLiteFeather does it — bootstrapping the `net.luckperms:minestom-loader` JarInJar loader yourself in main() (Minestom has no plugin folder to drop a jar into), the Adventure-version exclude every LuckPerms dependency needs, the hardcoded `data/` runtime directory LuckPerms creates next to the process (config.yml, its H2 database, downloaded translation bundles, and a self-relocated `libs/` cache), the test-classpath Gson conflict its loader causes, and how to bridge LuckPerms permission checks across a classloader boundary (e.g. into a CloudNet bridge extension — see the `cloudnet` skill). Use this whenever adding LuckPerms to a Minestom project, wiring up permission checks, debugging why a `data/` folder full of jars and a database appeared next to the server, or a LuckPerms-loaded test run breaks with a Gson/registry error — generic LuckPerms docs (written for Bukkit/Velocity/Sponge, which auto-load plugins from a folder) won't cover any of this, since Minestom has no plugin loader for LuckPerms to hook into.
---

# LuckPerms in a Minestom project

LuckPerms has no Bukkit/Velocity-style plugin folder to drop a jar into on Minestom — there's no plugin loader
scanning a directory at startup. Instead, `net.luckperms:minestom-loader` is a small **JarInJar loader library**:
you depend on it directly, and your own `main()` bootstraps it. Everything below follows from that one
difference.

## Bootstrapping

Add `minestom-loader` as both `runtimeOnly` (it's what actually runs) and `compileOnly` (your code calls
`MinestomLoader.get()` directly, so it needs to be on the compile classpath too), plus `net.luckperms:api` to
interact with LuckPerms once it's running:

```kotlin
dependencies {
    compileOnly(libs.luckperms.api) {
        exclude(group = "net.kyori.adventure")
    }
    runtimeOnly(libs.luckperms.minestom.loader) {
        exclude(group = "net.kyori.adventure")
    }
    compileOnly(libs.luckperms.minestom.loader) {
        exclude(group = "net.kyori.adventure")
    }
}
```

Then, as early as possible in `main()` — before anything that might need a permission check — bootstrap it:

```java
me.lucko.luckperms.minestom.loader.MinestomLoader.get().load().registerShutdownHook().start();
```

`.load()` extracts LuckPerms' actual bootstrap class from an embedded `luckperms-minestom.jarinjar` via an
isolated `JarInJarClassLoader` and instantiates it; `.registerShutdownHook()` wires clean shutdown into the JVM;
`.start()` brings LuckPerms up and returns once it's ready — `LuckPermsProvider.get()` is safe to call only after
this returns.

**Don't try to load LuckPerms as a Minestom extension instead.** The `minestom-loader` jar does ship its own
`extension.json` (pointing at `me.lucko.luckperms.minestom.loader.MinestomLoaderExtension`), but that class isn't
actually present in the artifact as of `5.6-SNAPSHOT` — dropping the jar into `extensions/` and expecting the
`ExtensionBootstrap` (see the `cloudnet` skill) to pick it up won't work. Programmatic bootstrap in `main()` is the
supported path.

## The `data/` directory LuckPerms creates

LuckPerms' Minestom bootstrap resolves its data directory as `Paths.get("data").toAbsolutePath()` —
**hardcoded, not configurable** through any loader API. Whatever the process's working directory is when you run
it, a `data/` folder appears next to it on first boot, containing:

- **`config.yml`** — LuckPerms' own config, auto-extracted with its normal defaults (`storage-method: h2` unless
  changed).
- **A local H2 database file** (e.g. `luckperms-h2-v2.mv.db`) — the default storage backend.
- **`translations/`** — downloaded translation bundles, if `auto-install-translations: true` (the default).
- **`libs/`** — LuckPerms downloads its own runtime dependencies (ASM, ByteBuddy, Caffeine, Configurate,
  the `event` bus lib, an H2 driver, `jar-relocator`, OkHttp/Okio, SnakeYAML) and relocates them with
  ByteBuddy + ASM + `jar-relocator` on first boot, caching the relocated jars here so it doesn't repeat the work
  on later boots.

Two practical consequences:

- **Don't commit `data/`** — it's entirely runtime-generated. Make sure it's gitignored; if you find it already
  checked in, that's a mistake to fix, not a template to copy from.
- **First boot needs outbound network access** to download and relocate those `libs/` dependencies. If a service
  deploys into an offline/sandboxed environment (a locked-down CloudNet node, an air-gapped CI job), either ensure
  egress to fetch them or pre-seed `data/libs` (copied from a normal dev boot) into the deployment template so
  first boot doesn't need the network.

## The Adventure exclude, on every LuckPerms dependency

LuckPerms bundles its own version of Adventure internally. A Minestom project already has Adventure on the
classpath — directly, or transitively through Aves — so **every** `luckperms.*` dependency declaration needs
`exclude(group = "net.kyori.adventure")`, on `api` and `minestom-loader` alike (see the block above). Skipping
this on either one leaves two competing Adventure versions on the classpath, which surfaces as `Component`
serialization or method-resolution errors that don't obviously point back to LuckPerms.

## Guava

LuckPerms expects an **unrelocated** Guava on the classpath. If nothing else in the project provides one (it used
to arrive transitively through CloudNet — no longer true once CloudNet is `compileOnly`, see the `cloudnet`
skill), declare it explicitly:

```kotlin
implementation(libs.guava)
```

## Test classpath: exclude the loader

`minestom-loader`'s JarInJar bundle ships an **unrelocated, outdated Gson**. Tests don't bootstrap LuckPerms at
all, but as a `runtimeOnly` dependency the loader still leaks onto the test runtime classpath, where its bundled
Gson shadows the project's real one and breaks Minestom's own registry init —
`GsonBuilder.disableJdkUnsafe NoSuchMethodError` is the telltale symptom. Exclude it from the test runtime
classpath specifically (compile-time visibility for any LuckPerms-aware test code is unaffected):

```kotlin
configurations.testRuntimeClasspath {
    exclude(group = "net.luckperms", module = "minestom-loader")
}
```

## Using the API once it's running

After `.start()` returns, `LuckPermsProvider.get()` gives you the live `LuckPerms` API instance:

```java
User user = LuckPermsProvider.get().getUserManager().getUser(playerId);
boolean allowed = user != null
    && user.getCachedData().getPermissionData().checkPermission(permission).asBoolean();
```

Guard against `user == null` — a player LuckPerms hasn't loaded/cached yet (very early in connection handling)
looks like "no permissions" rather than throwing, so treat `null` as `false`, not as an error.

## Bridging permission checks across a classloader boundary

LuckPerms lives in the application's own classloader realm (loaded via the JarInJar bootstrap above). If something
elsewhere needs to check a LuckPerms permission but runs in a **different** classloader — most commonly a CloudNet
bridge extension loaded through `ExtensionBootstrap` (see the `cloudnet` skill) — it cannot reference LuckPerms
classes directly; the two realms only share whatever loaded the fat jar itself.

The fix is a small holder class in a module both sides can see, exchanging only JDK types:

```java
// in a shared "common" module — no LuckPerms or CloudNet types here
public final class PermissionBridge {
    private static volatile BiPredicate<UUID, String> resolver;

    public static void setResolver(BiPredicate<UUID, String> permissionResolver) {
        resolver = permissionResolver;
    }

    public static boolean hasPermission(UUID playerId, String permission) {
        BiPredicate<UUID, String> current = resolver;
        return current != null && current.test(playerId, permission);
    }
}
```

The application installs the LuckPerms-backed resolver right after `.start()` returns:

```java
PermissionBridge.setResolver((playerId, permission) -> {
    User user = LuckPermsProvider.get().getUserManager().getUser(playerId);
    return user != null && user.getCachedData().getPermissionData().checkPermission(permission).asBoolean();
});
```

...and the extension living in the other classloader (e.g. implementing CloudNet's `MinestomPermissionChecker`)
just calls `PermissionBridge.hasPermission(player.getUuid(), permission)` — it never references
`net.luckperms.*` directly, so it doesn't matter that it can't see that classloader realm. The resolver returns
`false` before the application has called `setResolver` (early startup), which is the correct "no permission yet"
default rather than throwing.

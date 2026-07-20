# Cyano: full class inventory

SKILL.md covers the workflow (extension setup, instance/player creation, packet assertions, cleanup, test
structuring). This file lists every class in `net.minestom.testing` for quick lookup — read the class itself before
relying on an exact method signature not already shown in SKILL.md.

## `net.minestom.testing` (main)

| Class | Role |
|---|---|
| `Env` (interface) / `EnvImpl` | The test environment injected into `@Test` methods. Verified methods: `createEmptyInstance()`, `createFlatInstance()`, `createPlayer(Instance)`, `createConnection()`, `destroyInstance(Instance, boolean)`, `process()` (gives access to Minestom's `ConnectionManager` etc., used e.g. to swap the player provider). |
| `TestConnection` / `TestConnectionImpl` | A tracked connection for a test player. Verified: `connect(Instance) -> Player`, `trackIncoming(Class<T extends ServerPacket>) -> Collector<T>`. |
| `TestPlayerImpl` | The concrete `Player` implementation used for test-created players. Not read in detail — treat as an implementation detail behind `Env.createPlayer`/`TestConnection.connect`, not something to construct directly. |
| `Collector<T>` | Return type of `trackIncoming`; verified: `assertSingle(Consumer<T>)` for asserting exactly one matching packet was captured. Other assertion methods likely exist (e.g. for zero/multiple packets) — check the class if a test needs more than the single-packet case. |
| `FlexibleListener` | Not read in detail. Name suggests a configurable/ad-hoc event listener helper for tests — check the source before assuming its shape. |
| `TestUtils` | Not read in detail — general test helper utilities. |
| `extension.MicrotusExtension` | The JUnit5 `Extension` class used via `@ExtendWith(MicrotusExtension.class)` (see SKILL.md "Getting started"). |
| `util.MockBlockGetter` | Not read in detail. Name suggests a mock implementation of Minestom's block-getter abstraction for tests that need block data without a real instance. |

## Tests in the Cyano repo itself (useful as reference examples)

- `EnvironmentTest.java`, `IntegrationTest.java`, `TestPlayerIntegrationTest.java` — Cyano's own test suite,
  exercising the `Env`/`TestConnection`/`TestPlayerImpl` surface directly. Worth reading when SKILL.md's examples
  don't cover a specific scenario (e.g. multi-player tests, block interaction tests via `MockBlockGetter`).

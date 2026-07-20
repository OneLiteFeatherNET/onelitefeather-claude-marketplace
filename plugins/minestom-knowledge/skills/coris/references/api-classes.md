# Coris: full class inventory

SKILL.md covers the workflow (shapes, rooms/floors, the component system, doors). This file lists every class for
quick lookup. All core interfaces are `@ApiStatus.Experimental` (see SKILL.md).

## `component`

| Class | Role |
|---|---|
| `Componentable` (interface) | Verified: same add/has/get(/remove) shape as Xerus's `Componentable` (see SKILL.md) — but a distinct type, package `net.onelitefeather.coris.component`. |
| `CorisComponent` (interface) | Marker interface, Coris' equivalent of Xerus's `ObjectComponent`. |

## `shape`

| Class | Role |
|---|---|
| `Shape` (interface, extends `Comparable<Shape>`, `Intersect<Point>`) | Verified: `min() -> Point`, `max() -> Point`. |
| `CuboidShape` (record) | Verified full surface (see SKILL.md): `record CuboidShape(Vec start, Vec end) implements Shape`, compact constructor normalizes to min/max and throws `IllegalArgumentException` if `start`/`end` coincide (`distanceSquared <= 0`). |
| `PointShape` | Not read in detail — the zero-size-area counterpart to `CuboidShape`, for a shape that's genuinely a single point. |

## `util`

| Class | Role |
|---|---|
| `Intersect<T extends Point>` (interface) | Verified full surface: single method `intersect(T position) -> boolean`. Its own javadoc explicitly says callers must not assume a specific dimensional model (2D/3D/hybrid) from the interface alone. |

## `room`

| Class | Role |
|---|---|
| `Room` (interface, extends `Componentable`, `Comparable<Room>`) | Verified: `identifier() -> Key`, `shape() -> Shape`. |
| `BaseRoom` | Verified: constructors `(Key identifier, Shape shape)` and `(Key identifier, Map<Class<? extends CorisComponent>, CorisComponent> components, Shape shape)`. |

## `floor`

| Class | Role |
|---|---|
| `Floor<T>` (interface, extends `Componentable`) | Verified: `add(Key objectId, T object)`, `remove(Key id)`, `identifier() -> Key`. |
| `CorisFloor` | The concrete `Floor` implementation — not read in detail beyond its role. |
| `FloorRegistry<T extends Floor<Room>>` (interface) | Verified: `add(Key, T)`, `remove(Key)`, `clear()`, plus a `Comparator`-aware lookup surface (imports `java.util.Comparator`, `Optional`) — exact lookup method names not confirmed, check the interface. |
| `CorisFloorRegistry` | The concrete `FloorRegistry` implementation. |
| `event.FloorCreateEvent<T extends Floor<? extends Room>>` | Verified full surface: `implements CancellableEvent`, constructors `(T floor)` and `(T floor, boolean cancelled)`, `getFloor() -> T`. Per its own javadoc, only fires when the floor has no invalid data. |
| `event.FloorRemoveEvent` | Not read in full detail — presumably mirrors `FloorCreateEvent`'s shape for removal. |

## `door`

| Class | Role |
|---|---|
| `Door` (sealed interface, permits `BaseDoor`, extends `Componentable`) | Verified: `playAnimation(AnimationState)`, `open()`, `unlock()`, `id() -> UUID`, plus (seen in `BaseDoor`) `key() -> Key`, `face() -> DoorFace`, `shape() -> Shape`. |
| `BaseDoor` (abstract non-sealed) | Verified: constructor `(UUID uuid, Key key, DoorFace face, Shape shape, Map<Class<? extends CorisComponent>, CorisComponent> componentMap)`; implements the identity/component/getter surface but leaves `open()`/`unlock()`/`playAnimation()` for the concrete subclass. |
| `AnimationState` | Not read in detail — the parameter type for `playAnimation(...)`, presumably an enum of animation phases (opening/open/closing/closed or similar). |
| `DoorFace` | Not read in detail — the direction/orientation a door faces. |
| `event.DoorOpenEvent` | Verified full surface (see SKILL.md): `implements InstanceEvent, CancellableEvent`, constructor `(Door, Instance)`, `getDoor()`, `getInstance()`. Cancelling does not automatically stop an in-progress animation — see SKILL.md. |
| `event.DoorCloseEvent` | Not read in full detail — presumably mirrors `DoorOpenEvent`'s shape for closing. |

## Real consumers seen in the OneLiteFeatherNET org

No confirmed external consumer of Coris was found during research (a repo named `Ducula` has its own, separate
`CuboidShape` implementation under a different package — not actually built on Coris). Coris' own test suite
(`src/test/java/net/onelitefeather/coris/`) is the best source of additional real usage beyond SKILL.md's example,
in particular `door/DoorTest.java`, `floor/FloorRegistryTest.java`, and the `shape/intersect/` test package.

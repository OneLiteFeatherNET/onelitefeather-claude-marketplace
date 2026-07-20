---
name: coris
description: How to use Coris, OneLiteFeather's management API for floors, rooms, doors, and shapes on Minestom (github.com/OneLiteFeatherNET/Coris) — defining room/floor structures with Shape-based areas, registries, doors with open/lock behavior, and the associated events. Use this whenever modeling spatial structure on a Minestom server at OneLiteFeather — dungeon floors and rooms, area-based triggers, or interactive doors — instead of hand-rolling bounding-box/region logic. Coris is marked experimental (@ApiStatus.Experimental on its core interfaces) — mention that to the user if API stability matters for their use case.
---

# Coris: floors, rooms, doors, and shapes

Coris models spatial structure — floors containing rooms, rooms with a defined area, doors between them — for
things like dungeons or any area-based game structure. Its core interfaces (`Floor`, `FloorRegistry`, `Room`,
`Shape`) are annotated `@ApiStatus.Experimental`, unlike the other OneLiteFeather libraries covered by this plugin —
expect the API to still move, and flag that to whoever's using it if long-term stability matters for their project.

## Shapes: defining an area

**`Shape`** (`extends Comparable<Shape>, Intersect<Point>`) is the area a room or floor object occupies — `min()`/
`max()` bounds plus `intersect(point)` to test containment. `CuboidShape` is the concrete implementation for a 3D
box:

```java
Shape shape = new CuboidShape(new Vec(0, 60, 0), new Vec(10, 70, 10));
shape.intersect(player.getPosition()); // true if the player is inside the box
```

`CuboidShape` normalizes `start`/`end` into actual min/max internally (so argument order doesn't matter) and
**throws `IllegalArgumentException` if start and end are the same point** (zero-size cuboid) — use `PointShape`
instead when the area really is a single point, don't pass equal coordinates to `CuboidShape` to fake one.

`Intersect<T extends Point>` is its own small interface — implement it directly if a use case needs a custom shape
Coris doesn't provide, rather than working around `CuboidShape`/`PointShape`.

## Rooms and floors

- **`Room`** (`extends Componentable, Comparable<Room>`): `identifier()` (a `Key`) and `shape()`. `BaseRoom` is the
  ready-made implementation — construct it with an identifier and a `Shape`.
- There's no separate "metadata" API on `Room` beyond what its javadoc mentions — the component system *is* the
  metadata store: attach arbitrary per-room data via the `Componentable` methods (see below) rather than looking for
  a dedicated key-value method on `Room` itself. Component data lives only for the room reference's lifetime — if it
  needs to survive a restart, serialize it yourself.
- **`Floor<T>`** (`extends Componentable`, generic over what it holds — typically `Room`) is a container:
  `add(Key, T)`, `remove(Key)`, `identifier()`. `CorisFloor` is the concrete implementation.
- **`FloorRegistry<T extends Floor<Room>>`** tracks floors by key: `add`, `remove`, `clear`, plus lookup. Use
  `CorisFloorRegistry` unless a project needs custom floor-lookup behavior (e.g. sorted by a comparator — the
  registry interface is `Comparator`-aware).
- **`FloorCreateEvent<T>`/`FloorRemoveEvent`** are `CancellableEvent`s carrying the floor. Per `FloorCreateEvent`'s
  own javadoc, it's "only called when the floor has no invalid data" — so a listener doesn't need to re-validate
  the floor, just decide whether to allow it.

## Component system

Rooms, floors, and doors all implement `Componentable` — the same add/has/get/remove-by-class pattern used by Xerus
(see the `xerus` skill for the general shape of it), but **Coris has its own separate `Componentable`/
`CorisComponent` types** in `net.onelitefeather.coris.component` — they are not interchangeable with Xerus's
`Componentable`/`ObjectComponent`, even though the pattern looks identical. Don't mix imports between the two
libraries.

**Example** (the add/has/get flow, taken from Coris' own test suite):

```java
Room room = new BaseRoom(Key.key("room:test"), shape);

assertFalse(room.has(RuleComponent.class));

room.add(RuleComponent.class, new RuleComponent("no-pvp"));

assertTrue(room.has(RuleComponent.class));
CorisComponent component = room.get(RuleComponent.class); // cast to RuleComponent as needed
```

`Floor`/`Door` support the exact same `add`/`has`/`get` calls, since they all come from the same `Componentable`
interface — define one `CorisComponent` implementation per concern (e.g. `RuleComponent`, `LootTableComponent`) and
attach it to whichever room/floor/door instance actually needs it, instead of growing `BaseRoom` subclasses per
combination of features.

## Doors

**`Door`** is sealed (`permits BaseDoor` only) — extend `BaseDoor` for a concrete door, you can't implement `Door`
directly. Core surface: `id()` (`UUID`), `key()`, `face()` (`DoorFace`), `shape()`, plus behavior methods
`open()`, `unlock()`, and `playAnimation(AnimationState)`.

**`BaseDoor` doesn't implement `open()`/`unlock()`/`playAnimation()` for you** — those stay abstract for the
concrete subclass to define (Coris gives you the identity/shape/component bookkeeping, not the actual door
behavior). That also means **firing `DoorOpenEvent`/`DoorCloseEvent` is the concrete door's responsibility**, not
something Coris does automatically — same pattern as Guira's setup events (see the `guira` skill). Both door events
are `InstanceEvent` + `CancellableEvent`; per `DoorOpenEvent`'s javadoc, cancelling it does **not** automatically
stop an in-progress open animation — your `open()` implementation has to check `isCancelled()` and handle that
itself if the animation already started before the event fired.

## Further reference

`references/api-classes.md` has the full class inventory (every class in every package, with verified method
signatures where read) — useful since no strong external consumer of Coris was found, so its own test suite is the
best source of additional examples.

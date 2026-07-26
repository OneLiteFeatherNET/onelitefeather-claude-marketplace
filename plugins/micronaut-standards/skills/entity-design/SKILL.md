---
name: entity-design
description: OneLiteFeather's JPA/Micronaut Data entity conventions for Micronaut REST APIs — entities as a pure persistence layer with no Bean Validation annotations, the internal-UUID-vs-external-identifier pattern, custom AttributeConverters for complex column types, and why entities are plain Java beans rather than records or Lombok classes. Use this whenever adding or reviewing a database/entity/ class in a Micronaut backend. For where entity validation actually lives, see the dto skill; for the optional pattern of publishing entities from a separate Maven module instead of keeping them in the backend, see references/separate-model-module.md in this skill.
---

# Entity design

Entities in `database/entity/` are a pure persistence layer — nothing more. They map to a table, and
that is their entire job. Validation, conversion, and API shape all live elsewhere (see `dto` and
`response-modeling`); an entity that also carries `@NotBlank`/`@Size` annotations or a `toDto()` method
is doing someone else's job.

## No Bean Validation on the entity

```java
// database/entity/FontEntity.java — correct: no @NotBlank, @Size, etc. here
@Entity
@Table(indexes = { @Index(columnList = "uiName") })
public class FontEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    private String uiName;
    private String provider;
    // ...

    public FontEntity() {
    } // required by Hibernate

    public FontEntity(UUID id, String uiName, String provider /*, ... */) {
        this.id = id;
        this.uiName = uiName;
        this.provider = provider;
    }

    // getters and setters
}
```

The DTO (see `dto`) is the single source of truth for validation. Putting `@NotBlank` on both the DTO
field and the entity field means the same rule can drift out of sync between the two — one gets updated,
the other doesn't, and now the entity silently accepts data the DTO would have rejected (or vice versa).
Keep it in exactly one place: the DTO.

## Internal ID vs. external identifier

When an entity represents something that also has an identifier from an external system (a Minecraft
player's Mojang UUID, a third-party API's own ID), keep the entity's own primary key separate from that
external identifier instead of reusing it as the `@Id`:

```java
@Entity
@Table(indexes = {
    @Index(columnList = "playerUuid"),
    @Index(columnList = "playerName")
})
public class PlayerEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;              // internal primary key

    private UUID playerUuid;      // external identifier (Mojang UUID) — indexed, not the PK

    private String playerName;
}
```

This decouples the row's identity from an identifier the application doesn't control — if the external
system's ID scheme ever needs to change or be re-issued, the entity's own primary key and every foreign
key pointing at it are unaffected.

## Custom AttributeConverters for complex columns

For a column type Hibernate doesn't map natively — a `Locale`, a `Map<String, Object>` stored as JSON —
write a JPA `AttributeConverter` rather than serializing it ad hoc in application code:

```java
@Converter
public class LocaleAttributeConverter implements AttributeConverter<Locale, String> {

    @Override
    public String convertToDatabaseColumn(Locale locale) {
        return locale == null ? null : locale.toLanguageTag();
    }

    @Override
    public Locale convertToEntityAttribute(String dbData) {
        if (dbData == null) return Locale.ENGLISH;
        try {
            return Locale.forLanguageTag(dbData);
        } catch (IllformedLocaleException e) {
            return Locale.ENGLISH; // fall back rather than fail the whole entity load
        }
    }
}
```

For a JSON column, combine `@Convert` with `@JdbcTypeCode(SqlTypes.JSON)` (Hibernate 6):

```java
@Convert(converter = MapStringObjectConverter.class)
@JdbcTypeCode(SqlTypes.JSON)
private Map<String, Object> metadata;
```

Apply the converter on the field with `@Convert(converter = LocaleAttributeConverter.class)`, and give
it a sensible fallback value (as above, `Locale.ENGLISH`) rather than throwing and failing the whole
entity load over one malformed value — a `@ColumnDefault` on the column is a reasonable second line of
defense for the same default at the database level.

## Plain Java beans, not records, not Lombok

Entities are classic Java beans: a no-args constructor (required by Hibernate to instantiate the entity
via reflection before populating fields), an all-args constructor for convenience, and plain
getters/setters. No Lombok, no records. Records are reserved for DTOs (see `dto`/`response-modeling`) —
an entity's mutability and Hibernate's reflection-based instantiation are exactly what a record's
immutable, canonical-constructor-only shape is unsuited for.

## Further reference

`references/separate-model-module.md` — the optional pattern of publishing entities from a separately
versioned Maven module instead of keeping them inside the backend, for projects with more than one
consumer of the same data model.

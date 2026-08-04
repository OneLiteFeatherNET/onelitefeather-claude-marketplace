---
name: liquibase
description: OneLiteFeather's mandatory Liquibase database-migration convention for Micronaut REST APIs — always XML changelogs (never YAML/SQL/JSON), the master-changelog-plus-versioned-files structure, and why this replaces Hibernate's hbm2ddl.auto=update. Use this whenever a Micronaut backend needs a schema change, or when reviewing a project still relying on hbm2ddl.auto=update for schema management. For verifying a changelog actually works against both MariaDB and PostgreSQL, see the testcontainers skill.
---

# Liquibase: database migrations

Every schema change to a Micronaut backend's database goes through a Liquibase changelog. Hibernate's
`hbm2ddl.auto=update` is never used for anything beyond a throwaway local prototype — it has no
migration history, no rollback, and silently diverges between environments that started from different
schema versions.

## Always XML, never YAML/SQL/JSON

```xml
<!-- db/changelog/changes/001-create-font-table.xml -->
<databaseChangeLog xmlns="http://www.liquibase.org/xml/ns/dbchangelog"
                    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                    xsi:schemaLocation="http://www.liquibase.org/xml/ns/dbchangelog
                        http://www.liquibase.org/xml/ns/dbchangelog/dbchangelog-4.29.xsd">

    <changeSet id="001-create-font-table" author="theEvilReaper">
        <createTable tableName="font">
            <column name="id" type="uuid">
                <constraints primaryKey="true" nullable="false"/>
            </column>
            <column name="ui_name" type="varchar(255)">
                <constraints nullable="false"/>
            </column>
            <column name="texture_path" type="varchar(1024)">
                <constraints nullable="false"/>
            </column>
        </createTable>
    </changeSet>
</databaseChangeLog>
```

XML is the only accepted changelog format at OneLiteFeather — never YAML, SQL, or JSON changelogs, even
though Liquibase supports all four. Liquibase's abstract change types (`createTable`, `addColumn`,
`addForeignKeyConstraint`, and so on) are the most consistently dialect-neutral in XML: the same
changelog runs unchanged against both MariaDB and PostgreSQL, because Liquibase itself translates each
abstract change type into the right SQL dialect at execution time. Raw SQL changelogs make that
translation the author's job instead, per statement, per dialect.

## When an abstract change type doesn't exist

Reach for `<sql>` only when no abstract change type covers what's needed, and scope it to the specific
dialect it's needed for using the `dbms` attribute — never a bare `<sql>` block assumed to work
everywhere:

```xml
<changeSet id="002-add-generated-column" author="theEvilReaper">
    <sql dbms="postgresql">
        ALTER TABLE font ADD COLUMN search_vector tsvector GENERATED ALWAYS AS (to_tsvector('english', ui_name)) STORED;
    </sql>
    <sql dbms="mariadb">
        ALTER TABLE font ADD COLUMN search_vector TEXT GENERATED ALWAYS AS (ui_name) VIRTUAL;
    </sql>
</changeSet>
```

## Structure: master changelog + versioned files

```
db/changelog/
├── db.changelog-master.xml
└── changes/
    ├── 001-create-font-table.xml
    └── 002-add-generated-column.xml
```

```xml
<!-- db/changelog/db.changelog-master.xml -->
<databaseChangeLog xmlns="http://www.liquibase.org/xml/ns/dbchangelog" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                    xsi:schemaLocation="http://www.liquibase.org/xml/ns/dbchangelog http://www.liquibase.org/xml/ns/dbchangelog/dbchangelog-4.29.xsd">
    <include file="changes/001-create-font-table.xml" relativeToChangelogFile="true"/>
    <include file="changes/002-add-generated-column.xml" relativeToChangelogFile="true"/>
</databaseChangeLog>
```

One `changeSet` per functional change, with `id` and `author` set on every one — both are mandatory,
since Liquibase uses the `(id, author, filename)` triple to track which changesets have already run
against a given database.

## Micronaut integration

```kotlin
dependencies {
    implementation(mn.micronaut.liquibase)
}
```

```yaml
# application.yml
liquibase:
  datasources:
    default:
      change-log: classpath:db/changelog/db.changelog-master.xml
```

Micronaut runs pending changesets against the configured datasource at application startup, before the
rest of the application context finishes initializing.

## Rollback

Add `<rollback>` elements (or rely on Liquibase's automatic rollback for change types simple enough to
auto-generate one, like `createTable`) rather than treating every migration as forward-only and
untested:

```xml
<changeSet id="002-add-generated-column" author="theEvilReaper">
    <sql dbms="postgresql">ALTER TABLE font ADD COLUMN search_vector tsvector;</sql>
    <rollback>
        <sql dbms="postgresql">ALTER TABLE font DROP COLUMN search_vector;</sql>
    </rollback>
</changeSet>
```

`<preConditions>` (e.g. `columnExists`/`tableExists` checks) are the other tool for making a changeset
safe to re-run or safe against a database that's already partway migrated by hand.

## Cross-DB verification

Whether a changelog genuinely works against both MariaDB and PostgreSQL is verified by actually running
it against both in tests, not by inspection — see the `testcontainers` skill for the container setup
that does this.

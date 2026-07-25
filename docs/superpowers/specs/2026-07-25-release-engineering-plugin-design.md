# Plugin `release-engineering` — Design

## Zweck

Ein neues Claude-Code-Plugin, das den OneLiteFeather-CI/CD-Standard lehrt: Release Please, Renovate
und die reusable GitHub-Actions-Workflows (inkl. Docker-Publishing und Gradle-Besonderheiten). Analog
zu `minestom-knowledge` ist es reines Skill-Wissen — keine MCP-Server, keine externen Abhängigkeiten.

Quellen: die Outline-Doku ("Engineering-Standards — Start hier" + das Diátaxis-Set "Reusable GitHub
Actions Workflows"), der echte Code in `workflows` und `renovate` (OneLiteFeatherNET), Gold-Master-Repos
(**Cygnus** ohne Docker, **Otis** mit Docker, **Guira** als frischer Migrations-Pilot-PR #70), sowie
aktuelle Renovate-Upstream-Doku (docs.renovatebot.com, gegengecheckt gegen Terminologie-Änderungen wie
`regexManagers` → `customManagers`, `fileMatch` → `managerFilePatterns`).

## Scope-Entscheidungen (im Brainstorming getroffen)

- Nur die vier angefragten Themenblöcke: Release Please, Renovate, reusable Workflows (mit/ohne
  Docker), Gradle-Besonderheiten. Keine Community-Health-Dateien-Vorlage (README/CONTRIBUTING/
  CODEOWNERS) — bewusst außerhalb des Scopes.
- Keine Org-weiten Migrations-Tracking-Listen (`RELEASE-PLEASE-TRACKING.md` etc.) im Skill — das ist
  transienter Zustand einer laufenden Migration, kein wiederverwendbares Skill-Wissen.
- Drei eigenständige Skills statt einem, damit z. B. eine reine Renovate-Frage nicht das gesamte
  Release-Please-Wissen mitlädt (jede `SKILL.md` hat ihr eigenes `description`-Frontmatter fürs
  Trigger-Matching).
- **Release Please:** Versionsmarker-Standard ist ausschließlich ein Kommentar direkt in der
  Root-`build.gradle.kts` (`version = "1.2.3" // x-release-please-version`), gelesen über den
  eingebauten `generic`-extra-files-Updater von release-please. Explizit **kein**
  `gradle.properties`-Parsing per Shell-Skript (wie aktuell teils in Publish-Workflows zu finden,
  z. B. `grep '^version' gradle.properties | cut -d= -f2`) und **kein** selbstgebauter
  Kotlin-`replace`-Task/`Copy`+`ReplaceTokens` zur Versionssynchronisation. Der Skill deckt sowohl
  Setup (neues Repo) als auch Migration (bestehendes Repo weg von `@semantic-release`/
  `release-drafter`/tag-getriggertem Publish) als vollständige, getrennte Abschnitte ab, jeweils für
  Single-Module- und Multi-Module-Gradle-Projekte (Multi-Module: eigene Version pro Subprojekt über
  mehrere `packages`-Einträge in `release-please-config.json`).
- **Renovate:** nicht nur "zentrales Preset einbinden", sondern allgemeine Hilfe bei
  Renovate-Configs — eine breite, generische Referenz zu Renovate-Config-Optionen (nicht nur
  aktuell bei OLF gelebte Muster), plus manager-spezifische Abschnitte für **alle** Ecosysteme, die
  in der Org tatsächlich vorkommen (Gradle, Docker, GitHub Actions, npm/Node, Ansible, Python,
  Dart/pub) — nicht nur den Gradle/Docker/Actions-Kernstack.

## Struktur

```
plugins/release-engineering/
├── .claude-plugin/plugin.json
├── .codex-plugin/plugin.json
├── .antigravity-plugin/plugin.json
└── skills/
    ├── release-please/
    │   ├── SKILL.md
    │   └── references/
    │       └── multi-module.md
    ├── renovate/
    │   ├── SKILL.md
    │   └── references/
    │       ├── cookbook.md
    │       └── managers.md
    └── workflows/
        ├── SKILL.md
        └── references/
            ├── inputs-reference.md
            ├── docker.md
            └── design-principles.md
```

Zusätzlich: Eintrag `release-engineering` in `.claude-plugin/marketplace.json` (Format analog zu den
drei bestehenden Plugin-Einträgen) und eine Zeile in der Plugin-Tabelle der Root-`README.md`.

## Skill: `release-please`

**SKILL.md** (Hauptinhalt, generisch mit Platzhaltern statt echten Repo-Namen):

- Kurzüberblick: Conventional Commits → automatischer Changelog → Tag → Release → verketteter Publish.
  Löst `@semantic-release` und manuelles Taggen ab.
- **Versionsmarker-Konvention** als eigener, prominenter Abschnitt: `build.gradle.kts` statt
  `gradle.properties`, mit Begründung (kein Parse-/Replace-Code nötig, Gradle liest `project.version`
  nativ). Anti-Pattern-Kasten: kein `grep`/`cut`-Parsing, kein Kotlin-`replace`-Task.
- `## Setup` — neues, leeres Repo: `release-please-config.json` (`release-type: simple`,
  `extra-files: [{"type": "generic", "path": "build.gradle.kts"}]`), `.release-please-manifest.json`,
  `.github/workflows/release-please.yml` (`googleapis/release-please-action@v5`, verkettet mit
  `gradle-publish.yml` über `needs.release-please.outputs.release_created`).
- `## Migration` — bestehendes Repo: Erkennungsmerkmale von Alt-Tooling (`.releaserc*`,
  `release-drafter.yml`, tag-getriggerte `publish.yaml`), Entfernen inkl. etwaiger
  Parse-/Replace-Skripte, `bootstrap-sha` aus der Historie bestimmen, Versionsmarker von
  `gradle.properties` (falls vorhanden) nach `build.gradle.kts` überführen, Manifest auf aktuelle
  Version setzen.
- Beide Abschnitte behandeln Single-Module explizit; Multi-Module wird kurz angerissen und auf die
  Reference verlinkt.

**references/multi-module.md**: generisches Multi-Module-Gradle-Beispiel (Platzhalter-Modulnamen) —
mehrere Einträge im `packages`-Objekt (ein Pfad pro Subprojekt), je eigener Versionsmarker in dessen
`build.gradle.kts`, je eigener Eintrag in `.release-please-manifest.json`. Erklärt, dass ein Commit,
der nur Dateien unter einem Modul-Pfad ändert, nur die Version dieses Moduls bumpt.

## Skill: `renovate`

**SKILL.md**:

- Was Renovate bei OLF leistet, Abgrenzung zu Dependabot (kurz, aus der Explanation-Doc: bessere
  Gruppierung/Automerge für reusable-workflow-Refs).
- Org-Standard-Setup: zentrales Preset
  `github>OneLiteFeatherNET/renovate:default(OneLiteFeatherNET/<team>-maintainers)`, Team-Argument
  ist Pflicht (setzt Reviewer), Flavors `:paper` / `:minestom` als zweiter `extends`-Eintrag.
- Was das Default-Preset mitbringt (Automerge Patch, Office-Hours-Schedule Europe/Berlin, Semantic
  Commits, Label `renovate`, Vulnerability-Alerts).
- Migration weg von nicht-kanonischen Alt-Configs (lowercase-Preset ohne `:default`, `config:base`
  direkt, `config:recommended` direkt ohne Org-Preset).
- Separater Abschnitt: Renovate für die Pipeline-Pins selbst (`github-actions`-Manager bumpt
  `OneLiteFeatherNET/workflows/...@vX.Y.Z` automatisch).
- Verweis auf die zwei References für alles, was über den Org-Standard hinausgeht.

**references/cookbook.md** (breite generische Referenz, nicht auf aktuelle OLF-Nutzung beschränkt):

- Scheduling (`schedule`, `automergeSchedule`, `prHourlyLimit`/`prConcurrentLimit`).
- `packageRules`-Matching (`matchManagers`, `matchPackageNames`, `matchUpdateTypes`, `matchDatasources`),
  `ignoreDeps`/`ignorePaths`.
- Grouping (`groupName`, `groupSlug`, `minimumGroupSize`).
- Automerge (`automerge`, `automergeType`, `platformAutomerge`) inkl. Differenzierung nach
  Update-Typ (minor/patch/digest automerge, major nie).
- `customManagers` (aktueller Name, vormals `regexManagers`) mit `customType: "regex"`,
  `managerFilePatterns` (vormals `fileMatch`), `matchStrings` — für Dateien, die kein nativer Manager
  abdeckt.
- `lockFileMaintenance`, Dependency Dashboard, `vulnerabilityAlerts`/`osvVulnerabilityAlerts`.
- `config:recommended` vs. `config:best-practices` (was Letzteres zusätzlich bringt: Digest-Pinning,
  Abandonment-Handling, wöchentliche Lockfile-Maintenance) als bewusste Erweiterungsoption.
- Kasten "veraltete Syntax aus Blogposts/älteren Beispielen": `regexManagers` → `customManagers`,
  `fileMatch` → `managerFilePatterns`, `baseBranches` → `baseBranchPatterns`.
- Config-Validierung: `npx --package renovate -- renovate-config-validator`.

**references/managers.md** (pro Ecosystem, alle in der Org vorkommenden Stacks):

- Gradle (`gradle`, `gradle-wrapper`) — was automatisch erkannt wird, Zusammenspiel mit den
  `:paper`/`:minestom`-Versionierungs-Flavors aus dem `renovate`-Repo.
- Docker (`dockerfile`, `docker-compose`).
- GitHub Actions (`github-actions`) — Pin-Format `uses: .../foo.yml@vX.Y.Z`, Zusammenspiel mit der
  Pin-Strategie aus dem `workflows`-Skill.
- npm/Node (`npm`).
- Ansible (`ansible`, `ansible-galaxy`) — relevant für `infra-ansible-roles`, `infra-dns`,
  `Kubernetes-FLUX`.
- Python (`pip_requirements`, `poetry`, `pep621`, ...) — relevant für `Dungeon-Python`, `ProtoScript`.
- Dart/pub (`pub`, `fvm`) — relevant für `stelaris`, `vulpes-*-dart`.
- Wann auf `customManagers`/regex zurückfallen (Datei/Format, das kein nativer Manager kennt).

## Skill: `workflows`

**SKILL.md**:

- Katalog aller reusable Workflows (`gradle-build-pr`, `gradle-publish`, `gradle-docker-context`,
  `docker-publish`, `release-please`, `close-invalid-prs`, `markdown-lint`) mit einem Satz Zweck pro
  Workflow.
- Pin-Strategie: voller SemVer-Tag (`@v2.4.0`), bewusst kein `@v2`-Major-Alias — Renovate hält den
  Pin aktuell (Verweis auf `renovate`-Skill, Abschnitt "Pipeline-Pins").
- Docker-Entscheidung als eigener Abschnitt: plain `Dockerfile` im Repo → `docker-publish.yml`
  direkt mit `context`/`dockerfile`; Gradle/Micronaut-generierter Context (`optimizedDockerfile`) →
  erst `gradle-docker-context.yml` (produziert Artifact), dann `docker-publish.yml` mit demselben
  `artifact-name` konsumiert. Kurzfassung, Details in `references/docker.md`.
- Gradle-Besonderheiten: Java 25 (Temurin) als Default, 3-OS-Matrix auf PRs vs. Single-OS beim
  Publish, Path-Filter-Schlüssel `code`, `run-tests: false` für BOM-/testlose Projekte (senkt
  Default-Task auf `build`), kein `clean` im Default-Task (Cache-Killer), Cache ist read-only auf
  Nicht-Default-Branches.
- **Neuer Abschnitt "Neue Mechanik einführen?":** Kurzer Entscheidungsbaum für Fälle, die der
  bestehende Katalog nicht direkt abdeckt — bestehenden Workflow per zusätzlichem Input erweitern
  vs. neuen reusable Workflow im `workflows`-Repo anlegen vs. einen Custom-Job im Caller-Repo lassen
  (z. B. einmalige/repo-spezifische Logik, die sich nicht verallgemeinern lässt). Verweist für die
  Detailanleitung und das "Warum" auf `references/design-principles.md`.

**references/inputs-reference.md**: vollständige Input-/Default-/Secret-Tabellen pro Workflow
(gespiegelt aus dem tatsächlichen `workflow_call`-Schema im `workflows`-Repo, nicht nur aus der
Outline-Doku übernommen — beide wurden gegengecheckt).

**references/docker.md**: Otis-Muster im Detail (`gradle-docker-context.yml` →
`docker-publish.yml`-Handoff, Snapshot- vs. Release-Build als zwei parallele Jobpaare,
`workflow_dispatch` mit `docker_version`-Input für manuelles Re-Publish), plain-Dockerfile-Muster
ohne Gradle-Kopplung, Chunked-Upload-Hintergrund (Harbor hinter Cloudflare, 100-MB-Proxy-Limit,
`regctl --blob-chunk`) und keyless Cosign-Signing (`id-token: write`, kein Signing-Secret).

**references/design-principles.md** (neu): das "Warum" hinter den bestehenden Defaults, aus der
Outline-Seite "Explanation: Design-Entscheidungen" übernommen und gegen den echten Workflow-Code
verifiziert — Matrix auf PRs vs. Single-OS beim Publish, `cancel-in-progress: true` auf PRs vs.
`false` beim Publish, Grund für den Path-Filter, kein `clean` im Default-Task, Cache read-only auf
Nicht-Default-Branches, Java-25-Wahl, warum release-please statt `@semantic-release`, warum Renovate
statt Dependabot für die Pipeline-Pins. Diese Prinzipien werden als übertragbarer Rahmen formuliert,
damit eine neue Mechanik (neuer Ecosystem-Typ, neues Deployment-Ziel, neuer Artefakt-Typ) konsistent
dazu entworfen werden kann — plus eine konkrete Anleitung, wie ein neuer reusable Workflow im
`workflows`-Repo eingereicht wird (`workflow_call`-Schema-Konventionen, `secrets: inherit`,
Conventional-Commit-PR, eigene Versionierung des `workflows`-Repos via release-please, volles
SemVer-Pin für Konsumenten statt `@main`/Major-Alias).

## Nicht im Scope

- Community-Health-Dateien-Vorlage (README/CONTRIBUTING/CODEOWNERS) — eigenes, späteres Thema.
- Org-weite Migrations-Tracking-Listen — transienter Zustand, gehört nicht in ein Skill.
- SBOM-Einbindung (`cyclonedxBom` + DependencyTrack-Upload, wie in Cygnus zu sehen) — eigenes Thema,
  nicht Teil dieser Anfrage.

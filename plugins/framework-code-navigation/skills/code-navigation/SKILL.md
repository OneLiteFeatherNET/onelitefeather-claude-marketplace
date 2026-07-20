---
name: code-navigation
description: Token-saving routing policy for JVM (Java/Kotlin) projects — when searching, locating, navigating, or refactoring code in a project that looks JVM-based, use Serena's symbol tools instead of grep/find/read. Applies whenever finding definitions, callers, references, types, or doing project-wide code search or symbol-based edits. Only relevant on projects with Java/Kotlin sources (pom.xml, build.gradle, build.gradle.kts, or .java/.kt files) and a reachable Serena MCP server — on any other project, this skill intentionally has nothing to say and you should proceed with normal tools.
---

# Code navigation: symbols instead of grep (JVM projects only)

Goal: cut API calls and tokens by navigating code through the language server
(Serena) instead of text search and file dumps — but **only on projects where
that's actually possible**. This plugin is installed by choice, by people who
work on JVM codebases; it must never get in the way of anyone working on a
project Serena doesn't cover.

## Before anything else: does this project qualify?

Check both of the following before relying on Serena for a task. This check
is cheap (a couple of tool calls) and only needs to happen once per session,
not before every single lookup:

1. **Does the project look JVM-based?** Look for `pom.xml`, `build.gradle`,
   `build.gradle.kts`, or `.java`/`.kt` source files near the working
   directory.
2. **Does Serena actually respond?** Try a lightweight Serena call (e.g.
   `get_symbols_overview` on a file, or check whether `mcp__serena__*` tools
   are listed at all). A missing MCP connection, a language server that
   hasn't indexed the project yet, or a non-JVM project are all valid reasons
   this fails.

If either check fails, this skill does not apply — proceed with grep/find/read
as you normally would, without commenting on Serena or apologizing for not
using it. Don't retry repeatedly or trouble the user with connection details;
a silent, unremarkable fallback is the correct behavior. Only mention Serena
at all if the user asks about it directly or if you were clearly expected to
use it (e.g. the user explicitly asked for symbol-based navigation).

## Once both checks pass: rules (in this order)

1. **Find a definition** → `mcp__serena__find_symbol` (NOT `grep "class X"` + read the file).
2. **Callers / references** → `mcp__serena__find_referencing_symbols`
   (NOT `grep -r "foo("` across the repo).
3. **Understand file/package structure** → `mcp__serena__get_symbols_overview`
   (NOT dumping the whole file with `read`).
4. **Edit** symbol-based (`replace_symbol_body`, `insert_after_symbol`), so only
   the relevant slice enters the context.
5. **Raw grep/find/read only as a last resort** — e.g. config keys, strings, or
   non-code files the language server doesn't know about.

## Why

grep returns lots of noise (comments, same-named symbols, strings); the agent
then reads several files to find the right one — those are the expensive extra
calls. The language server knows definitions and references exactly and resolves
into dependencies (including the JavaDoc attached to a symbol).

## JVM note

For Java/Kotlin, Serena wires up the matching language server. If the `-sources`
jars of the dependencies are present, the symbol lookup also surfaces the JavaDoc
of third-party libraries — on demand, without dumping documentation.

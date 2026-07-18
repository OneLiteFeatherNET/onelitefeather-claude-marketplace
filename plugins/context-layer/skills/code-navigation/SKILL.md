---
name: code-navigation
description: Token-saving routing policy — when searching, locating, navigating or refactoring code, ALWAYS use the Serena symbol tools instead of grep/find/read. Activates whenever finding definitions, callers, references, types, or doing project-wide code search.
when_to_use: Whenever locating code, finding a definition, finding callers/references of a symbol, understanding how a subsystem works, or planning a cross-file refactor.
---

# Code navigation: symbols instead of grep

Goal: cut API calls and tokens by navigating code through the language server
(Serena) instead of text search and file dumps.

## Rules (in this order)

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

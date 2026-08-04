#!/usr/bin/env bash
# guard.sh - PreToolUse safety net for git-hygiene.
#
# Invoked by hooks/hooks.json for every Bash tool call whose command line matches
# the `if` pre-filter (git commit/merge/push/tag, gh pr create/edit,
# gh release create/edit). Reads the hook payload as JSON on stdin:
#   {"tool_input": {"command": "git commit -m \"...\""}}
#
# Contract (references/enforcement.md section 1 is the single source of truth):
#   - To DENY (block the tool call): exit 0 and print exactly one line of JSON:
#       {"hookSpecificOutput":{"hookEventName":"PreToolUse",
#        "permissionDecision":"deny","permissionDecisionReason":"..."}}
#   - Anything else (exit 0 with no such JSON, or exit 1) is non-blocking: the
#     tool call proceeds. Exit 1 is NOT how you block -- see enforcement.md.
#   - This script never exits 1 on a detected violation. It either denies (exit 0
#     + JSON above) or allows, optionally printing a plain-text warning that is
#     merely shown in the transcript.
#
# What is denied: the four deterministic attribution patterns, detected by
# delegating to strip-attribution.sh --check (references/attribution.md
# "Detection patterns"). Zero documented false-positive risk, so hard-blocking
# is justified.
#
# What only warns (allow + message): typography (detypo.pl --check) and
# `--no-verify`/`-n` usage scoped to `git commit|merge|push|tag` (never to `gh`,
# where `-n` means `--notes` -- see enforcement.md section 5). Phrasing
# ("ai-tells.md") is deliberately never automated -- see that file's own note
# that no script touches it -- so this guard does not attempt it.
#
# Extraction: git/gh commands carry the text to check as command-line argument
# values (-m/--message, -b/--body, -t/--title, -n/--notes) or, for -F/--file/
# --body-file/--notes-file, as the contents of the file the argument names (the
# "-F blind spot" in enforcement.md section 4). Command-line tokenizing uses
# Perl's core Text::ParseWords::shellwords, which performs shell-style quote
# removal WITHOUT evaluating `$(...)`/backticks/variables -- safe against a
# message body that happens to contain shell metacharacters.

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
strip_attribution="${script_dir}/strip-attribution.sh"
detypo="${script_dir}/detypo.pl"

deny() {
  # $1: permissionDecisionReason text.
  jq -n --arg reason "$1" \
    '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $reason}}'
  exit 0
}

# Fail open (allow) if a required interpreter is missing -- a broken dependency
# must never turn every git commit/gh call into a silent permanent block, and
# without jq we cannot emit the deny JSON shape at all.
if ! command -v jq >/dev/null 2>&1 || ! command -v perl >/dev/null 2>&1; then
  echo "git-hygiene guard.sh: jq and/or perl not found on PATH; skipping checks for this call." >&2
  exit 0
fi

raw_input="$(cat)"

command_line="$(printf '%s' "$raw_input" | jq -r '.tool_input.command // empty' 2>/dev/null || true)"

if [ -z "$command_line" ]; then
  exit 0
fi

# Tokenize with shell-style quote/backslash removal, NUL-separated so bash can
# rebuild an array safely regardless of embedded whitespace/newlines. This does
# NOT execute $(...) / `...` / variable expansion -- it only strips quoting.
mapfile -d '' -t words < <(
  printf '%s' "$command_line" | perl -MText::ParseWords -e '
    local $/;
    my $cmd = <STDIN>;
    print join("\0", shellwords($cmd));
  ' 2>/dev/null || true
)

if [ "${#words[@]}" -eq 0 ]; then
  exit 0
fi

read_file_or_literal() {
  # $1: a path argument to -F/--file/--body-file/--notes-file. Print the
  # file's contents if it exists and is readable, else print the literal
  # argument back (harmless fallback -- it is scanned as ordinary text).
  local val="$1"
  if [ -n "$val" ] && [ -r "$val" ]; then
    cat -- "$val"
  else
    printf '%s' "$val"
  fi
}

# Split the token stream into per-invocation segments at unquoted shell
# metacharacter tokens (&&, ||, ;, |). shellwords already merged every quoted
# argument (including a multi-line commit message) into a single token, so a
# token that is exactly one of these four strings can only be a real operator,
# never contamination from inside a quoted message.
#
# Each segment is scanned independently, below. This replaces an earlier
# version that found only the RIGHTMOST git/gh token in the whole command
# line and scanned from there to the end -- which silently missed every
# invocation before the last one. `git commit -m "<contaminated>" && git push`
# has its `-m` value in the FIRST segment; scanning only from the last git/gh
# token onward (i.e. from `git push` onward) never reads it, so the deny
# check never ran. Per-segment scanning closes that bypass and, as a side
# effect, also stops a later unrelated segment (e.g. `echo -n done`) from
# being misread as `--no-verify` on an earlier, unrelated git invocation.
op_indices=()
for idx in "${!words[@]}"; do
  case "${words[$idx]}" in
    '&&' | '||' | ';' | '|') op_indices+=("$idx") ;;
  esac
done
boundaries=("${op_indices[@]}" "${#words[@]}")

warnings=()
seg_start=0

for boundary in "${boundaries[@]}"; do
  seg_end=$((boundary - 1))

  if [ "$seg_start" -gt "$seg_end" ]; then
    seg_start=$((boundary + 1))
    continue
  fi

  # Find the first `git` or `gh` token within THIS segment only (e.g. skips
  # a leading env-var assignment like `GIT_AUTHOR_NAME=x git commit ...`).
  base_idx=-1
  for ((idx = seg_start; idx <= seg_end; idx++)); do
    case "${words[$idx]}" in
      git | gh)
        base_idx="$idx"
        break
        ;;
    esac
  done

  if [ "$base_idx" -lt 0 ]; then
    seg_start=$((boundary + 1))
    continue
  fi

  base="${words[$base_idx]}"
  subcommand="${words[$((base_idx + 1))]:-}"
  messages=()
  no_verify_seen=0

  case "$base" in
    git)
      i=$((base_idx + 2))
      while [ "$i" -le "$seg_end" ]; do
        tok="${words[$i]}"
        case "$tok" in
          -m | --message)
            i=$((i + 1))
            messages+=("${words[$i]:-}")
            ;;
          -F | --file)
            i=$((i + 1))
            messages+=("$(read_file_or_literal "${words[$i]:-}")")
            ;;
          --no-verify)
            no_verify_seen=1
            ;;
          -n)
            # Only a --no-verify synonym on commit/merge/push/tag (enforcement.md
            # section 5); on other git subcommands -n has other meanings, so this
            # branch is only reached when subcommand is one of those four anyway
            # because that is what hooks.json's `if` pre-filter already scoped us
            # to -- still gate explicitly for defense in depth.
            case "$subcommand" in
              commit | merge | push | tag) no_verify_seen=1 ;;
            esac
            ;;
        esac
        i=$((i + 1))
      done
      ;;
    gh)
      i=$((base_idx + 2))
      while [ "$i" -le "$seg_end" ]; do
        tok="${words[$i]}"
        case "$tok" in
          -t | --title | -b | --body | -n | --notes)
            i=$((i + 1))
            messages+=("${words[$i]:-}")
            ;;
          -F | --body-file | --notes-file)
            i=$((i + 1))
            messages+=("$(read_file_or_literal "${words[$i]:-}")")
            ;;
        esac
        i=$((i + 1))
      done
      ;;
  esac

  combined=""
  if [ "${#messages[@]}" -gt 0 ]; then
    for m in "${messages[@]}"; do
      combined="${combined}${m}"$'\n'
    done
  fi

  # --- Deny check: the four deterministic attribution patterns. Any single
  # contaminated invocation anywhere in the chain denies the whole call. ---
  if [ -n "$combined" ]; then
    if ! printf '%s' "$combined" | "$strip_attribution" --check >/dev/null 2>&1; then
      deny "Commit/PR message contains an AI tool attribution trailer (Co-Authored-By bot address, a <Tool>-Session: trailer, the 'Generated with [...]' footer, or a bare harness session URL). Remove it before proceeding -- see references/attribution.md."
    fi
  fi

  # --- Warn-only checks for this invocation. Never deny here. ---
  if [ -n "$combined" ]; then
    if ! printf '%s' "$combined" | perl "$detypo" --check >/dev/null 2>&1; then
      warnings+=("git-hygiene: possible machine typography (em dash, curly quotes, or similar) detected in the message text of 'git ${subcommand}'. Not blocked -- the false-positive rate is too high to enforce -- but worth a look before you proceed. See references/typography.md.")
    fi
  fi

  if [ "$base" = "git" ] && [ "$no_verify_seen" -eq 1 ]; then
    warnings+=("git-hygiene: this command bypasses git's own commit-msg hook (--no-verify/-n) on 'git ${subcommand}'. If the opt-in commit-msg hygiene check is installed in this clone, it will not run for this call -- double-check the message manually.")
  fi

  seg_start=$((boundary + 1))
done

if [ "${#warnings[@]}" -gt 0 ]; then
  printf '%s\n' "${warnings[@]}"
fi

exit 0

#!/usr/bin/env bash
# strip-attribution.sh - Remove AI coding-harness attribution trailers from a
# commit/PR message, while leaving every other line - including human
# co-author trailers and legitimate product-name mentions - untouched.
#
# Usage:
#   strip-attribution.sh [--check] [FILE]
#
# Reads the message on stdin, or from FILE if given.
#
# Default (rewrite) mode: writes the cleaned message to stdout. Exit 0.
# --check (detection) mode: writes nothing; exit 1 if any attribution line
#   was found (the message is not clean), exit 0 if the message is already
#   clean.
#
# What gets removed (case-insensitively), and nothing else:
#   1. A "Co-Authored-By:" trailer whose address structurally identifies a
#      machine/service account rather than a specific human:
#        - a bare "noreply@"/"no-reply@" local-part (e.g. noreply@anthropic.com,
#          noreply@openai.com). This is deliberately generic and not tied to
#          one vendor: it is what harness-generated trailers use. It does NOT
#          match GitHub's human privacy-email format
#          ("<id>+<username>@users.noreply.github.com"), which always carries
#          a per-user identifier in the local part.
#        - a GitHub App "[bot]" account address (e.g. some-tool[bot]@users.noreply.github.com).
#   2. A line starting with "<Word>-Session:" (Claude-Session:, Codex-Session:,
#      Cursor-Session:, ...) - a harness session trailer.
#   3. The "Generated with [...]" footer line marked with the robot emoji.
#   4. A bare harness session URL on its own line (a URL whose path contains
#      a "/session..." segment, with nothing else on the line).
#
# Everything else survives untouched: Signed-off-by, BREAKING CHANGE,
# Refs/Fixes/Closes, Release-As, human Co-authored-by trailers, and any body
# text that merely mentions a tool/product name such as "Claude Code".

set -euo pipefail

usage() {
  cat <<'USAGE' >&2
Usage: strip-attribution.sh [--check] [FILE]

Reads a commit/PR message on stdin (or from FILE) and removes AI coding-
harness attribution trailers: bot co-author addresses, session trailers,
the "Generated with" footer, and bare harness session URLs.

Default: writes the cleaned message to stdout. Exit 0.
--check: writes nothing to stdout; exit 1 if attribution was found, exit 0
         if the message is already clean.
USAGE
}

check_mode=0
input_file=""

while [ $# -gt 0 ]; do
  case "$1" in
    --check)
      check_mode=1
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    --)
      shift
      if [ $# -gt 0 ]; then
        input_file="$1"
        shift
      fi
      break
      ;;
    -*)
      echo "strip-attribution.sh: unknown option: $1" >&2
      usage
      exit 2
      ;;
    *)
      input_file="$1"
      shift
      ;;
  esac
done

if [ -n "$input_file" ]; then
  input="$(cat -- "$input_file")"
else
  input="$(cat)"
fi

# 1. Co-Authored-By trailer with a structurally bot-shaped address.
#    - noreply/no-reply must be the ENTIRE local-part (anchored right after
#      "<", no arbitrary prefix allowed), so "jane.noreply@example.com" does
#      NOT match - only a bare "noreply@..."/"no-reply@..." does.
#    - "[bot]@" is a suffix marker and may have an arbitrary prefix before
#      it (GitHub App accounts are "<id>+<name>[bot]@users.noreply.github.com"),
#      so that shape intentionally keeps the "[^>]*" prefix.
bot_coauthor_re='^[[:space:]]*co-authored-by:.*<(no-?reply@[a-z0-9.-]+|[^>]*\[bot\]@[a-z0-9.-]+)>[[:space:]]*$'

# 2. Session trailer: "<Word>-Session:" (Claude-Session:, Codex-Session:, ...)
session_trailer_re='^[[:space:]]*[a-z][a-z0-9]*-session:'

# 3. "Generated with [...]" footer line (requires the robot-emoji marker too).
generated_footer_re='generated with \['

# 4. Bare harness session URL on its own line.
session_url_re='^[[:space:]]*https?://[^[:space:]]*/session[_/-][a-z0-9_-]+[[:space:]]*$'

found=0
output=""

strip_line() {
  local line="$1" lc
  lc="$(printf '%s' "$line" | tr '[:upper:]' '[:lower:]')"

  if printf '%s\n' "$lc" | grep -Eq "$bot_coauthor_re"; then
    return 0
  fi
  if printf '%s\n' "$lc" | grep -Eq "$session_trailer_re"; then
    return 0
  fi
  if printf '%s\n' "$line" | grep -q '🤖' && printf '%s\n' "$lc" | grep -Eq "$generated_footer_re"; then
    return 0
  fi
  if printf '%s\n' "$lc" | grep -Eq "$session_url_re"; then
    return 0
  fi
  return 1
}

if [ -n "$input" ]; then
  while IFS= read -r line || [ -n "$line" ]; do
    if strip_line "$line"; then
      found=1
      continue
    fi
    output="${output}${line}"$'\n'
  done <<EOF_MSG
$input
EOF_MSG
fi

if [ "$check_mode" -eq 1 ]; then
  if [ "$found" -eq 1 ]; then
    exit 1
  fi
  exit 0
fi

printf '%s' "$output"

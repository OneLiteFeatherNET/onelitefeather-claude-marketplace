#!/usr/bin/env bash
# guard.sh - PreToolUse safety net for git-hygiene.
#
# Invoked by hooks/hooks.json for every Bash tool call whose command line matches
# the `if` pre-filter (git commit/merge/push/tag, gh pr create/edit/comment/
# review/merge, gh issue create/comment, gh release create/edit). Reads the hook
# payload as JSON on stdin:
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
# values (-m/--message/--trailer, -b/--body, -t/--title/--subject, -n/--notes)
# or, for -F/--file/--body-file/--notes-file, as the contents of the file the
# argument names (the "-F blind spot" in enforcement.md section 4). Command-line
# tokenizing uses Perl's core Text::ParseWords::shellwords, which performs
# shell-style quote removal WITHOUT evaluating `$(...)`/backticks/variables --
# safe against a message body that happens to contain shell metacharacters.
#
# ============================================================================
# DESIGN: one single-pass, value-aware walker (read this before editing)
# ============================================================================
#
# Three earlier rounds of fixes each closed one bypass and left a sibling of the
# SAME defect at a different layer. The defect class is always this:
#
#     a token that is already CLAIMED as some flag's value gets re-interpreted
#     as command-line SYNTAX by a pass that did not know about the claim.
#
# Concrete historical instances, in the order they were found:
#   1. dispatch loop      -- `-am` / `--name=value` spellings not recognized, so
#                            the value never reached the scanner at all.
#   2. normalization pass -- the fix for (1) pre-expanded the WHOLE argv, so an
#                            ordinary message starting with `-` was shredded into
#                            synthetic flags (and `-m "-xF/etc/passwd"` even
#                            synthesized a `-F` the dispatcher then obeyed).
#   3. `=`-splitting      -- an UNRECOGNIZED `--name=value` still leaked `value`
#                            back into dispatch, where `--label=-b` swallowed the
#                            real following `-b`'s value.
#   4. segment pre-pass   -- chain-operator detection ran as a separate pre-pass
#                            over raw tokens BEFORE any value consumption was
#                            known, so `-m "|"` (a message whose text is exactly
#                            a shell operator) was misread as a real operator and
#                            silently truncated the scan.
#
# The rewrite removes the possibility of a fifth instance by removing the
# separate passes. There is now exactly ONE left-to-right walk over the raw
# token stream, carrying all state (current segment's base command, subcommand,
# option tables, and -- crucially -- `pending`, the class of value the previous
# token is still waiting for). At every token the walker asks ONE question
# first:
#
#     RULE 1: is this token currently claimed as a flag's value?
#             If yes it is DATA, consumed verbatim, and is NEVER eligible to be
#             an operator, a flag, a `--name=value` split, a cluster expansion,
#             a subcommand, or a new base command.
#
# Only after RULE 1 says "unclaimed" may a token be considered for, in order:
#   RULE 2: a chain operator (&&, ||, ;, |, &) -> flush + start a new segment;
#   RULE 3: a bare `git`/`gh` -> flush + start a new invocation (this is what
#           catches newline-separated commands, which the tokenizer flattens);
#   RULE 4: `--`               -> end of options for the rest of this segment
#           (shell operators still split -- `--` binds the command, not the shell);
#   RULE 5: `--name=value`     -> resolved ATOMICALLY here; whatever `name` is,
#           recognized or not, `value` is consumed on the spot and can never be
#           looked at again;
#   RULE 6: `--name`           -> classified; a value-taking one sets `pending`
#           so the NEXT token is claimed by RULE 1 before anything else sees it;
#   RULE 7: `-abc` cluster     -> walked letter by letter, getopt-style; the
#           first value-taking letter takes the rest of the token as its glued
#           value (or claims the next token via `pending`) and ENDS the cluster;
#   RULE 8: anything else      -> positional (possibly the subcommand).
#
# Because `pending` is the single place value-consumption state lives, and it is
# consulted before every other classification, no later addition to this walker
# can reintroduce the defect class without deliberately reading `pending` and
# ignoring it.
#
# Known tokenizer-level limitation (inherent, not fixable here): shellwords
# cannot tell a quoted "|" from a real pipe. RULE 1 covers the case that
# matters (a value is claimed, so its content is never consulted), and the
# residual case -- an operator-looking string as an *unclaimed positional* --
# is handled by the carry-over rule at `seg_reset`: a segment that begins
# directly with an option token (no command name of its own) inherits the
# previous invocation's context instead of being skipped. See seg_adopt_carry.

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
strip_attribution="${script_dir}/strip-attribution.sh"
detypo="${script_dir}/detypo.pl"

deny() {
  # $1: permissionDecisionReason text.
  jq -nc --arg reason "$1" \
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

# Same fail-open treatment for the sibling script the deny check delegates
# to. Without this precheck, a missing or non-executable strip-attribution.sh
# makes `"$strip_attribution" --check` exit 126/127 -- indistinguishable, to
# a bare `if ! ...`, from exit 1 ("attribution found") -- so a broken install
# would silently deny EVERY commit, including completely clean ones, with
# the misleading "contains an AI tool attribution trailer" message. A broken
# dependency must fail open here exactly like the jq/perl case above.
if [ ! -x "$strip_attribution" ]; then
  echo "git-hygiene guard.sh: strip-attribution.sh not found or not executable at ${strip_attribution}; skipping checks for this call." >&2
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
  # file's contents if it names a real, readable regular file, else print
  # the literal argument back (harmless fallback -- it is scanned as
  # ordinary text). This must NEVER be able to abort the whole script via
  # `set -e`: guard.sh processes a chain of `&&`/`||`/`;`-separated
  # invocations in one pass, and a crash here (e.g. `cat` on a directory:
  # `-r` alone passes for a directory's permission bits, but `cat` then
  # fails) must not skip scanning every segment after this one in the
  # chain. `[ -f "$val" ]` rules out directories/devices/etc. up front,
  # and the trailing `|| printf ...` is a second line of defense against
  # any other reason `cat` might fail between the `-f`/`-r` checks and the
  # read itself (permission changed out from under us, a symlink loop,
  # and so on) -- in every such case this degrades to "treat as an
  # unreadable literal", never to "abort guard.sh entirely".
  #
  # Size-bounded on purpose (see also the line cap in flush_segment): a
  # PreToolUse hook that runs past its timeout is KILLED, and a killed hook is
  # non-blocking -- so an unbounded read of a huge file does not merely stall,
  # it fails open and lets the very call it was checking through. Reading the
  # head and the tail of an oversized file keeps that bounded while still
  # covering where attribution actually lives: trailers and the "Generated
  # with" footer are, by construction, at the END of a message.
  local val="$1" size=0
  if [ -n "$val" ] && [ -f "$val" ] && [ -r "$val" ]; then
    size="$(wc -c <"$val" 2>/dev/null || echo 0)"
    if [ "${size:-0}" -gt 1048576 ]; then
      {
        head -c 524288 -- "$val" 2>/dev/null || true
        printf '\n[guard.sh: middle of an oversized message file skipped]\n'
        tail -c 524288 -- "$val" 2>/dev/null || true
      } || printf '%s' "$val"
    else
      cat -- "$val" 2>/dev/null || printf '%s' "$val"
    fi
  else
    printf '%s' "$val"
  fi
}

# ---------------------------------------------------------------------------
# Option tables.
#
# Four classes, and the reason the distinction matters for each:
#   msg    - the value IS operator-supplied message text -> scan it.
#   file   - the value NAMES a file whose contents are the message -> read+scan.
#   ignore - the value is NOT message text, but the option definitely REQUIRES
#            a separate value argument. Listing it is what stops that value from
#            being misread as syntax (`--author=-F <path>` must not read <path>).
#            An option is listed here ONLY if real git/gh really does consume the
#            next token; a wrongly listed boolean would swallow a following real
#            `-m` and turn a contaminated commit into a false ALLOW.
#   optarg - short options whose value, if any, must be GLUED (`-u<mode>`,
#            `-S<keyid>`). They never consume the next token, so they must not be
#            in `ignore`, but the rest of their own token is not more flags either.
#
# Audit of git message-carrying options that are deliberately NOT `msg`:
#   -c / -C / --reuse-message / --reedit-message / --squash / --fixup
#       These name an EXISTING commit; the resulting message text comes out of
#       history, not out of this invocation's command line. This guard exists to
#       stop the harness from *injecting* attribution into a new message; text
#       that is already in the repository was either already screened when it was
#       first written or is the human's own history, and re-reading it here would
#       mean shelling out to `git log` (a side effect a PreToolUse hook should not
#       have) for no new coverage. Classified `ignore` so their argument cannot be
#       mistaken for syntax.
#   --amend
#       Boolean. Reuses the previous commit's message unless -m/-F/--trailer are
#       also given -- and those are already covered above, so --amend needs no
#       handling of its own.
#   -t / --template <file>
#       Seeds the EDITOR with a template; the human then edits it interactively,
#       and git's own commit-msg hook (scripts/commit-msg) is the right layer for
#       whatever they end up writing. Classified `ignore`, not `file`, so the
#       template is never read by this hook.
#   --trailer IS in scope and IS `msg`: it is new, operator-supplied text on this
#       command line, and `--trailer "Co-Authored-By: x <noreply@anthropic.com>"`
#       is a direct spelling of the exact thing this guard denies. Repeatable,
#       like -m; every occurrence is collected.
# ---------------------------------------------------------------------------

tab_msg_long=""
tab_file_long=""
tab_ignore_long=""
tab_msg_short=""
tab_file_short=""
tab_ignore_short=""
tab_optarg_short=""

set_tables() {
  # $1: base ("git"/"gh"), $2: subcommand path ("commit", "pr create", ...).
  # An unknown/not-yet-seen subcommand gets the conservative superset for that
  # base, so options seen before the subcommand token still classify sanely.
  local base="$1" sub="$2"

  if [ -z "$base" ]; then
    # No invocation identified yet: recognize nothing, so a stray option token
    # outside any git/gh command can never be classified as message-bearing.
    tab_msg_long=""
    tab_file_long=""
    tab_ignore_long=""
    tab_msg_short=""
    tab_file_short=""
    tab_ignore_short=""
    tab_optarg_short=""
    return
  fi

  if [ "$base" = "git" ]; then
    # Common to commit/merge/tag. `git push` has no message options at all.
    tab_msg_long="message trailer"
    tab_file_long="file"
    tab_msg_short="m"
    tab_file_short="F"
    case "$sub" in
      commit)
        tab_ignore_long="author date cleanup reuse-message reedit-message squash fixup template pathspec-from-file"
        tab_ignore_short="cCt"
        tab_optarg_short="uS" # -u[<mode>], -S[<keyid>]: glued value only
        ;;
      merge)
        # NB: for `git merge`, --squash and --fixup are BOOLEAN (they mean
        # something else than on commit), so they must not be listed as
        # value-taking here or a following -m would be swallowed.
        # --gpg-sign/-S and --log take OPTIONAL values (`--gpg-sign[=<keyid>]`),
        # so they are deliberately absent: claiming the next token for them
        # could swallow a real `-m`.
        tab_ignore_long="strategy strategy-option into-name"
        tab_ignore_short="sX"
        tab_optarg_short="S"
        ;;
      tag)
        tab_ignore_long="local-user cleanup"
        tab_ignore_short="u"
        tab_optarg_short=""
        ;;
      push)
        tab_msg_long=""
        tab_file_long=""
        tab_msg_short=""
        tab_file_short=""
        tab_ignore_long="repo receive-pack exec push-option"
        tab_ignore_short="o"
        tab_optarg_short=""
        ;;
      *)
        # Includes the "subcommand not yet read" state: `git -c k=v commit ...`
        # and `git -C <path> commit ...` must consume their value here.
        tab_ignore_long="git-dir work-tree namespace author date"
        tab_ignore_short="cC"
        tab_optarg_short=""
        ;;
    esac
    return
  fi

  # gh. Verified against `gh <sub> --help` for gh 2.97:
  #   -b/--body everywhere except releases, where it is -n/--notes;
  #   -F/--body-file (releases: -F/--notes-file);
  #   -t/--title, except `gh pr merge` where -t is --subject (the real merge
  #   commit subject -- in scope, it lands in git history).
  # gh uses pflag/cobra, which does NOT accept abbreviated long options
  # (verified: `gh pr create --bod=x` -> "unknown flag"), so gh names are
  # matched exactly; only git gets prefix matching.
  # Baseline for EVERY gh subcommand, narrowed (never widened) per subcommand
  # below. `title`/`subject`/`-t` stay in the baseline even for subcommands that
  # have no such flag (`gh pr comment`, `gh pr review`, `gh issue comment`):
  # scanning text gh would have rejected as an unknown flag costs nothing, while
  # dropping it would be an under-match -- the one direction this guard must
  # never err in.
  tab_optarg_short=""
  tab_msg_long="body title subject"
  tab_file_long="body-file"
  tab_msg_short="bt"
  tab_file_short="F"
  tab_ignore_long="repo"
  tab_ignore_short="R"
  case "$sub" in
    "pr create")
      tab_msg_long="body title subject"
      tab_file_long="body-file"
      tab_ignore_long="assignee base head label milestone project reviewer template recover repo"
      tab_msg_short="bt"
      tab_file_short="F"
      tab_ignore_short="aBHlmprTR"
      ;;
    "pr edit")
      tab_msg_long="body title subject"
      tab_file_long="body-file"
      tab_ignore_long="add-assignee add-label add-project add-reviewer base milestone remove-assignee remove-label remove-project remove-reviewer repo"
      tab_msg_short="bt"
      tab_file_short="F"
      tab_ignore_short="BmR"
      ;;
    "pr comment" | "issue comment")
      tab_msg_long="body title subject"
      tab_file_long="body-file"
      tab_ignore_long="repo"
      tab_msg_short="bt"
      tab_file_short="F"
      tab_ignore_short="R"
      ;;
    "pr review")
      # -a/--approve, -c/--comment, -r/--request-changes are all BOOLEAN here.
      tab_msg_long="body title subject"
      tab_file_long="body-file"
      tab_ignore_long="repo"
      tab_msg_short="bt"
      tab_file_short="F"
      tab_ignore_short="R"
      ;;
    "pr merge")
      # --body/--subject become the real merge commit message, so they are in
      # scope exactly like `git merge -m`. -m/-r/-s/-d are BOOLEAN here
      # (--merge/--rebase/--squash/--delete-branch), notably -m is NOT a message.
      tab_msg_long="body subject title"
      tab_file_long="body-file"
      tab_ignore_long="author-email match-head-commit repo"
      tab_msg_short="bt"
      tab_file_short="F"
      tab_ignore_short="AR"
      ;;
    "issue create")
      tab_msg_long="body title subject"
      tab_file_long="body-file"
      tab_ignore_long="assignee label milestone project template type parent blocked-by blocking recover repo"
      tab_msg_short="bt"
      tab_file_short="F"
      tab_ignore_short="almpTR"
      ;;
    "release create" | "release edit")
      tab_msg_long="notes title subject body"
      tab_file_long="notes-file body-file"
      tab_ignore_long="discussion-category notes-start-tag target tag repo"
      tab_msg_short="nt"
      tab_file_short="F"
      tab_ignore_short="R"
      ;;
    *)
      # Unknown / not-yet-read gh subcommand: recognize the message spellings
      # that are uniform across gh, but not -n (release-only; on other gh
      # commands it does not exist, and enforcement.md section 5 is emphatic
      # that -n must never be given a cross-command meaning).
      tab_msg_long="body title subject notes"
      tab_file_long="body-file notes-file"
      tab_ignore_long="repo"
      tab_msg_short="bt"
      tab_file_short="F"
      tab_ignore_short="R"
      ;;
  esac
}

_matches_exact() {
  # $1: candidate long-option name (no leading dashes); $2: space-separated list.
  local c="$1" lst="$2" e
  [ -n "$c" ] || return 1
  for e in $lst; do
    [ "$e" = "$c" ] && return 0
  done
  return 1
}

_matches_prefix() {
  # git's parse-options accepts any unambiguous PREFIX of a long option
  # (verified: `git commit --m` == --message, `--mess=x` == --message=x). Match
  # the same way against our own recognized names: a candidate matches if it is
  # a non-empty prefix of a listed name.
  #
  # This is intentionally asymmetric in the safe direction. A prefix that real
  # git would reject as ambiguous against its FULL option set (e.g. `--f`, which
  # real git says could be --file or --fixup) is treated here as our flag: an
  # over-cautious deny costs one retry, whereas under-matching a real
  # message-bearing invocation is a silent miss, which is the failure this whole
  # guard exists to prevent.
  local c="$1" lst="$2" e
  [ -n "$c" ] || return 1
  for e in $lst; do
    [ "${e:0:${#c}}" = "$c" ] && return 0
  done
  return 1
}

CLS=""
classify_long() {
  # $1: long-option name without leading dashes. Sets CLS to
  # msg|file|noverify|ignore|none. Order matters: message classes win over
  # ignore, so an ambiguous prefix errs toward scanning rather than skipping.
  local name="$1" matcher=_matches_exact
  CLS="none"
  [ "$seg_base" = "git" ] && matcher=_matches_prefix

  if "$matcher" "$name" "$tab_msg_long"; then
    CLS="msg"
    return 0
  fi
  if "$matcher" "$name" "$tab_file_long"; then
    CLS="file"
    return 0
  fi
  if [ "$seg_base" = "git" ] && _matches_prefix "$name" "no-verify"; then
    CLS="noverify"
    return 0
  fi
  if "$matcher" "$name" "$tab_ignore_long"; then
    CLS="ignore"
    return 0
  fi
  return 0
}

# --- per-segment state -----------------------------------------------------
seg_base=""
seg_sub=""
seg_subwords=0
seg_tokens=0
seg_no_more_options=0
seg_no_verify=0
pending=""
messages=()
warnings=()

# Carried across a segment boundary purely so a segment that starts directly
# with an option token (no command name of its own -- which a real command after
# `&&` always has) can inherit the previous invocation's context. This is the
# residual defense for the tokenizer limitation noted in the design block: if a
# quoted operator-looking POSITIONAL ever splits one real invocation in two, the
# tail half is still scanned rather than silently dropped. It deliberately does
# NOT fire for a genuine following command such as `... && echo -n done`, whose
# first token is `echo`, so `-n` there is never misread as --no-verify.
carry_base=""
carry_sub=""

seg_reset() {
  seg_base=""
  seg_sub=""
  seg_subwords=0
  seg_tokens=0
  seg_no_more_options=0
  seg_no_verify=0
  pending=""
  messages=()
  set_tables "" ""
}

consume_value() {
  # $1: pending class, $2: the claimed token (verbatim DATA, never re-parsed).
  case "$1" in
    msg) messages+=("$2") ;;
    file) messages+=("$(read_file_or_literal "$2")") ;;
    *) : ;; # ignore-class: consumed and discarded
  esac
}

note_no_verify() {
  # enforcement.md section 5: only ever a bypass signal on git, and only on the
  # four subcommands named there. (Strictly, `-n` means --no-verify only on
  # `git commit`; on push it is --dry-run, on merge --no-stat, on tag -n<num>.
  # The doc's wider scope is kept deliberately -- this is a warning, never a
  # deny, and the conservative direction here is to mention it.)
  case "$seg_sub" in
    commit | merge | push | tag) seg_no_verify=1 ;;
  esac
}

flush_segment() {
  # Run the deny + warn checks for the invocation just finished. Called at every
  # segment boundary and once at end of input. A deny exits the whole script.
  local label combined loosened m strip_check_rc

  if [ -z "$seg_base" ]; then
    return 0
  fi

  label="$seg_base"
  [ -n "$seg_sub" ] && label="$seg_base $seg_sub"

  combined=""
  if [ "${#messages[@]}" -gt 0 ]; then
    for m in "${messages[@]}"; do
      # git concatenates repeated -m values into separate paragraphs; joining
      # with a newline is what makes a trailer on any one of them line-anchored
      # for strip-attribution.sh, and is why the SECOND -m of a pair is checked
      # exactly like the first.
      combined="${combined}${m}"$'\n'
    done
  fi

  # Cap the number of LINES handed to the checkers. strip-attribution.sh scans
  # line by line in bash, which is roughly milliseconds per line -- a 20k-line
  # message takes minutes, which means the hook is killed on timeout and, per
  # enforcement.md section 1, a killed hook does not block. Checking the first
  # and last 200 lines of an absurdly long message is strictly better than
  # checking none of it: every attribution pattern is a trailer or a footer, so
  # the tail is exactly where it would be.
  if [ "$(printf '%s' "$combined" | wc -l)" -gt 400 ]; then
    combined="$(printf '%s' "$combined" | perl -0777 -ne '
      my @l = split /\n/, $_, -1;
      print join("\n", @l[0 .. 199]),
            "\n[guard.sh: middle of an unusually long message skipped]\n",
            join("\n", @l[-200 .. -1]), "\n";
    ' 2>/dev/null || printf '%s' "$combined")"
  fi

  # A "loosened" second reading of the same text, checked only if the literal
  # one comes back clean. It exists because the tokenizer (shellwords) is a
  # quote remover, not a shell, and two of its blind spots would otherwise let a
  # trailer through on a technicality of LINE ANCHORING -- the attribution
  # patterns all require the trailer to start a line and end one:
  #   - `$'fix\n\nCo-Authored-By: x <noreply@anthropic.com>'` (ANSI-C quoting,
  #     a common way to write a multi-line message in a one-liner) reaches us
  #     with a literal backslash-n, so the trailer is not at a line start.
  #   - `{ git commit -m "...<noreply@anthropic.com>"; }` / `(git commit ...)`
  #     glue the group's trailing `;`/`)`/`}` onto the last token, so the
  #     trailer no longer ends its line.
  # Undoing exactly those two things and re-checking cannot create a false
  # positive of consequence: every pattern it can newly match still requires a
  # bot address, a session trailer, or the generated-with footer to be present
  # in the text verbatim.
  loosened="$(printf '%s' "$combined" | perl -0777 -pe 's/\\n/\n/g; s/[ \t]*[;)}]+[ \t]*$//mg' 2>/dev/null || printf '%s' "$combined")"
  [ "$loosened" = "$combined" ] && loosened=""

  # --- Deny check: the four deterministic attribution patterns. Any single
  # contaminated invocation anywhere in the chain denies the whole call. ---
  if [ -n "$combined" ]; then
    # The precheck near the top only catches strip-attribution.sh being missing
    # or non-executable BEFORE we ever try to run it. It cannot catch the script
    # existing, being executable, and then crashing partway through (interpreter
    # error, corrupted file swapped in mid-session, etc.) -- that failure mode
    # still needs distinguishing from "exit 1: attribution found" here, or an
    # executable-but-broken script would deny every clean commit exactly like
    # the missing-file case. Capture the real exit code with the `cmd || rc=$?`
    # idiom (enforcement.md section 6) so a failing pipeline under `set -e` does
    # not abort the whole script.
    strip_check_rc=0
    printf '%s' "$combined" | "$strip_attribution" --check >/dev/null 2>&1 || strip_check_rc=$?
    if [ "$strip_check_rc" -eq 126 ] || [ "$strip_check_rc" -eq 127 ]; then
      warnings+=("git-hygiene: strip-attribution.sh exited unexpectedly (code ${strip_check_rc}) while checking '${label}'; skipping the attribution check for this call rather than denying it -- see references/enforcement.md.")
    elif [ "$strip_check_rc" -ne 0 ]; then
      deny "Commit/PR message contains an AI tool attribution trailer (Co-Authored-By bot address, a <Tool>-Session: trailer, the 'Generated with [...]' footer, or a bare harness session URL). Remove it before proceeding -- see references/attribution.md."
    fi
  fi

  if [ -n "$loosened" ]; then
    strip_check_rc=0
    printf '%s' "$loosened" | "$strip_attribution" --check >/dev/null 2>&1 || strip_check_rc=$?
    if [ "$strip_check_rc" -ne 0 ] && [ "$strip_check_rc" -ne 126 ] && [ "$strip_check_rc" -ne 127 ]; then
      deny "Commit/PR message contains an AI tool attribution trailer (Co-Authored-By bot address, a <Tool>-Session: trailer, the 'Generated with [...]' footer, or a bare harness session URL). Remove it before proceeding -- see references/attribution.md."
    fi
  fi

  # --- Warn-only checks for this invocation. Never deny here. ---
  if [ -n "$combined" ]; then
    if ! printf '%s' "$combined" | perl "$detypo" --check >/dev/null 2>&1; then
      warnings+=("git-hygiene: possible machine typography (em dash, curly quotes, or similar) detected in the message text of '${label}'. Not blocked -- the false-positive rate is too high to enforce -- but worth a look before you proceed. See references/typography.md.")
    fi
  fi

  if [ "$seg_base" = "git" ] && [ "$seg_no_verify" -eq 1 ]; then
    warnings+=("git-hygiene: this command bypasses git's own commit-msg hook (--no-verify/-n) on '${label}'. If the opt-in commit-msg hygiene check is installed in this clone, it will not run for this call -- double-check the message manually.")
  fi
}

end_segment() {
  flush_segment
  carry_base="$seg_base"
  carry_sub="$seg_sub"
  seg_reset
}

record_subword() {
  # $1: a positional token in a position where the subcommand path is still
  # being read. git takes one word (commit), gh takes two (pr create).
  local want=1
  [ "$seg_base" = "gh" ] && want=2
  if [ "$seg_subwords" -lt "$want" ]; then
    if [ -z "$seg_sub" ]; then
      seg_sub="$1"
    else
      seg_sub="$seg_sub $1"
    fi
    seg_subwords=$((seg_subwords + 1))
    set_tables "$seg_base" "$seg_sub"
  fi
}

seg_reset

# ===========================================================================
# THE WALK. One pass, left to right, over the raw token stream.
# ===========================================================================
i=0
n="${#words[@]}"
while [ "$i" -lt "$n" ]; do
  tok="${words[$i]}"
  i=$((i + 1))

  # --- RULE 1 -------------------------------------------------------------
  # A claimed value is DATA. It is consumed verbatim here, before any other
  # rule can look at it: not an operator, not a flag, not split on `=`, not a
  # cluster, not a subcommand, not a base command. This single check is the
  # architectural invariant that makes every historical bypass listed in the
  # design block unreachable.
  if [ -n "$pending" ]; then
    consume_value "$pending" "$tok"
    pending=""
    continue
  fi

  # --- RULE 2: chain operators -------------------------------------------
  case "$tok" in
    '&&' | '||' | ';' | '|' | '&' | ';;' | '|&')
      end_segment
      continue
      ;;
  esac

  # --- RULE 3: a bare git/gh token starts a new invocation -----------------
  # Also covers newline-separated commands: the tokenizer collapses newlines to
  # ordinary whitespace, so `git commit -m x<newline>git push` arrives as one
  # flat token stream with no operator between the two invocations.
  # `(git commit ...)` and `{git commit ...;}` arrive with the grouping
  # character glued to the command name, since shellwords is a quote remover
  # and not a shell; strip those before the comparison so a grouped invocation
  # is still recognized as one.
  base_probe="$tok"
  while :; do
    case "$base_probe" in
      '('* | '{'* | '!'*) base_probe="${base_probe:1}" ;;
      *) break ;;
    esac
  done

  # Deliberately NOT gated on `seg_no_more_options`. `--` ends option parsing for
  # the command it appears in, but newlines are erased by the tokenizer, so the
  # only signal that the NEXT line is a new command is its `git`/`gh` token. An
  # earlier version required `seg_no_more_options -eq 0` here, which meant a
  # single `--` anywhere (`git checkout -- .`) suppressed new-invocation
  # detection for every following line until an explicit `&&`/`;`/`||`/`|` turned
  # up -- and an ordinary multi-line block has none, so the guard silently went
  # dark for the rest of it. The cost of not gating is a harmless spurious empty
  # segment when a pathspec is literally named `git` (`... -- git src/`), which
  # produces no messages and therefore no decision.
  if [ "$base_probe" = "git" ] || [ "$base_probe" = "gh" ]; then
    if [ -n "$seg_base" ]; then
      end_segment
    fi
    seg_base="$base_probe"
    seg_tokens=$((seg_tokens + 1))
    set_tables "$seg_base" ""
    continue
  fi

  if [ -z "$seg_base" ]; then
    # Nothing has identified this segment as a git/gh invocation yet. A leading
    # env assignment, `sudo`, `command`, a redirect target and so on all land
    # here and are skipped. The one exception is the carry-over rule: a segment
    # whose VERY FIRST token is already an option cannot be a real command of
    # its own, so it is the tail of a mis-split invocation -- adopt the previous
    # invocation's context rather than dropping the rest of it unscanned.
    if [ "$seg_tokens" -eq 0 ] && [ -n "$carry_base" ] && [ "${tok:0:1}" = "-" ] && [ "$tok" != "-" ]; then
      seg_base="$carry_base"
      seg_sub="$carry_sub"
      seg_subwords=9
      set_tables "$seg_base" "$seg_sub"
    else
      seg_tokens=$((seg_tokens + 1))
      continue
    fi
  fi

  seg_tokens=$((seg_tokens + 1))

  if [ "$seg_no_more_options" -eq 1 ]; then
    continue # everything after `--` is a positional operand
  fi

  case "$tok" in
    --)
      # --- RULE 4 ---------------------------------------------------------
      # End of options for the command, not for the shell: operators after `--`
      # are still operators (RULE 2 runs before this branch is ever reached
      # again), but nothing else is a flag any more.
      seg_no_more_options=1
      ;;

    --*=*)
      # --- RULE 5 ---------------------------------------------------------
      # An atomic (name, value) PAIR. The value is consumed HERE in every
      # branch, including the unrecognized-name branch, so it can never be
      # handed back to the walker and re-read as syntax (the `--label=-b -b
      # "<contaminated>"` bypass).
      lname="${tok%%=*}"
      lname="${lname#--}"
      lvalue="${tok#*=}"
      classify_long "$lname"
      case "$CLS" in
        msg) messages+=("$lvalue") ;;
        file) messages+=("$(read_file_or_literal "$lvalue")") ;;
        noverify) note_no_verify ;;
        *) : ;; # unrecognized name: value consumed and discarded, never re-examined
      esac
      ;;

    --?*)
      # --- RULE 6 ---------------------------------------------------------
      classify_long "${tok#--}"
      case "$CLS" in
        msg) pending="msg" ;;
        file) pending="file" ;;
        ignore) pending="ignore" ;;
        noverify) note_no_verify ;;
        *) : ;; # unknown long option: assumed boolean. If it does take a value,
                # that value is a plain token that RULE 8 harmlessly skips --
                # only options KNOWN to require a value may set `pending`, since
                # wrongly claiming the next token could swallow a real -m.
      esac
      ;;

    -?*)
      # --- RULE 7: clustered / glued short options ------------------------
      # POSIX-getopt style, exactly as git and pflag both behave: boolean
      # letters chain (`-am`), and the first value-taking letter takes the rest
      # of THIS token as its glued value (`-m"text"` arrives as `-mtext` after
      # quote removal) or, if it is the last character, claims the NEXT token
      # via `pending` -- where RULE 1 will take it verbatim. Either way the
      # cluster ENDS there; characters after a value-taking letter are never
      # further flags.
      rest="${tok:1}"
      k=0
      while [ "$k" -lt "${#rest}" ]; do
        ch="${rest:$k:1}"
        glued="${rest:$((k + 1))}"
        if [[ -n "$tab_msg_short" && "$tab_msg_short" == *"$ch"* ]]; then
          if [ -n "$glued" ]; then messages+=("$glued"); else pending="msg"; fi
          break
        elif [[ -n "$tab_file_short" && "$tab_file_short" == *"$ch"* ]]; then
          if [ -n "$glued" ]; then messages+=("$(read_file_or_literal "$glued")"); else pending="file"; fi
          break
        elif [[ -n "$tab_ignore_short" && "$tab_ignore_short" == *"$ch"* ]]; then
          [ -z "$glued" ] && pending="ignore"
          break
        elif [[ -n "$tab_optarg_short" && "$tab_optarg_short" == *"$ch"* ]]; then
          # Optional value, glued only (-u<mode>, -S<keyid>): never claims the
          # next token, but the rest of this one is its value, not more flags.
          break
        else
          if [ "$ch" = "n" ] && [ "$seg_base" = "git" ]; then
            note_no_verify
          fi
          k=$((k + 1))
        fi
      done
      ;;

    *)
      # --- RULE 8: positional -------------------------------------------
      record_subword "$tok"
      ;;
  esac
done

flush_segment

if [ "${#warnings[@]}" -gt 0 ]; then
  printf '%s\n' "${warnings[@]}"
fi

exit 0

#!/usr/bin/env bash
# guard-selftest.sh - regression corpus for scripts/guard.sh.
#
# Standalone and self-contained: run it directly, any working directory.
#
#   plugins/git-hygiene/scripts/guard-selftest.sh          # run everything
#   plugins/git-hygiene/scripts/guard-selftest.sh -v       # also print passes
#
# Exit 0 = every assertion passed. Exit 1 = at least one failed; the failures
# are listed again at the end with the command line that produced them.
#
# Each case feeds guard.sh a PreToolUse payload ({"tool_input":{"command":...}})
# on stdin and asserts on the resulting decision:
#   DENY  -> stdout parses as JSON with .hookSpecificOutput.permissionDecision
#            == "deny" (references/enforcement.md section 1: this, and only
#            this, blocks the tool call).
#   ALLOW -> no such deny JSON. guard.sh must still exit 0 in both cases;
#            exit 1 would be a non-blocking hook error, never a block.
#
# Every "contaminated" fixture uses the same real bot attribution address,
# noreply@anthropic.com, in a Co-Authored-By trailer -- one of the four
# deterministic patterns strip-attribution.sh --check detects.
#
# The corpus covers, in order:
#   1. baseline spellings          6. glued/`=`/prefix spellings
#   2. -F file reads               7. --trailer
#   3. gh subcommands              8. repeated -m
#   4. chained commands            9. must-ALLOW cases (no false positives)
#   5. hostile message VALUES     10. regressions from the three prior fix rounds

set -uo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
guard="${script_dir}/guard.sh"

verbose=0
[ "${1:-}" = "-v" ] && verbose=1

if [ ! -x "$guard" ]; then
  echo "guard-selftest.sh: ${guard} missing or not executable" >&2
  exit 1
fi

tmpdir="$(mktemp -d)"
cleanup() { rm -rf -- "$tmpdir"; }
trap cleanup EXIT

# --- fixtures --------------------------------------------------------------
BOT='Co-Authored-By: Claude <noreply@anthropic.com>'
BOT_LC='co-authored-by: claude <noreply@anthropic.com>'
DIRTY="fix: something

${BOT}"

printf '%s\n' "fix: from a file" "" "$BOT" >"${tmpdir}/dirty.txt"
printf '%s\n' "fix: from a file" "" "clean trailer: yes" >"${tmpdir}/clean.txt"
dirty_file="${tmpdir}/dirty.txt"
clean_file="${tmpdir}/clean.txt"
mkdir -p "${tmpdir}/adir"

total=0
failed=0
failures=()

run_guard() {
  # $1: shell command line to hand the hook. Echoes guard.sh's stdout.
  #
  # The `timeout` is load-bearing, not belt-and-braces: a PreToolUse hook that
  # runs past Claude Code's own timeout is killed, and a killed hook does not
  # block (enforcement.md section 1) -- so "guard.sh is very slow" IS a bypass,
  # not just a performance nit. Any case that hangs shows up here as a non-zero
  # exit and fails the suite.
  jq -nc --arg c "$1" '{tool_input: {command: $c}}' | timeout 25 "$guard" 2>/dev/null
}

assert_case() {
  # $1: "deny"|"allow", $2: description, $3: command line
  local want="$1" desc="$2" cmd="$3" out decision rc
  total=$((total + 1))
  out="$(run_guard "$cmd")"
  rc=$?
  decision="$(printf '%s' "$out" | jq -r '.hookSpecificOutput.permissionDecision // "allow"' 2>/dev/null || echo allow)"
  [ -z "$decision" ] && decision="allow"

  if [ "$rc" -ne 0 ]; then
    failed=$((failed + 1))
    failures+=("[exit ${rc}, expected 0] ${desc}"$'\n'"    \$ ${cmd}")
    printf 'FAIL %s (guard.sh exited %s)\n' "$desc" "$rc"
    return
  fi

  if [ "$decision" = "$want" ]; then
    [ "$verbose" -eq 1 ] && printf 'ok   %s\n' "$desc"
    return
  fi

  failed=$((failed + 1))
  failures+=("[got ${decision}, expected ${want}] ${desc}"$'\n'"    \$ ${cmd}")
  printf 'FAIL %s (got %s, expected %s)\n' "$desc" "$decision" "$want"
}

deny() { assert_case deny "$1" "$2"; }
allow() { assert_case allow "$1" "$2"; }

assert_warn() {
  # $1: "yes"|"no", $2: substring the transcript warning must/must not contain,
  # $3: description, $4: command line. Warnings are the only observable proof
  # that per-invocation SEGMENTATION works: a guard that never resets its
  # per-segment state still denies contaminated chains (deny is a global OR),
  # but it misattributes `-n` in a later unrelated command as --no-verify on
  # the earlier git call. These assertions pin that down.
  local want="$1" needle="$2" desc="$3" cmd="$4" out got
  total=$((total + 1))
  out="$(run_guard "$cmd")"
  got="no"
  case "$out" in *"$needle"*) got="yes" ;; esac
  if [ "$got" = "$want" ]; then
    [ "$verbose" -eq 1 ] && printf 'ok   %s\n' "$desc"
    return
  fi
  failed=$((failed + 1))
  failures+=("[warning '${needle}' ${got}, expected ${want}] ${desc}"$'\n'"    \$ ${cmd}")
  printf 'FAIL %s (warning present: %s, expected %s)\n' "$desc" "$got" "$want"
}

echo "== 1. baseline message spellings (must DENY) =="
deny "git commit -m plain"                 "git commit -m \"fix: x

${BOT}\""
deny "git commit clustered -am"            "git commit -am \"fix: x

${BOT}\""
deny "git commit --message=<dirty>"        "git commit --message=\"fix: x

${BOT}\""
deny "git commit -m glued (-m\"...\")"     "git commit -m\"fix: x

${BOT}\""
deny "git commit -m, trailer only"         "git commit -m \"${BOT}\""
deny "git merge -m <dirty>"                "git merge feature -m \"merge

${BOT}\""
deny "git tag -a -m <dirty>"               "git tag -a v1.0.0 -m \"release

${BOT}\""
deny "lowercase co-authored-by variant"    "git commit -m \"fix: x

${BOT_LC}\""

echo "== 2. -F / --file (contents must be read) =="
deny "git commit -F <dirty file>"          "git commit -F ${dirty_file}"
deny "git commit --file=<dirty file>"      "git commit --file=${dirty_file}"
deny "git commit -F<dirty file> glued"     "git commit -F${dirty_file}"
deny "git commit -aF <dirty file>"         "git commit -aF ${dirty_file}"

echo "== 3. gh subcommands (must DENY) =="
deny "gh pr create --body"                 "gh pr create --title t --body \"${BOT}\""
deny "gh pr create -b"                     "gh pr create -t t -b \"${BOT}\""
deny "gh pr create --body=<dirty>"         "gh pr create -t t --body=\"${BOT}\""
deny "gh pr create -b glued"               "gh pr create -t t -b\"${BOT}\""
deny "gh pr create --body-file <dirty>"    "gh pr create -t t --body-file ${dirty_file}"
deny "gh pr create --body-file=<dirty>"    "gh pr create -t t --body-file=${dirty_file}"
deny "gh pr create -F <dirty>"             "gh pr create -t t -F ${dirty_file}"
deny "gh pr create -F<dirty> glued"        "gh pr create -t t -F${dirty_file}"
deny "gh pr create --title (dirty title)"  "gh pr create --title \"${BOT}\" -b ok"
deny "gh pr edit --body"                   "gh pr edit 12 --body \"${BOT}\""
deny "gh issue create --body"              "gh issue create -t t --body \"${BOT}\""
deny "gh issue create -F"                  "gh issue create -t t -F ${dirty_file}"
deny "gh pr comment --body"                "gh pr comment 12 --body \"${BOT}\""
deny "gh pr comment -F"                    "gh pr comment 12 -F ${dirty_file}"
deny "gh issue comment --body"             "gh issue comment 7 --body \"${BOT}\""
deny "gh pr review --body"                 "gh pr review 12 --approve --body \"${BOT}\""
deny "gh pr review -b"                     "gh pr review 12 -c -b \"${BOT}\""
deny "gh pr merge --body"                  "gh pr merge 12 --squash --body \"${BOT}\""
deny "gh pr merge -b"                      "gh pr merge 12 -s -b \"${BOT}\""
deny "gh pr merge --subject"               "gh pr merge 12 --squash --subject \"${BOT}\""
deny "gh pr merge -t (=--subject)"         "gh pr merge 12 -s -t \"${BOT}\""
deny "gh pr merge -F"                      "gh pr merge 12 -s -F ${dirty_file}"
deny "gh release create --notes"           "gh release create v1.0.0 --notes \"${BOT}\""
deny "gh release create -n"                "gh release create v1.0.0 -n \"${BOT}\""
deny "gh release create -F"                "gh release create v1.0.0 -F ${dirty_file}"
deny "gh release edit --notes"             "gh release edit v1.0.0 --notes \"${BOT}\""

echo "== 4. chained commands (every segment must be scanned) =="
deny "&& chain, dirty FIRST"               "git commit -m \"${BOT}\" && git push"
deny "&& chain, dirty LAST"                "git add -A && git commit -m \"${BOT}\""
deny "&& chain, dirty MIDDLE of 3"         "git add -A && git commit -m \"${BOT}\" && git push"
deny "; separated"                         "git add -A ; git commit -m \"${BOT}\" ; git push"
deny "|| separated"                        "git commit -m \"${BOT}\" || true"
deny "| piped"                             "git commit -m \"${BOT}\" | tee /dev/null"
deny "newline separated (no operator)"     "git add -A
git commit -m \"${BOT}\"
git push"
deny "git then gh in one chain"            "git commit -m clean && gh pr create -t t -b \"${BOT}\""
deny "leading env assignment"              "GIT_AUTHOR_NAME=x git commit -m \"${BOT}\""

echo "== 5. hostile message VALUES (segmentation-layer defect class) =="
deny "value starts with -"                 "git commit -m \"-fix: x

${BOT}\""
deny "value starts with --"                "git commit -m \"--fix: x

${BOT}\""
deny "value contains ="                    "git commit -m \"fix: a=b

${BOT}\""
deny "value mentions a flag"               "git commit -m \"-n is now supported

${BOT}\""
deny "value looks like -xF<path>"          "git commit -m \"-xF/etc/passwd

${BOT}\""
deny "value IS exactly |"                  "git commit -m '|' -m \"${BOT}\""
deny "value IS exactly &&"                 "git commit -m '&&' -m \"${BOT}\""
deny "value IS exactly ||"                 "git commit -m '||' -m \"${BOT}\""
deny "value IS exactly ;"                  "git commit -m ';' -m \"${BOT}\""
deny "value IS exactly | then chain"       "git commit -m '|' && gh pr create -t t -b \"${BOT}\""
deny "value IS the word git"               "git commit -m 'git' -m \"${BOT}\""
deny "dirty value that IS an operator"     "git commit -m \"|

${BOT}\""
deny "unrecognized --name=<flag-shaped>"   "gh pr create --label=-b -b \"${BOT}\""
deny "unrecognized --name=-F<path>"        "gh pr create --label=-F${dirty_file} -t t -b \"${BOT}\""
deny "git --author=-m then real -m"        "git commit --author=-m -m \"${BOT}\""

echo "== 6. -F pointed at unreadable things (must not abort the walk) =="
deny "-F <directory> then dirty chain"     "git commit -F ${tmpdir}/adir && git commit -m \"${BOT}\""
deny "-F <nonexistent> then dirty chain"   "git commit -F ${tmpdir}/nope.txt && git commit -m \"${BOT}\""
deny "-F /dev/null then dirty chain"       "git commit -F /dev/null && git commit -m \"${BOT}\""
deny "-F <dir> in same segment as -m"      "git commit -F ${tmpdir}/adir -m \"${BOT}\""
deny "gh -F <directory> then dirty chain"  "gh pr create -t t -F ${tmpdir}/adir && git commit -m \"${BOT}\""

echo "== 7. git long-option abbreviations (parse-options prefix matching) =="
deny "--m"                                 "git commit --m \"${BOT}\""
deny "--me"                                "git commit --me \"${BOT}\""
deny "--mes"                               "git commit --mes \"${BOT}\""
deny "--mess="                             "git commit --mess=\"${BOT}\""
deny "--messag="                           "git commit --messag=\"${BOT}\""
deny "--message="                          "git commit --message=\"${BOT}\""
deny "--fil=<dirty file>"                  "git commit --fil=${dirty_file}"
deny "--fi <dirty file>"                   "git commit --fi ${dirty_file}"
deny "--f <dirty file>"                    "git commit --f ${dirty_file}"

echo "== 8. --trailer and repeated -m =="
deny "--trailer <dirty>"                   "git commit -m ok --trailer \"${BOT}\""
deny "--trailer=<dirty>"                   "git commit -m ok --trailer=\"${BOT}\""
deny "--trail= abbreviation"               "git commit -m ok --trail=\"${BOT}\""
deny "second -m dirty, first clean"        "git commit -m \"fix: subject\" -m \"${BOT}\""
deny "third -m dirty"                      "git commit -m a -m b -m \"${BOT}\""
deny "-m clean then -F dirty"              "git commit -m \"fix: subject\" -F ${dirty_file}"

echo "== 9. must ALLOW (no false positives) =="
allow "clean conventional -m"              "git commit -m \"fix: correct off-by-one error in parser\""
allow "clean -m with leading dash text"    "git commit -m \"-n is now supported by the parser\""
allow "clean -am"                          "git commit -am \"feat: add flag -x to the cli\""
allow "clean -F <clean file>"              "git commit -F ${clean_file}"
allow "gh release create -n (notes)"       "gh release create v1.0.0 -n \"Release notes\""
allow "gh release create -n multiword"     "gh release create v1.0.0 --title \"v1.0.0\" -n \"Bug fixes and improvements\""
allow "gh pr comment clean"                "gh pr comment 12 --body \"Looks good to me, thanks.\""
allow "gh issue comment clean"             "gh issue comment 7 -b \"Reproduced on main.\""
allow "gh pr review clean"                 "gh pr review 12 --approve --body \"Nice work.\""
allow "gh pr merge clean"                  "gh pr merge 12 --squash --subject \"feat: add thing\" --body \"see PR\""
allow "git commit --author=-F <file>"      "git commit --author=-F ${dirty_file} -m \"fix: a clean subject\""
allow "gh pr create --repo=-F <file>"      "gh pr create --repo=-F ${dirty_file} -t \"title\" -b \"clean body\""
allow "git commit --no-verify (warn only)" "git commit --no-verify -m \"clean message\""
allow "git commit -n (warn only)"          "git commit -n -m \"clean message\""
allow "git push --no-verify"               "git push --no-verify origin main"
allow "unrelated: ls -la"                  "ls -la"
allow "unrelated: npm test"                "npm test"
allow "unrelated: echo -n after chain"     "git commit -m \"fix: clean\" && echo -n done"
allow "human co-author trailer"            "git commit -m \"fix: x

Co-Authored-By: Jane Doe <jane@example.com>\""
allow "github privacy-email co-author"     "git commit -m \"fix: x

Co-Authored-By: Jane <12345+jane@users.noreply.github.com>\""
allow "body merely mentions Claude Code"   "git commit -m \"docs: describe the Claude Code hook contract\""
allow "gh pr create -T template file"      "gh pr create -T ${dirty_file} -t \"title\" -b \"clean body\""
allow "git commit -t template file"        "git commit -t ${dirty_file} -m \"fix: clean\""
allow "git commit -C <commit> reuse"       "git commit -C HEAD~1"
allow "git commit --amend --no-edit"       "git commit --amend --no-edit"
allow "git commit -- pathspec"             "git commit -m \"fix: clean\" -- src/main.c"
allow "empty command"                      ""
allow "git alone"                          "git"

echo "== 9b. segmentation is real: warnings and file reads stay in their segment =="
assert_warn yes "bypasses git's own commit-msg hook" \
  "--no-verify warns"                        "git commit --no-verify -m \"clean message\""
assert_warn yes "bypasses git's own commit-msg hook" \
  "-n warns on git commit"                   "git commit -n -m \"clean message\""
assert_warn no "bypasses git's own commit-msg hook" \
  "echo -n in a later segment does not warn" "git commit -m \"fix: clean\" && echo -n done"
assert_warn no "bypasses git's own commit-msg hook" \
  "gh -n never warns (it means --notes)"     "gh release create v1.0.0 -n \"Release notes\""
assert_warn no "bypasses git's own commit-msg hook" \
  "gh -n after a git segment"                "git commit -m \"fix: clean\" && gh release create v1.0.0 -n \"notes\""
# An unrelated later command's -F must not be resolved as a git message file.
allow "later segment's -F is not our -F"     "git commit -m \"fix: clean\" && some-linter -F ${dirty_file}"
allow "later segment's -m is not our -m"     "git commit -m \"fix: clean\" && some-tool -m ${dirty_file}"
# ...but the tail of an invocation mis-split by a quoted operator POSITIONAL
# (the tokenizer cannot tell it from a real pipe) is still scanned, because a
# segment that begins with an option token inherits the previous context.
deny "quoted operator positional, tail scanned" "git commit '|' -m \"${BOT}\""

echo "== 10. regressions from the three prior fix rounds =="
# round 1: clustered short options and --name=value not recognized
deny "r1: -am cluster"                     "git commit -am \"${BOT}\""
deny "r1: --message= form"                 "git commit --message=\"${BOT}\""
# round 2: normalization re-parsed already-consumed values
deny "r2: message starting with -"         "git commit -m \"- fix: tidy up

${BOT}\""
deny "r2: message injecting a fake -F"     "git commit -m \"-xF/etc/passwd\" -m \"${BOT}\""
allow "r2: message injecting fake -F only" "git commit -m \"-xF${dirty_file}\""
# round 3: unrecognized --name=value leaked; set -e abort on unreadable -F
deny "r3: --label=-b swallow"              "gh pr create --label=-b -b \"${BOT}\""
deny "r3: unreadable -F does not abort"    "git commit -F ${tmpdir}/adir && git commit -m \"${BOT}\""
# round 4 (this rework): quoted operator as a message value
deny "r4: -m '|' truncation"               "git commit -m '|' && git commit -m \"${BOT}\""
# compound-command bypass that predates all of the above
deny "r0: dirty first segment of a chain"  "git commit -m \"${BOT}\" && git push"

echo "== 11. tokenizer blind spots found by this rework's own adversarial pass =="
# shellwords is a quote remover, not a shell: these three spellings all reach
# the guard with the trailer no longer starting/ending its own line.
deny "subshell (git ...)"                  "(git commit -m \"${BOT}\")"
deny "subshell with spaces"                "( git commit -m \"${BOT}\" )"
deny "brace group { ...; }"                "{ git commit -m \"${BOT}\"; }"
deny "ANSI-C quoting \$'...\\n...'"         "git commit -m \$'fix: x\\n\\n${BOT}'"
deny "ANSI-C quoting inside a chain"       "git add -A && git commit -m \$'fix: x\\n\\n${BOT}'"
deny "grouped gh invocation"               "(gh pr create -t t -b \"${BOT}\")"
allow "clean ANSI-C quoting"               "git commit -m \$'fix: a\\n\\nA normal body paragraph.'"
allow "clean subshell"                     "(git commit -m \"fix: clean\")"
allow "clean brace group"                  "{ git commit -m \"fix: clean\"; }"
# Trailing shell punctuation must not be needed for a clean message to pass.
allow "clean msg ending in a semicolon"    "git commit -m \"fix: end with a semicolon;\""
allow "clean msg with literal backslash-n" "git commit -m \"docs: describe the \\\\n escape\""

echo "== 12. gh flags kept deliberately over-matched (superset of the old guard) =="
# gh pr comment / pr review / issue comment have no --title at all, and gh pr
# merge calls it --subject. Real gh rejects these spellings, so scanning them
# costs nothing -- but under-matching a message-bearing flag never may.
deny "gh pr comment -t"                    "gh pr comment 1 -t \"${BOT}\""
deny "gh pr comment --title"               "gh pr comment 1 --title \"${BOT}\""
deny "gh pr review -t"                     "gh pr review 1 -t \"${BOT}\""
deny "gh pr review --title"                "gh pr review 1 --title \"${BOT}\""
deny "gh issue comment -t"                 "gh issue comment 1 -t \"${BOT}\""
deny "gh issue comment --title"            "gh issue comment 1 --title \"${BOT}\""
deny "gh pr merge --title"                 "gh pr merge 1 --title \"${BOT}\""

echo "== 13. oversized message must stay bounded (a killed hook does not block) =="
yes "a line of ordinary body text" 2>/dev/null | head -n 5000 >"${tmpdir}/long-clean.txt"
cp "${tmpdir}/long-clean.txt" "${tmpdir}/long-tail.txt"
printf '\n%s\n' "$BOT" >>"${tmpdir}/long-tail.txt"
{
  printf '%s\n' "$BOT"
  cat "${tmpdir}/long-clean.txt"
} >"${tmpdir}/long-head.txt"
allow "5000-line clean -F file"            "git commit -F ${tmpdir}/long-clean.txt"
deny "5000-line -F, trailer at the END"    "git commit -F ${tmpdir}/long-tail.txt"
deny "5000-line -F, trailer at the START"  "git commit -F ${tmpdir}/long-head.txt"

echo
if [ "$failed" -eq 0 ]; then
  printf 'guard-selftest: %d/%d assertions passed.\n' "$total" "$total"
  exit 0
fi

printf 'guard-selftest: %d of %d assertions FAILED:\n\n' "$failed" "$total"
printf '  %s\n' "${failures[@]}"
exit 1

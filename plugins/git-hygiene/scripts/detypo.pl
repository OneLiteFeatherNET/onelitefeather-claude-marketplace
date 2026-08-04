#!/usr/bin/env perl
# detypo.pl -- context-aware typography cleanup for Git/GitHub text.
#
# Implements the codepoint table and protection zones documented in
# plugins/git-hygiene/skills/git-hygiene/references/typography.md (the single
# source of truth). See that file for the reasoning behind every decision
# below; this script only implements it.
#
# Usage: detypo.pl [--check] [--lang=de|en] [file...]
#
#   --check       Report findings and exit 1 if any were found. Never
#                 modifies the input file(s).
#   --lang=LANG   "en" (default) or "de". In German mode, a *spaced* U+2013
#                 (the correct Gedankenstrich) and intact German quote pairs
#                 (U+201E ... U+201C) are left alone. U+2014 is still always
#                 corrected -- it has no legitimate use in German.
#
# Without --check, the (possibly rewritten) text is written to STDOUT.
#
# Two hard prohibitions enforced throughout (see reference, section 6):
#   - \p{Pd} is never used as a dash detector (it matches the ASCII hyphen).
#   - No invisible/exotic character is ever written literally into a regex
#     pattern's source text; every one is an explicit \x{....} escape.

use strict;
use warnings;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Getopt::Long qw(GetOptions);

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------

my $check_mode = 0;
my $lang       = 'en';

GetOptions(
    'check'  => \$check_mode,
    'lang=s' => \$lang,
) or die "Usage: $0 [--check] [--lang=de|en] [file...]\n";

die "Unsupported --lang '$lang' (expected 'de' or 'en')\n"
    unless $lang eq 'de' || $lang eq 'en';

my @files = @ARGV;
@files = ('-') unless @files;

# ---------------------------------------------------------------------------
# Simple, direct substitutions: one codepoint -> fixed ASCII text, no
# context sensitivity, no protection-zone-internal budget. These are applied
# to any text that has already been zone-masked (see mask_line below), so
# fenced/indented/blockquote/URL/inline-code content never reaches this
# table at all.
# ---------------------------------------------------------------------------

# Hyphen-family dashes and math minus -- always a direct 1:1 swap.
my $RE_SIMPLE_DASH = qr/[\x{2010}\x{2011}\x{2012}\x{2212}]/;

# Quotes that are always a direct swap (no German-pair ambiguity).
my %SIMPLE_QUOTES = (
    "\x{2018}" => "'",   # LEFT SINGLE QUOTATION MARK
    "\x{2019}" => "'",   # RIGHT SINGLE QUOTATION MARK
    "\x{201C}" => '"',   # LEFT DOUBLE QUOTATION MARK
    "\x{201D}" => '"',   # RIGHT DOUBLE QUOTATION MARK
);

# German-style low quotes -- direct swap UNLESS protected as an intact pair
# (handled separately in mask_line for --lang=de).
my %LOW_QUOTES = (
    "\x{201E}" => '"',   # DOUBLE LOW-9 QUOTATION MARK
    "\x{201A}" => "'",   # SINGLE LOW-9 QUOTATION MARK
);

my $RE_ELLIPSIS = qr/\x{2026}/;

# Whitespace that renders visibly -- replaced with a plain ASCII space.
my $RE_SPACE_LIKE = qr/[\x{00A0}\x{202F}\x{2002}\x{2003}\x{2007}\x{2009}\x{200A}]/;

# Whitespace that renders as nothing -- deleted, never replaced with a space.
my $RE_INVISIBLE = qr/[\x{200B}\x{FEFF}]/;

my %SYMBOLS = (
    "\x{2192}" => '->',
    "\x{2190}" => '<-',
    "\x{21D2}" => '=>',
    "\x{21D0}" => '<=',
    "\x{2022}" => '-',
    "\x{00D7}" => 'x',
    "\x{2122}" => '(TM)',
    "\x{00A9}" => '(C)',
);
my $RE_SYMBOLS = qr/[\x{2192}\x{2190}\x{21D2}\x{21D0}\x{2022}\x{00D7}\x{2122}\x{00A9}]/;

# ---------------------------------------------------------------------------
# Masking: hide protection-zone content that can occur *inside* an otherwise
# processed line (inline code spans, URLs / link targets, and -- in German
# mode only -- intact German quote pairs) behind a private-use-area sentinel,
# so the substitution pass below never sees it.
# ---------------------------------------------------------------------------

my $SENTINEL = "\x{F8FF}"; # Private Use Area, exceedingly unlikely in prose.

sub mask_line {
    my ($line, $lang) = @_;
    my @stash;

    my $stash_and_mark = sub {
        my ($text) = @_;
        push @stash, $text;
        return $SENTINEL . $#stash . $SENTINEL;
    };

    # Inline code spans: one or more backticks, matched with the same-length
    # closing run (CommonMark rule). Mask the whole span, backticks included.
    $line =~ s{(\x{0060}+)((?:(?!\1).)*?)\1}{ $stash_and_mark->($1.$2.$1) }ge;

    # Markdown link targets: the (...) part of [text](target).
    $line =~ s{(\]\()([^)\x{F8FF}]*)(\))}{ $1 . $stash_and_mark->($2) . $3 }ge;

    # Reference-style link destination line: [label]: target
    if ($line =~ /^(\[[^\]]+\]:\s*)(\S+)(.*)$/s) {
        my ($pre, $dest, $rest) = ($1, $2, $3);
        $line = $pre . $stash_and_mark->($dest) . $rest;
    }

    # Bare URLs.
    $line =~ s{(https?://[^\s\)\]\x{F8FF}]+)}{ $stash_and_mark->($1) }ge;

    # German quote pairs: protect only the two marks, not the content
    # between them, so the content itself still gets typographic cleanup.
    if ($lang eq 'de') {
        # Double pair: U+201E opens, U+201C closes (e.g. „Hallo“).
        $line =~ s{(\x{201E})([^\x{201E}\x{201C}\x{F8FF}]*)(\x{201C})}{
            $stash_and_mark->($1) . $2 . $stash_and_mark->($3)
        }ge;
        # Single pair: U+201A opens, U+2018 closes (e.g. ‚klein'). The
        # typography.md codepoint table calls this out explicitly --
        # U+201A gets "Same protection as U+201E" -- so it needs the same
        # intact-pair masking, not just the double-quote pair.
        $line =~ s{(\x{201A})([^\x{201A}\x{2018}\x{F8FF}]*)(\x{2018})}{
            $stash_and_mark->($1) . $2 . $stash_and_mark->($3)
        }ge;
    }

    return ($line, \@stash);
}

sub unmask_line {
    my ($line, $stash) = @_;
    $line =~ s/$SENTINEL(\d+)$SENTINEL/$stash->[$1]/ge;
    return $line;
}

# ---------------------------------------------------------------------------
# Dash resolution (U+2013 EN DASH, U+2014 EM DASH, U+2015 HORIZONTAL BAR).
# See typography.md sections 3 and 7. Budget-gated dashes are the ones whose
# mechanical fallback is a *spaced* hyphen -- "at most one per paragraph",
# beyond which the script reports rather than replaces.
# ---------------------------------------------------------------------------

sub resolve_dashes {
    my ($line, $lang, $budget_ref, $findings_ref, $filename, $lineno) = @_;

    # U+2014 EM DASH -- always corrected, in German too (never an exception).
    # This is the exact worked example in typography.md section 8, edge case
    # 1: a line-opening "— And another thing." must never become a bare
    # "- And another thing." (that reparses as a Markdown list marker), so
    # every occurrence -- not just the ones some other codepoint's regex
    # happens to special-case -- is checked for its match position via
    # $-[0] and routed through the shared line-start guard below.
    $line =~ s{(\x{0020})?(\x{2014})(\x{0020})?}{
        my $at_start = _at_reparse_start($line, $-[0]);
        _dash_replacement('EM DASH', 'U+2014', $1, $2, $3,
            1, # always eligible, regardless of language
            $at_start,
            $budget_ref, $findings_ref, $filename, $lineno);
    }gex;

    # U+2015 HORIZONTAL BAR -- like em dash when it opens a line, like en
    # dash otherwise; here both routes are budget-gated the same way as the
    # em dash, and the line-start guard is applied uniformly via $at_start
    # rather than a separate first pass (which is what let U+2014 slip
    # through the guard before this fix).
    $line =~ s{(\x{0020})?(\x{2015})(\x{0020})?}{
        my $at_start = _at_reparse_start($line, $-[0]);
        _dash_replacement('HORIZONTAL BAR', 'U+2015', $1, $2, $3,
            1, $at_start, $budget_ref, $findings_ref, $filename, $lineno);
    }gex;

    # U+2013 EN DASH.
    $line =~ s{(\x{0020})?(\x{2013})(\x{0020})?}{
        my $at_start = _at_reparse_start($line, $-[0]);
        my ($sb, $ch, $sa) = ($1, $2, $3);
        my $spaced = (defined $sb && defined $sa) ? 1 : 0;
        if ($spaced && $lang eq 'de') {
            # Correct German Gedankenstrich -- never touched, not a finding.
            ($sb // '') . $ch . ($sa // '');
        } else {
            _dash_replacement('EN DASH', 'U+2013', $sb, $ch, $sa,
                $spaced, # only budget-gated when spaced; tight is a direct swap
                $at_start,
                $budget_ref, $findings_ref, $filename, $lineno);
        }
    }gex;

    return $line;
}

# A dash/bullet's match position is "list-marker-shaped" when it starts at
# column 0-3 AND every character on the line before that point is a plain
# space -- CommonMark treats up to three leading spaces as still being
# list-marker position, not just column 0 exactly. (Four or more leading
# spaces is a different, already-protected zone: an indented code block,
# handled entirely separately by process_file's block-level zone state
# machine, which never even calls into per-line prose processing for such
# lines -- see ZONE_INDENT.) $pos is the raw $-[0] of the triggering match,
# which for the dash regexes above may itself point at the optionally-
# captured leading space rather than at the dash character.
sub _at_reparse_start {
    my ($str, $pos) = @_;
    return 0 if $pos > 3;
    return substr($str, 0, $pos) =~ /^\x{0020}*$/;
}

# Never leave a bare "-" immediately followed by a space at a list-marker-
# shaped position (see _at_reparse_start) -- that reparses as CommonMark
# list syntax that did not exist in the source (typography.md section 8,
# edge case 1). Applied to the output of any dash conversion (or the
# bullet conversion, see process_prose_line) that could land at line-start,
# not just the character that happened to be checked first during
# development. The optional leading space in the pattern accounts for the
# dash regexes' own optionally-captured space immediately before the dash:
# when 1-3 spaces precede the dash on the line, only the LAST of them is
# part of this match/replacement (the rest are untouched line prefix), so
# $result itself may start with zero or one space before the hyphen.
sub _apply_line_start_guard {
    my ($result, $at_line_start) = @_;
    if ($at_line_start && $result =~ /^(\x{0020}?)-(\x{0020})/) {
        $result =~ s/^(\x{0020}?)-(\x{0020})/$1\\-$2/;
    }
    return $result;
}

# Shared logic for em dash / horizontal bar / (non-German) spaced en dash.
sub _dash_replacement {
    my ($name, $code, $sb, $ch, $sa, $budget_gated, $at_line_start,
        $budget_ref, $findings_ref, $filename, $lineno) = @_;

    my $spaced = (defined $sb && defined $sa) ? 1 : 0;

    if ($spaced && $budget_gated) {
        if ($$budget_ref < 1) {
            $$budget_ref++;
            return _apply_line_start_guard(($sb // '') . '-' . ($sa // ''), $at_line_start);
        } else {
            push @$findings_ref,
                "$filename:$lineno: $code $name -- more than one mechanical"
              . " ' - ' fallback in this paragraph; left as-is, needs"
              . " function-appropriate resolution (or a human/model pass)";
            # Original character restored, not a hyphen -- no list-marker
            # risk, so no guard needed on this branch.
            return ($sb // '') . $ch . ($sa // '');
        }
    }

    # Tight (unspaced), or not budget-gated: direct 1:1 swap, no budget use.
    return _apply_line_start_guard(($sb // '') . '-' . ($sa // ''), $at_line_start);
}

# ---------------------------------------------------------------------------
# Per-line processing
# ---------------------------------------------------------------------------

sub process_prose_line {
    my ($line, $lang, $budget_ref, $findings_ref, $filename, $lineno) = @_;

    my ($masked, $stash) = mask_line($line, $lang);

    # Invisible characters: deleted, never replaced with a space.
    $masked =~ s/$RE_INVISIBLE//g;

    # Visible-but-exotic whitespace: replaced with a plain ASCII space.
    $masked =~ s/$RE_SPACE_LIKE/ /g;

    # Direct dash swaps (hyphen family + math minus).
    $masked =~ s/$RE_SIMPLE_DASH/-/g;

    # Context-sensitive dashes (en dash, em dash, horizontal bar).
    $masked = resolve_dashes($masked, $lang, $budget_ref, $findings_ref, $filename, $lineno);

    # Quotes.
    $masked =~ s/(\x{2018}|\x{2019}|\x{201C}|\x{201D})/$SIMPLE_QUOTES{$1}/ge;
    $masked =~ s/(\x{201E}|\x{201A})/$LOW_QUOTES{$1}/ge;

    # Ellipsis.
    $masked =~ s/$RE_ELLIPSIS/.../g;

    # Symbols. U+2022 BULLET is the one entry whose ASCII form ('-') has the
    # identical line-start Markdown-list-marker reparse risk as the dashes
    # above (typography.md's own note on this row: "a converted bullet at
    # line start can itself be misread as a Markdown list marker"), so it
    # goes through the same guard; the rest of the table never produces a
    # bare leading '-' and needs no such check. Unlike the dash regexes, the
    # trailing space after a bullet is not part of the match, so the guard
    # is checked against the character immediately following the match
    # (via $+[0]) rather than against the replacement text itself.
    $masked =~ s/($RE_SYMBOLS)/
        my $matched = $1;
        my $repl    = $SYMBOLS{$matched};
        if ($matched eq "\x{2022}" && _at_reparse_start($masked, $-[0])
            && substr($masked, $+[0], 1) eq "\x{0020}") {
            $repl = "\\-";
        }
        $repl;
    /ge;

    return unmask_line($masked, $stash);
}

# Report-only pass used for --check: identical detection, but never mutates
# the returned line, and every codepoint that resolve_dashes/etc. would have
# changed is recorded as a finding instead.
sub scan_prose_line {
    my ($line, $lang, $budget_ref, $findings_ref, $filename, $lineno) = @_;

    my ($masked, undef) = mask_line($line, $lang);

    while ($masked =~ /$RE_INVISIBLE/g) {
        push @$findings_ref, "$filename:$lineno: invisible character -- would be deleted";
    }
    while ($masked =~ /$RE_SPACE_LIKE/g) {
        push @$findings_ref, "$filename:$lineno: exotic space character -- would become ' '";
    }
    while ($masked =~ /$RE_SIMPLE_DASH/g) {
        push @$findings_ref, "$filename:$lineno: dash-family character -- would become '-'";
    }
    # U+201E is included here unconditionally, in German mode too. mask_line
    # (called above, identically in both rewrite and check mode) already
    # hides a genuinely INTACT German pair (U+201E ... U+201C) behind a
    # sentinel before this scan ever runs, so any U+201E still visible in
    # $masked at this point is -- in either language -- an unpaired/dangling
    # low quote that rewrite mode's unconditional %LOW_QUOTES substitution
    # (see process_prose_line) would convert regardless of --lang. A
    # previous version of this check exempted ALL U+201E whenever
    # --lang=de, independent of whether it was actually paired, which made
    # `--check --lang=de` silently report clean on exactly the input
    # rewrite mode would still change -- a real false negative, since both
    # guard.sh and commit-msg only ever call --check.
    while ($masked =~ /(\x{2018}|\x{2019}|\x{201C}|\x{201D}|\x{201A}|\x{201E})/g) {
        push @$findings_ref, "$filename:$lineno: typographic quote -- would become a straight quote";
    }
    while ($masked =~ /$RE_ELLIPSIS/g) {
        push @$findings_ref, "$filename:$lineno: ellipsis character -- would become '...'";
    }
    while ($masked =~ /$RE_SYMBOLS/g) {
        push @$findings_ref, "$filename:$lineno: symbol character -- would become its ASCII form";
    }

    # Dashes needing budget/lang-aware judgement: reuse resolve_dashes
    # against a scratch copy so the paragraph budget really is shared with
    # the (identical) rewrite pass, and diff against the original to find
    # what actually changed (the true "would replace" findings), plus
    # resolve_dashes already pushes over-budget findings directly.
    my $before = $masked;
    my $after  = resolve_dashes($masked, $lang, $budget_ref, $findings_ref, $filename, $lineno);
    if ($after ne $before) {
        push @$findings_ref, "$filename:$lineno: dash character -- would be replaced per typography rules";
    }

    return;
}

# ---------------------------------------------------------------------------
# Block-level zone state machine
# ---------------------------------------------------------------------------

use constant {
    ZONE_NONE       => 'none',
    ZONE_FENCE      => 'fence',
    ZONE_INDENT     => 'indent',
    ZONE_BLOCKQUOTE => 'blockquote',
};

sub process_file {
    my ($filename, $fh, $lang, $check_mode) = @_;

    my @out;
    my @findings;

    my $in_fence     = 0;
    my $fence_marker = '';
    my $fence_len    = 0;

    my $budget = 0;          # mechanical " - " budget for the current paragraph
    my $prev_para_active = 0; # was the previous line part of an active NONE paragraph?

    my $lineno = 0;
    while (my $line = <$fh>) {
        $lineno++;
        chomp(my $bare = $line);

        my $zone;

        if ($in_fence) {
            $zone = ZONE_FENCE;
            if ($bare =~ /^ {0,3}(\Q$fence_marker\E{$fence_len,})\s*$/) {
                $in_fence = 0;
            }
        } elsif ($bare =~ /^ {0,3}(`{3,}|~{3,})/) {
            $zone         = ZONE_FENCE;
            $fence_marker = substr($1, 0, 1);
            $fence_len    = length($1);
            $in_fence     = 1;
        } elsif ($bare =~ /^(?:\x{0020}{4,}|\t)/) {
            $zone = ZONE_INDENT;
        } elsif ($bare =~ /^ {0,3}>/) {
            $zone = ZONE_BLOCKQUOTE;
        } elsif ($bare =~ /^\s*$/) {
            $zone = ZONE_NONE; # blank line; still "processed" but nothing to change
        } else {
            $zone = ZONE_NONE;
        }

        my $is_blank = ($bare =~ /^\s*$/);

        if ($zone eq ZONE_NONE && !$is_blank) {
            $budget = 0 unless $prev_para_active;
            if ($check_mode) {
                scan_prose_line($bare, $lang, \$budget, \@findings, $filename, $lineno);
                push @out, $line;
            } else {
                my $processed = process_prose_line($bare, $lang, \$budget, \@findings, $filename, $lineno);
                push @out, $processed . "\n";
            }
            $prev_para_active = 1;
        } else {
            # Protected zone (fence/indent/blockquote) or a blank line:
            # never touched, and paragraph budget resets.
            push @out, $line;
            $prev_para_active = 0;
        }
    }

    return (\@out, \@findings);
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

my $any_findings = 0;

for my $file (@files) {
    my $fh;
    if ($file eq '-') {
        $fh = \*STDIN;
    } else {
        open($fh, '<:encoding(UTF-8)', $file) or die "detypo.pl: cannot open $file: $!\n";
    }

    my ($out_lines, $findings) = process_file($file, $fh, $lang, $check_mode);
    close($fh) unless $file eq '-';

    if ($check_mode) {
        if (@$findings) {
            $any_findings = 1;
            print "$_\n" for @$findings;
        } else {
            print "$file: no findings\n";
        }
    } else {
        print @$out_lines;
    }
}

exit($check_mode && $any_findings ? 1 : 0);

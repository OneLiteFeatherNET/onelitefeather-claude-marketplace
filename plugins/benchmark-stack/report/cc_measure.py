#!/usr/bin/env python3
"""
cc_measure.py — measure Serena's effect (& co.) in Claude Code.

Parses Claude Code session transcripts (~/.claude/projects/**/*.jsonl) and counts,
per session: API calls (assistant turns), tool calls by category (especially
grep/find/read = "exploration"), Serena usage, and token usage.

Usage:
  # Inspect individual sessions:
  python3 cc_measure.py ~/.claude/projects/<project>/*.jsonl

  # A/B comparison (several runs per group recommended, due to non-determinism):
  python3 cc_measure.py \
      --baseline "runs/baseline/*.jsonl" \
      --serena   "runs/serena/*.jsonl"

Tip: copy the relevant .jsonl into separate folders after each run, or pass the
specific session files directly.
"""
import sys, json, glob, argparse
from collections import defaultdict

# Tool names Claude Code uses for exploration (built-in)
BUILTIN_EXPLORE = {"Read", "Grep", "Glob", "LS"}
# Shell commands that count as search when run via Bash
SHELL_SEARCH = ("grep", "rg ", "find ", "ripgrep", "ag ", "ls -r", "ls -R", "cat ", "head ", "tail ", "sed ", "awk ")


def classify(name, block):
    """Map a tool_use block to a category."""
    if not name:
        return "other"
    low = name.lower()
    if "serena" in low:
        return "serena"
    if name.startswith("mcp__"):
        return "mcp_other"      # e.g. doc layer / claude-context / Outline
    if name in BUILTIN_EXPLORE:
        return "explore_builtin"
    if name == "Bash":
        cmd = ""
        inp = block.get("input") or {}
        if isinstance(inp, dict):
            cmd = (inp.get("command") or "").lower()
        if any(tok in cmd for tok in SHELL_SEARCH):
            return "explore_shell"
        return "bash_other"
    return "other"


def analyze_file(path):
    turns = 0
    tok = defaultdict(int)          # input/output/cache_read/cache_creation
    cats = defaultdict(int)         # category -> tool_use count
    bynames = defaultdict(int)      # exact tool name -> count
    try:
        fh = open(path, encoding="utf-8")
    except OSError:
        return None
    with fh:
        for line in fh:
            line = line.strip()
            if not line:
                continue
            try:
                d = json.loads(line)
            except json.JSONDecodeError:
                continue
            if d.get("type") != "assistant":
                continue
            m = d.get("message") or {}
            turns += 1
            u = m.get("usage") or {}
            tok["input"] += u.get("input_tokens", 0) or 0
            tok["output"] += u.get("output_tokens", 0) or 0
            tok["cache_read"] += u.get("cache_read_input_tokens", 0) or 0
            tok["cache_creation"] += u.get("cache_creation_input_tokens", 0) or 0
            for b in (m.get("content") or []):
                if isinstance(b, dict) and b.get("type") == "tool_use":
                    name = b.get("name")
                    cats[classify(name, b)] += 1
                    bynames[name] += 1
    explore = cats["explore_builtin"] + cats["explore_shell"]
    return {
        "path": path, "turns": turns, "tok": dict(tok),
        "cats": dict(cats), "explore": explore,
        "serena": cats["serena"], "mcp_other": cats["mcp_other"],
        "bynames": dict(bynames),
    }


def fmt(n):
    return f"{n:,}"


def print_session(r):
    t = r["tok"]
    billed_in = t["input"] + t["cache_creation"] + t["cache_read"]
    print(f"  {r['path'].split('/')[-1]}")
    print(f"    API calls (turns):      {r['turns']}")
    print(f"    Exploration (grep/find/read): {r['explore']}   "
          f"(builtin {r['cats'].get('explore_builtin',0)}, shell {r['cats'].get('explore_shell',0)})")
    print(f"    Serena calls:           {r['serena']}")
    print(f"    Other MCP (doc layer):  {r['mcp_other']}")
    print(f"    Tokens  in(uncached) {fmt(t['input'])} | cache_write {fmt(t['cache_creation'])} "
          f"| cache_read {fmt(t['cache_read'])} | out {fmt(t['output'])}")
    print(f"    Tokens  total(billed-in+out): {fmt(billed_in + t['output'])}")


def aggregate(results):
    agg = defaultdict(float)
    for r in results:
        agg["turns"] += r["turns"]
        agg["explore"] += r["explore"]
        agg["serena"] += r["serena"]
        agg["mcp_other"] += r["mcp_other"]
        for k, v in r["tok"].items():
            agg["tok_" + k] += v
    n = len(results) or 1
    return {k: v / n for k, v in agg.items()}, n


def print_group(label, results):
    print(f"\n=== {label}  ({len(results)} session(s)) ===")
    for r in results:
        print_session(r)
    avg, n = aggregate(results)
    print("  --- average per session ---")
    print(f"    API calls:     {avg['turns']:.1f}")
    print(f"    Exploration:   {avg['explore']:.1f}")
    print(f"    Serena calls:  {avg['serena']:.1f}")
    print(f"    Tokens uncached-in: {avg['tok_input']:.0f} | out: {avg['tok_output']:.0f} "
          f"| cache_read: {avg['tok_cache_read']:.0f}")
    return avg


def delta(a, b, key, lower_is_better=True):
    if a.get(key, 0) == 0:
        return "n/a"
    d = (b.get(key, 0) - a.get(key, 0)) / a[key] * 100
    arrow = "↓" if d < 0 else "↑"
    good = (d < 0) == lower_is_better
    tag = "OK" if good else "!!"
    return f"{arrow}{abs(d):.0f}% {tag}"


def expand(patterns):
    out = []
    for p in patterns:
        hits = glob.glob(p)
        out.extend(hits if hits else ([p] if p.endswith(".jsonl") else []))
    return sorted(set(out))


def run(paths):
    res = [analyze_file(p) for p in paths]
    return [r for r in res if r]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("files", nargs="*", help="JSONL session files or globs")
    ap.add_argument("--baseline", action="append", default=[], help="baseline runs (without Serena)")
    ap.add_argument("--serena", action="append", default=[], help="runs WITH Serena/doc layer")
    a = ap.parse_args()

    if a.baseline or a.serena:
        base = run(expand(a.baseline))
        ser = run(expand(a.serena))
        if not base or not ser:
            print("Both groups need at least one session. base=%d serena=%d" % (len(base), len(ser)))
            sys.exit(1)
        ba = print_group("BASELINE (without Serena)", base)
        sa = print_group("WITH Serena (+doc layer)", ser)
        print("\n=== COMPARISON (Serena vs. baseline, lower=better) ===")
        print(f"    API calls:         {delta(ba, sa, 'turns')}")
        print(f"    Exploration calls: {delta(ba, sa, 'explore')}")
        print(f"    Tokens uncached-in:{delta(ba, sa, 'tok_input')}")
        print(f"    Output tokens:     {delta(ba, sa, 'tok_output')}")
        print(f"    Serena used?       baseline {ba['serena']:.1f} -> serena {sa['serena']:.1f} "
              f"{'(OK: Serena is used)' if sa['serena']>0 else '(!! Serena was NOT used — check routing!)'}")
        print("\nNote: LLM runs are non-deterministic — compare averages over several\n"
              "runs (3–5 per group), not single runs. And ALWAYS check whether the\n"
              "result was correct: fewer tokens with a wrong solution does not count.")
    else:
        files = expand(a.files)
        if not files:
            print(__doc__); sys.exit(1)
        print_group("Sessions", run(files))


if __name__ == "__main__":
    main()

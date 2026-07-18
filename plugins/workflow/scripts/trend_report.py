#!/usr/bin/env python3
"""
trend_report.py — trend across the most recent Claude Code sessions.

Shows, per session: exploration calls (grep/find/read), Serena calls, uncached
input and output tokens — chronologically, so it becomes visible whether the
context-layer takes hold in daily work (exploration down, Serena usage up).

Usage:
  python3 trend_report.py [--dir ~/.claude/projects] [--last 15]
"""
import os, sys, json, glob, argparse

BUILTIN_EXPLORE = {"Read", "Grep", "Glob", "LS"}
SHELL_SEARCH = ("grep", "rg ", "find ", "ag ", "ls -r", "ls -R")


def analyze(path):
    turns = 0
    inp = out = 0
    explore = serena = 0
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
            inp += u.get("input_tokens", 0) or 0
            out += u.get("output_tokens", 0) or 0
            for b in (m.get("content") or []):
                if not (isinstance(b, dict) and b.get("type") == "tool_use"):
                    continue
                name = b.get("name") or ""
                if "serena" in name.lower():
                    serena += 1
                elif name in BUILTIN_EXPLORE:
                    explore += 1
                elif name == "Bash":
                    cmd = ((b.get("input") or {}).get("command") or "").lower()
                    if any(t in cmd for t in SHELL_SEARCH):
                        explore += 1
    return {"turns": turns, "in": inp, "out": out,
            "explore": explore, "serena": serena, "mtime": os.path.getmtime(path),
            "name": os.path.basename(path)[:8]}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dir", default=os.path.expanduser("~/.claude/projects"))
    ap.add_argument("--last", type=int, default=15)
    a = ap.parse_args()

    files = glob.glob(os.path.join(a.dir, "**", "*.jsonl"), recursive=True)
    rows = [r for r in (analyze(f) for f in files) if r and r["turns"] > 0]
    rows.sort(key=lambda r: r["mtime"])
    rows = rows[-a.last:]
    if not rows:
        print("No sessions found under", a.dir)
        return

    print(f"{'Session':<9} {'Turns':>6} {'Explore':>8} {'Serena':>7} {'in(unc)':>9} {'out':>8}")
    print("-" * 52)
    for r in rows:
        print(f"{r['name']:<9} {r['turns']:>6} {r['explore']:>8} {r['serena']:>7} "
              f"{r['in']:>9,} {r['out']:>8,}")

    # Trend: first vs. second half
    half = max(1, len(rows) // 2)
    old, new = rows[:half], rows[half:]
    def avg(xs, k): return sum(x[k] for x in xs) / len(xs)
    print("\nTrend (early vs. most recent half, less explore = better):")
    for k, label in [("explore", "Exploration calls"), ("serena", "Serena calls"),
                     ("in", "Uncached input")]:
        o, n = avg(old, k), avg(new, k)
        d = (n - o) / o * 100 if o else 0
        arrow = "↓" if n < o else "↑"
        print(f"  {label:<20} {o:8.0f} -> {n:8.0f}  ({arrow}{abs(d):.0f}%)")
    print("\nNote: Serena calls should rise, exploration & uncached input should fall\n"
          "as the context-layer is adopted in daily work. Check correctness separately.")


if __name__ == "__main__":
    main()

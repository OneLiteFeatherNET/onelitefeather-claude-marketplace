#!/usr/bin/env python3
"""
make_report.py — builds a slide-ready HTML report (with charts) from the OTel
collector's OTLP-JSON file export.

Usage:
  python3 make_report.py [data/metrics.json] [-o report.html]

Compares the conditions (baseline vs serena): total tokens, uncached input,
tokens by type, Serena share, cost — including delta in %.
"""
import sys, os, io, base64, argparse
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from parse_otel import load

BASE = "baseline"
SER = "serena"


def _png(fig):
    buf = io.BytesIO()
    fig.savefig(buf, format="png", dpi=110, bbox_inches="tight")
    plt.close(fig)
    return base64.b64encode(buf.getvalue()).decode()


def _bar(title, labels, series, ylabel="Tokens"):
    fig, ax = plt.subplots(figsize=(6, 3.6))
    colors = ["#8892b0", "#2dd4bf"]
    bars = ax.bar(labels, series, color=colors[:len(labels)])
    ax.set_title(title, fontsize=12, fontweight="bold")
    ax.set_ylabel(ylabel)
    ax.spines[["top", "right"]].set_visible(False)
    for b, v in zip(bars, series):
        ax.text(b.get_x() + b.get_width() / 2, v, f"{v:,.0f}",
                ha="center", va="bottom", fontsize=10)
    return _png(fig)


def _grouped(title, types, base_vals, ser_vals):
    fig, ax = plt.subplots(figsize=(7, 3.8))
    x = range(len(types))
    w = 0.38
    ax.bar([i - w / 2 for i in x], base_vals, w, label="baseline", color="#8892b0")
    ax.bar([i + w / 2 for i in x], ser_vals, w, label="serena", color="#2dd4bf")
    ax.set_xticks(list(x))
    ax.set_xticklabels(types, rotation=0, fontsize=9)
    ax.set_title(title, fontsize=12, fontweight="bold")
    ax.set_ylabel("Tokens")
    ax.spines[["top", "right"]].set_visible(False)
    ax.legend(frameon=False)
    return _png(fig)


def _delta(base, ser):
    if not base:
        return '<span class="na">n/a</span>'
    d = (ser - base) / base * 100
    cls = "good" if d < 0 else "bad"
    arrow = "↓" if d < 0 else "↑"
    return f'<span class="{cls}">{arrow}{abs(d):.0f}%</span>'


def build(agg):
    tbc = agg["tokens_by_cond"]
    cost = agg["cost_by_cond"]
    base_tot, ser_tot = tbc.get(BASE, 0), tbc.get(SER, 0)

    def tt(cond, typ):
        return agg["tokens_by_cond_type"].get(f"{cond}|{typ}", 0)

    types = ["input", "output", "cacheRead", "cacheCreation"]
    base_types = [tt(BASE, t) for t in types]
    ser_types = [tt(SER, t) for t in types]

    # Serena share
    ser_share = agg["tokens_by_cond_server"].get(f"{SER}|serena", 0)

    charts = {
        "total": _bar("Total tokens", ["baseline", "serena"], [base_tot, ser_tot]),
        "input": _bar("Uncached input tokens (cost driver)", ["baseline", "serena"],
                      [tt(BASE, "input"), tt(SER, "input")]),
        "types": _grouped("Tokens by type", types, base_types, ser_types),
    }

    rows = [
        ("Total tokens", base_tot, ser_tot),
        ("Uncached input", tt(BASE, "input"), tt(SER, "input")),
        ("Output", tt(BASE, "output"), tt(SER, "output")),
        ("Cost (USD)", cost.get(BASE, 0), cost.get(SER, 0)),
    ]
    trows = "".join(
        f"<tr><td>{name}</td><td>{b:,.0f}</td><td>{s:,.0f}</td><td>{_delta(b, s)}</td></tr>"
        for name, b, s in rows
    )
    serena_used = "yes" if ser_share > 0 else "NO — check routing!"

    return f"""<!doctype html><html lang="en"><head><meta charset="utf-8">
<title>Serena A/B — Token Report</title>
<style>
 body{{font-family:-apple-system,Segoe UI,Roboto,sans-serif;max-width:900px;margin:2rem auto;padding:0 1rem;color:#0f172a}}
 h1{{font-size:1.6rem}} h2{{font-size:1.1rem;margin-top:2rem;color:#334155}}
 table{{border-collapse:collapse;width:100%;margin:1rem 0}}
 th,td{{padding:.5rem .7rem;text-align:right;border-bottom:1px solid #e2e8f0}}
 th:first-child,td:first-child{{text-align:left}}
 th{{background:#f1f5f9}}
 .good{{color:#059669;font-weight:700}} .bad{{color:#dc2626;font-weight:700}} .na{{color:#94a3b8}}
 .grid{{display:grid;grid-template-columns:1fr 1fr;gap:1rem}}
 img{{width:100%;border:1px solid #e2e8f0;border-radius:8px}}
 .kpi{{font-size:1.05rem;padding:.6rem .9rem;background:#f8fafc;border-radius:8px;border:1px solid #e2e8f0}}
</style></head><body>
<h1>Serena A/B — Token & Cost Report</h1>
<p class="kpi"><b>Serena actually used?</b> {serena_used}
&nbsp;·&nbsp; Total tokens {_delta(base_tot, ser_tot)} &nbsp;·&nbsp;
Uncached input {_delta(tt(BASE,'input'), tt(SER,'input'))}</p>
<h2>Key figures</h2>
<table><thead><tr><th>Metric</th><th>baseline</th><th>serena</th><th>Δ</th></tr></thead>
<tbody>{trows}</tbody></table>
<h2>Charts</h2>
<div class="grid">
 <img src="data:image/png;base64,{charts['total']}">
 <img src="data:image/png;base64,{charts['input']}">
</div>
<img src="data:image/png;base64,{charts['types']}">
<h2>How to read this</h2>
<p>Lower is better (↓ green). The most meaningful value is <b>uncached input</b>
(the real cost driver, not distorted by caching). A win only counts with
<b>unchanged correctness</b> — track the success/failure rate of the runs
separately. Numbers are sums over all included runs/sessions.</p>
</body></html>"""


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("data", nargs="?", default="data/metrics.json")
    ap.add_argument("-o", "--out", default="report.html")
    a = ap.parse_args()
    agg = load(a.data)
    if not agg["conditions"]:
        print("No metrics found. Is the collector running and OTEL_RESOURCE_ATTRIBUTES set?")
        sys.exit(1)
    html = build(agg)
    with open(a.out, "w", encoding="utf-8") as fh:
        fh.write(html)
    print(f"Report written: {a.out}  (conditions: {', '.join(agg['conditions'])})")


if __name__ == "__main__":
    main()

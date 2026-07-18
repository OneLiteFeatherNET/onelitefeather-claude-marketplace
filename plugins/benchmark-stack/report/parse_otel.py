#!/usr/bin/env python3
"""
parse_otel.py — reads the OTel collector's OTLP-JSON file export
(data/metrics.json) and aggregates Claude Code metrics by `condition`
(baseline/serena), token `type` and `mcp_server.name`.

Claude Code metrics:
  claude_code.token.usage  (Sum, cumulative)  attrs: type, model, mcp_server.name, ...
  claude_code.cost.usage   (Sum, cumulative, USD)

Because the file exporter repeatedly writes cumulative counters, we take the MAX
value per unique series (condition + attrs) = the final value.
"""
import json, sys
from collections import defaultdict

TOKEN_METRIC = "claude_code.token.usage"
COST_METRIC = "claude_code.cost.usage"


def _attr_map(attrs):
    """OTLP-JSON attributes[] -> dict{key: value}."""
    out = {}
    for a in attrs or []:
        k = a.get("key")
        v = a.get("value", {})
        val = (v.get("stringValue") if "stringValue" in v else
               v.get("intValue") if "intValue" in v else
               v.get("doubleValue") if "doubleValue" in v else
               v.get("boolValue"))
        out[k] = val
    return out


def _dp_value(dp):
    if "asInt" in dp:
        return float(dp["asInt"])
    if "asDouble" in dp:
        return float(dp["asDouble"])
    return 0.0


def load(path):
    # series[(condition, run, metric, frozenset(attr items))] = max value
    series = {}
    with open(path, encoding="utf-8") as fh:
        for line in fh:
            line = line.strip()
            if not line:
                continue
            try:
                doc = json.loads(line)
            except json.JSONDecodeError:
                continue
            for rm in doc.get("resourceMetrics", []):
                res = _attr_map(rm.get("resource", {}).get("attributes"))
                condition = res.get("condition", "unknown")
                run = res.get("run", "?")
                for sm in rm.get("scopeMetrics", []):
                    for m in sm.get("metrics", []):
                        name = m.get("name")
                        if name not in (TOKEN_METRIC, COST_METRIC):
                            continue
                        dps = (m.get("sum", {}) or m.get("gauge", {})).get("dataPoints", [])
                        for dp in dps:
                            attrs = _attr_map(dp.get("attributes"))
                            key = (condition, run, name,
                                   frozenset(sorted(attrs.items())))
                            val = _dp_value(dp)
                            if key not in series or val > series[key]:
                                series[key] = val
    return _aggregate(series)


def _aggregate(series):
    tokens_by_cond = defaultdict(float)
    tokens_by_cond_type = defaultdict(float)
    tokens_by_cond_server = defaultdict(float)
    cost_by_cond = defaultdict(float)
    conditions = set()
    for (cond, run, name, attrs_fs), val in series.items():
        conditions.add(cond)
        attrs = dict(attrs_fs)
        if name == TOKEN_METRIC:
            tokens_by_cond[cond] += val
            tokens_by_cond_type[(cond, attrs.get("type", "unknown"))] += val
            server = attrs.get("mcp_server.name") or attrs.get("mcp_server_name") or "(built-in)"
            tokens_by_cond_server[(cond, server)] += val
        elif name == COST_METRIC:
            cost_by_cond[cond] += val
    return {
        "conditions": sorted(conditions),
        "tokens_by_cond": dict(tokens_by_cond),
        "tokens_by_cond_type": {f"{k[0]}|{k[1]}": v for k, v in tokens_by_cond_type.items()},
        "tokens_by_cond_server": {f"{k[0]}|{k[1]}": v for k, v in tokens_by_cond_server.items()},
        "cost_by_cond": dict(cost_by_cond),
    }


if __name__ == "__main__":
    path = sys.argv[1] if len(sys.argv) > 1 else "data/metrics.json"
    agg = load(path)
    print(json.dumps(agg, indent=2, ensure_ascii=False))

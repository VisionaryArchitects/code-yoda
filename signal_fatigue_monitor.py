# file: Backend/signal_fatigue_monitor.py
"""Reads council + supervisor logs and emits simple fatigue/drift signals."""
from __future__ import annotations
import json, time
from pathlib import Path
from statistics import mean

COUNCIL = Path("Logs/council.ndjson")
SUPERV  = Path("Logs/supervisor.ndjson")  # ensure supervisor appends to this file per message
OUT     = Path("Logs/fatigue_log.txt")

def tail_lines(p: Path, max_lines: int = 2000):
    if not p.exists():
        return []
    with p.open("r", encoding="utf-8") as f:
        lines = f.readlines()[-max_lines:]
    return [json.loads(x) for x in lines if x.strip()]

while True:
    council = tail_lines(COUNCIL, 2000)
    sup = tail_lines(SUPERV, 2000)

    lat = [x.get("latency_s", 0) for x in council]
    tokens_in = [m.get("tokens_in", 0) for m in sup]
    tokens_out = [m.get("tokens_out", 0) for m in sup]

    report = [
        f"time={time.strftime('%Y-%m-%d %H:%M:%S')}",
        f"council_runs={len(council)} mean_latency={round(mean(lat),3) if lat else 0}",
        f"tokens_in_last={sum(tokens_in[-50:])} tokens_out_last={sum(tokens_out[-50:])}",
    ]
    OUT.write_text("\n".join(report))
    time.sleep(15)
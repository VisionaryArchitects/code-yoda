# file: Backend/council_supervisor.py
from __future__ import annotations
import time, uuid, json
from pathlib import Path
from typing import Any, Dict

from fastapi import FastAPI, Body
from pydantic import BaseModel
import uvicorn
import requests

LOG = Path("Logs/council.ndjson"); LOG.parent.mkdir(parents=True, exist_ok=True)
SUP = "http://127.0.0.1:8765"

app = FastAPI(title="Council Proxy", version="1.0.0")

class AskIn(BaseModel):
    prompt: str
    config_path: str | None = None

class RunIn(BaseModel):
    user_input: str
    config_path: str | None = None

@app.post("/council/ask")
def council_ask(payload: AskIn):
    t0 = time.time(); rid = uuid.uuid4().hex
    r = requests.post(f"{SUP}/run", json={"user_input": payload.prompt, "config_path": payload.config_path})
    data = r.json()
    rec = {"ts": time.time(), "run_id": data.get("run_id", rid), "phase": "ask", "prompt": payload.prompt, "latency_s": round(time.time()-t0,3)}
    LOG.write_text(LOG.read_text()+json.dumps(rec)+"\n" if LOG.exists() else json.dumps(rec)+"\n")
    return data

@app.post("/council/run")
def council_run(payload: RunIn):
    t0 = time.time(); rid = uuid.uuid4().hex
    r = requests.post(f"{SUP}/run", json={"user_input": payload.user_input, "config_path": payload.config_path})
    data = r.json()
    rec = {"ts": time.time(), "run_id": data.get("run_id", rid), "phase": "run", "input": payload.user_input, "latency_s": round(time.time()-t0,3)}
    LOG.write_text(LOG.read_text()+json.dumps(rec)+"\n" if LOG.exists() else json.dumps(rec)+"\n")
    return data

if __name__ == "__main__":
    uvicorn.run("council_supervisor:app", host="127.0.0.1", port=8770)
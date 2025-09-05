#!/usr/bin/env bash
# Fresh WSL2 bootstrap for RTX 4090 workflows (vLLM-first), TitleCase paths.
# Run inside WSL Ubuntu:  bash /mnt/d/Projects/LLM/Tools/wsl_bootstrap.sh
set -euo pipefail

ROOT="/mnt/d/Projects/LLM"
ENVS="$ROOT/Envs"
REPOS="$ROOT/Repos"
TOOLS="$ROOT/Tools"
MODELS_HF="$ROOT/Models/HF"
LOGS="$ROOT/Logs"

mkdir -p "$ENVS" "$REPOS" "$TOOLS" "$MODELS_HF" "$LOGS"

banner(){ echo -e "\n\e[1;35m[WSL]\e[0m $1"; }
need(){ command -v "$1" >/dev/null 2>&1 || { echo "Missing $1"; exit 1; } }

banner "Update apt & install basics"
sudo apt update
sudo apt install -y python3-venv python3-pip git curl build-essential pkg-config \
                    libgl1 libglib2.0-0 ffmpeg

banner "Check GPU visibility"
if ! command -v nvidia-smi >/dev/null 2>&1; then
  echo "nvidia-smi not present in WSL — ensure Windows has the CUDA-enabled driver installed.";
else
  nvidia-smi | head -n 3
fi

banner "Create Python venv + deps"
VENV="$ENVS/LinuxMain"
python3 -m venv "$VENV"
source "$VENV/bin/activate"
python -m pip install --upgrade pip wheel

# vLLM + helpers (OpenAI-compatible server)
pip install vllm fastapi "uvicorn[standard]" requests tavily-python trafilatura

# Optional: Playwright for JS-heavy pages (headless Chromium)
if python -c "import sys" >/dev/null 2>&1; then
  pip install playwright || true
  playwright install --with-deps chromium || true
fi

# Optional: Unstructured & Chroma (heavy)
# pip install unstructured[all-docs] chromadb sentence-transformers

banner "Env vars (HF cache)"
export HF_HOME="$MODELS_HF"
export TRANSFORMERS_CACHE="$MODELS_HF/transformers"

cat <<EOF

[WSL] Quickstart vLLM (example):
  export HF_HOME=$MODELS_HF
  export TRANSFORMERS_CACHE=$MODELS_HF/transformers
  python -m vllm.entrypoints.openai.api_server \
    --model meta-llama/Meta-Llama-3-8B-Instruct \
    --dtype auto --max-model-len 8192 --gpu-memory-utilization 0.95

Then point Supervisor agent llm.api_base to:  http://127.0.0.1:8000/v1

Tip: use tmux/screen to keep the server running.
EOF
param([string]$Root='D:\Projects\LLM',[string]$ApiKey='change-me')
$ErrorActionPreference='Stop'
function New-Folder($p){ if(-not(Test-Path $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null } }

Write-Host "[Deploy] Target: $Root" -ForegroundColor Cyan
$dirs=@('Envs','Models\HF','Models\GGUF','Models\TRTLLM','Data','Repos','Tools','Logs','Configs','Public\mobile','Dashboard')
foreach($d in $dirs){ New-Folder (Join-Path $Root $d) }
[Environment]::SetEnvironmentVariable('HF_HOME', (Join-Path $Root 'Models/HF'), 'User')
[Environment]::SetEnvironmentVariable('TRANSFORMERS_CACHE', (Join-Path $Root 'Models/HF/transformers'), 'User')
[Environment]::SetEnvironmentVariable('VLLM_WORKDIR', (Join-Path $Root 'Tools/VLLM'), 'User')

# Python env
if(-not(Get-Command python -ErrorAction SilentlyContinue)){ throw 'Install Python 3.10+ first' }
$venv=Join-Path $Root 'Envs/Main'
if(-not(Test-Path $venv)){ python -m venv $venv }
. "$venv\Scripts\Activate.ps1"
python -m pip install --upgrade pip wheel
pip install fastapi "uvicorn[standard]" pyyaml typer crewai langgraph langchain-core chromadb sentence-transformers requests tavily-python trafilatura

# Copy configs if present in current folder
if(Test-Path '.\Configs'){ Copy-Item .\Configs\* -Destination (Join-Path $Root 'Configs') -Recurse -Force }
$env:ANGELOS_API_KEY=$ApiKey

# Start services if backend exists
$backend=Join-Path $Root 'Backend'
if(Test-Path (Join-Path $backend 'supervisor.py')){
  Start-Process -NoNewWindow python -ArgumentList "-m","uvicorn","supervisor:app","--host","127.0.0.1","--port","8765" -WorkingDirectory $backend
}
if(Test-Path (Join-Path $backend 'supervisor_mobile.py')){
  Start-Process -NoNewWindow python -ArgumentList "-m","uvicorn","supervisor_mobile:app","--host","127.0.0.1","--port","8766" -WorkingDirectory $backend
}
Write-Host "[Deploy] Done. Health: http://127.0.0.1:8765/health  Mobile: http://127.0.0.1:8766/mobile"
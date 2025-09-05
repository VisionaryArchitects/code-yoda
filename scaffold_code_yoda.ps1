# file: D:\Projects\LLM\Scripts\scaffold_code_yoda.ps1
</head>
<body>
<h1>Code Yoda</h1>
<input id="q" size="40" placeholder="Type a prompt"/>
<button id="go">Run</button>
<div class="out" id="out"></div>
<script>
const api = 'http://127.0.0.1:8765/run';
const q = document.getElementById('q');
const out = document.getElementById('out');
document.getElementById('go').onclick = async () => {
const r = await fetch(api, {method:'POST', headers:{'Content-Type':'application/json'}, body: JSON.stringify({user_input: q.value})});
const j = await r.json();
out.textContent = j.reply || JSON.stringify(j, null, 2);
};
</script>
</body></html>
'@
Set-Content -Path (Join-Path $Root 'Public/mobile/index.html') -Value $mobile_html -Encoding UTF8


# Scripts/smoke_test.ps1
$smoke = @'
$ErrorActionPreference='''Stop''
function Check($name,$ok){ if($ok){ Write-Host "[OK] $name" -ForegroundColor Green } else { Write-Host "[FAIL] $name" -ForegroundColor Red; exit 1 } }
try{ $h=(Invoke-WebRequest http://127.0.0.1:8765/health -UseBasicParsing).Content; Check 'Supervisor /health' ($h.Length -gt 0) }catch{ Check 'Supervisor /health' $false }
try{ $t=Invoke-WebRequest -Uri http://127.0.0.1:8765/agents/test -Method POST -ContentType 'application/json' -Body '{}' -UseBasicParsing; Check 'Agents test' ($t.StatusCode -eq 200) }catch{ Check 'Agents test' $false }
Write-Host 'All green.'
'@
Set-Content -Path (Join-Path $Root 'Scripts/smoke_test.ps1') -Value $smoke -Encoding UTF8


# Requirements (Python)
$req = @'
fastapi
uvicorn[standard]
pydantic
pyyaml
typer
'@
Set-Content -Path (Join-Path $Root 'Backend/requirements.txt') -Value $req -Encoding UTF8


# -------- Deps & Boot --------
if($InstallDeps){
if(-not(Get-Command python -ErrorAction SilentlyContinue)){ throw 'Install Python 3.10+ first' }
$venv = Join-Path $Root 'Envs/Main'
if(-not(Test-Path $venv)){ python -m venv $venv }
. "$venv\Scripts\Activate.ps1"
python -m pip install --upgrade pip wheel
pip install -r (Join-Path $Root 'Backend/requirements.txt')
}


if($Boot){
Start-Process -NoNewWindow python -ArgumentList "-m","uvicorn","supervisor:app","--host","127.0.0.1","--port","8765" -WorkingDirectory (Join-Path $Root 'Backend')
Start-Process -NoNewWindow python -ArgumentList "-m","uvicorn","supervisor_mobile:app","--host","127.0.0.1","--port","8766" -WorkingDirectory (Join-Path $Root 'Backend')
Write-Host "[Scaffold] Supervisor: http://127.0.0.1:8765/health" -ForegroundColor Yellow
Write-Host "[Scaffold] Mobile UI: http://127.0.0.1:8766/mobile" -ForegroundColor Yellow
}
'```


---


## 1) How to run
```powershell
# 🔴 EDIT ME → only once per machine
Set-ExecutionPolicy Bypass -Scope Process -Force


# 🟢 SAFE — scaffold, install, boot
D:\Projects\LLM\Scripts\scaffold_code_yoda.ps1 -Root 'D:\Projects\LLM' -InstallDeps -Boot


# Test
D:\Projects\LLM\Scripts\smoke_test.ps1
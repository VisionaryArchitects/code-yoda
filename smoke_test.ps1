$ErrorActionPreference='Stop'
function Check($name,$ok){ if($ok){ Write-Host "[OK] $name" -ForegroundColor Green } else { Write-Host "[FAIL] $name" -ForegroundColor Red; exit 1 } }

# GPU
try{ $gpu=(nvidia-smi) ; Check 'nvidia-smi' ($gpu -ne $null) }catch{ Check 'nvidia-smi' $false }
# Supervisor
try{ $h=(Invoke-WebRequest http://127.0.0.1:8765/health -UseBasicParsing).Content; Check 'Supervisor /health' ($h.Length -gt 0) }catch{ Check 'Supervisor /health' $false }
# Agents test
try{ $t=Invoke-WebRequest -Uri http://127.0.0.1:8765/agents/test -Method POST -ContentType 'application/json' -Body '{}' -UseBasicParsing; Check 'Agents test' ($t.StatusCode -eq 200) }catch{ Check 'Agents test' $false }
# End-to-end run
try{ $body='{"user_input":"Summarize: what is our system?"}'; $r=Invoke-WebRequest -Uri http://127.0.0.1:8765/run -Method POST -ContentType 'application/json' -Body $body -UseBasicParsing; Check 'Run' ($r.StatusCode -eq 200) }catch{ Check 'Run' $false }
Write-Host "All green."
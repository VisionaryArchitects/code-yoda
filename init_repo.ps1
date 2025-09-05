param([string]$RepoName='code-yoda-stack', [string]$Remote='origin')
if(-not(Get-Command git -ErrorAction SilentlyContinue)){ throw 'Install Git first' }

git init
git add .
git commit -m "feat: initial stack"
Write-Host "Create a private repo named $RepoName on GitHub, then paste its URL:" -ForegroundColor Cyan
$url=Read-Host 'Remote URL'
git remote add $Remote $url
git branch -M main
git push -u $Remote main
Write-Host "Done. Set GH_TOKEN in your secrets to use the release workflow."
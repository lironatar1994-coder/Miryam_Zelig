param (
    [string]$CommitMessage = "",
    [string]$RepoUrl = "https://github.com/lironatar1994-coder/Miryam_Zelig.git",
    [string]$Branch = "main",
    [string]$SSHHost = "root@vee-app.co.il",
    [string]$RemoteDir = "/root/Miryam_Zelig"
)

$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ProjectRoot

Write-Host "--- Starting Miryam Zelig Static Site Deployment ---" -ForegroundColor Cyan

if (-not (Test-Path ".\index.html")) {
    throw "index.html was not found in $ProjectRoot"
}

Write-Host "Checking server connectivity..." -ForegroundColor Gray
if (-not (Test-Connection -ComputerName "vee-app.co.il" -Count 1 -Quiet)) {
    throw "Could not ping vee-app.co.il"
}

if (-not (Test-Path ".\.git")) {
    Write-Host "Initializing local git repository..." -ForegroundColor Gray
    git init
}

git branch -M $Branch

$hasOrigin = (git remote) -contains "origin"
if (-not $hasOrigin) {
    git remote add origin $RepoUrl
}
else {
    $origin = git remote get-url origin
    if ($origin -ne $RepoUrl) {
    git remote set-url origin $RepoUrl
    }
}

$status = git status --porcelain
$branchStatus = git status --short --branch
$hasCommit = -not (($branchStatus -join "`n") -match "No commits yet")

if ($status -or -not $hasCommit) {
    $Message = $CommitMessage
    if (-not $Message) {
        $Message = Read-Host "Changes detected. Enter commit message"
    }
    if (-not $Message) {
        $Message = "Deploy Miryam Zelig static site"
    }

    Write-Host "Staging and committing changes..." -ForegroundColor Gray
    git add index.html deploy.ps1 deploy_linux.sh README.md .gitignore .gitattributes gallery miryam.jpeg
    git commit -m "$Message"
}
else {
    Write-Host "No local changes to commit." -ForegroundColor Gray
}

Write-Host "Pushing to GitHub..." -ForegroundColor Gray
git push -u origin $Branch
if ($LASTEXITCODE -ne 0) {
    throw "Git push failed. Remote deployment was not started."
}

Write-Host "Ensuring remote checkout exists..." -ForegroundColor Blue
$cloneCmd = "if [ ! -d '$RemoteDir/.git' ]; then rm -rf '$RemoteDir' && git clone '$RepoUrl' '$RemoteDir'; fi"
ssh $SSHHost $cloneCmd
if ($LASTEXITCODE -ne 0) {
    throw "Remote clone/setup failed"
}

Write-Host "Connecting to server and triggering remote deploy..." -ForegroundColor Blue
$remoteCmd = "cd '$RemoteDir' && chmod +x deploy_linux.sh && ./deploy_linux.sh"
ssh $SSHHost $remoteCmd

if ($LASTEXITCODE -ne 0) {
    Write-Host "`n[!] DEPLOYMENT FAILED" -ForegroundColor Red
    exit $LASTEXITCODE
}

Write-Host "`n================================================" -ForegroundColor Green
Write-Host "      DEPLOYMENT COMPLETE SUCCESSFULLY" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green

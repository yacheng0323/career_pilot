# ============================================================
# dev.ps1 - Career Pilot local dev launcher
# Starts FastAPI backend + Flutter app simultaneously
#
# Usage:
#   .\dev.ps1                    # default: Android emulator
#   .\dev.ps1 -Target ios        # iOS simulator
#   .\dev.ps1 -Target web        # Flutter Web
#   .\dev.ps1 -Target windows    # Flutter Windows Desktop
#   .\dev.ps1 -BackendOnly       # backend only
#   .\dev.ps1 -FlutterOnly       # Flutter only (backend already running)
# ============================================================

param(
    [ValidateSet("android", "ios", "web", "windows")]
    [string]$Target = "android",

    [switch]$BackendOnly,
    [switch]$FlutterOnly,

    [string]$FlutterPath = "D:\flutter\bin",
    [int]$BackendPort = 8000
)

$ErrorActionPreference = "Stop"
$ROOT = $PSScriptRoot

function Write-Step { param($msg) Write-Host "`n>> $msg" -ForegroundColor Cyan }
function Write-OK   { param($msg) Write-Host "OK $msg"  -ForegroundColor Green }
function Write-Warn { param($msg) Write-Host "!! $msg"  -ForegroundColor Yellow }
function Write-Fail { param($msg) Write-Host "XX $msg"  -ForegroundColor Red }

# API_BASE_URL based on target
$ApiBaseUrl = switch ($Target) {
    "android" { "http://10.0.2.2:$BackendPort" }
    default   { "http://localhost:$BackendPort" }
}

# Paths
$BackendDir  = Join-Path $ROOT "backend"
$VenvPython  = Join-Path $BackendDir ".venv\Scripts\python.exe"
$VenvPip     = Join-Path $BackendDir ".venv\Scripts\pip.exe"
$ReqFile     = Join-Path $BackendDir "requirements-dev.txt"

# Validate backend dir
if (-not $FlutterOnly) {
    if (-not (Test-Path $BackendDir)) {
        Write-Fail "backend/ directory not found: $BackendDir"
        exit 1
    }
    if (-not (Test-Path $VenvPython)) {
        Write-Warn "venv not found, creating..."
        Write-Step "Creating Python venv"
        python -m venv (Join-Path $BackendDir ".venv")
        & $VenvPip install -r $ReqFile | Out-Null
        Write-OK "venv created"
    }
}

# Validate flutter
if (-not $BackendOnly) {
    $env:PATH = "$FlutterPath;$env:PATH"
    if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
        Write-Fail "flutter not found. Check FlutterPath: $FlutterPath"
        exit 1
    }
}

# ── Start Backend ──────────────────────────────────────────
$BackendProcess = $null

if (-not $FlutterOnly) {
    Write-Step "Starting FastAPI backend on port $BackendPort ..."

    $BackendProcess = Start-Process `
        -FilePath $VenvPython `
        -ArgumentList "-m uvicorn backend.main:app --port $BackendPort --reload" `
        -WorkingDirectory $ROOT `
        -PassThru `
        -NoNewWindow

    # Wait up to 15s for backend to be ready
    $ready = $false
    for ($i = 1; $i -le 15; $i++) {
        Start-Sleep -Seconds 1
        try {
            $r = Invoke-WebRequest "http://localhost:$BackendPort/health" `
                     -TimeoutSec 2 -UseBasicParsing -ErrorAction Stop
            if ($r.StatusCode -eq 200) { $ready = $true; break }
        } catch { }
        Write-Host "  waiting for backend... ($i/15)" -ForegroundColor DarkGray
    }

    if ($ready) {
        Write-OK "Backend ready : http://localhost:$BackendPort"
        Write-OK "API Docs      : http://localhost:$BackendPort/docs"
    } else {
        Write-Warn "Backend did not respond in 15s - Flutter will use mock fallback"
    }

    if ($BackendOnly) {
        Write-Host "`nBackend running. Press Ctrl+C to stop." -ForegroundColor Green
        try { $BackendProcess.WaitForExit() } finally { }
        exit 0
    }
}

# ── Start Flutter ──────────────────────────────────────────
Write-Step "Starting Flutter ($Target) ..."
Write-Host "  API_BASE_URL = $ApiBaseUrl" -ForegroundColor DarkGray

$flutterArgs = @(
    "run",
    "--dart-define=API_BASE_URL=$ApiBaseUrl",
    "--dart-define=CLAUDE_API_KEY="
)

if ($Target -ne "android" -and $Target -ne "ios") {
    $flutterArgs += "-d"
    $flutterArgs += $Target
}

Write-Host ""
Write-Host "========================================" -ForegroundColor DarkCyan
Write-Host " Career Pilot Dev"                        -ForegroundColor Cyan
Write-Host " Backend : http://localhost:$BackendPort" -ForegroundColor DarkCyan
Write-Host " Flutter : $Target  ($ApiBaseUrl)"        -ForegroundColor DarkCyan
Write-Host " Press q to quit Flutter"                 -ForegroundColor DarkGray
Write-Host "========================================" -ForegroundColor DarkCyan
Write-Host ""

try {
    & flutter @flutterArgs
} finally {
    if ($BackendProcess -and -not $BackendProcess.HasExited) {
        Write-Step "Stopping backend..."
        Stop-Process -Id $BackendProcess.Id -Force -ErrorAction SilentlyContinue
        Write-OK "Backend stopped"
    }
}
# Child Safety Monitor startup script
$logDir = Join-Path -Path $env:USERPROFILE -ChildPath 'screen_capture_logs'
if (-not (Test-Path -Path $logDir)) {
    New-Item -Path $logDir -ItemType Directory -Force | Out-Null
}
$logFile = Join-Path -Path $logDir -ChildPath 'startup_log.txt'
Add-Content -Path $logFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Child Safety Monitor started"

# Determine script directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Run the simple capture script that won't be blocked
$simplePath = Join-Path -Path $scriptDir -ChildPath "ScreenCaptureSimple.ps1"

if (Test-Path -Path $simplePath) {
    Add-Content -Path $logFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Starting ScreenCaptureSimple.ps1"
    & $simplePath
} else {
    Add-Content -Path $logFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] ERROR: Script not found: ScreenCaptureSimple.ps1"
}

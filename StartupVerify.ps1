# Startup verification script
$logDir = Join-Path -Path $env:USERPROFILE -ChildPath 'screen_capture_logs'
if (-not (Test-Path -Path $logDir)) {
    New-Item -Path $logDir -ItemType Directory -Force | Out-Null
}
$logFile = Join-Path -Path $logDir -ChildPath 'startup_log.txt'
Add-Content -Path $logFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Screen capture startup initiated"

# Determine script directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Use the simple screen capture method
$simplePath = Join-Path -Path $scriptDir -ChildPath "ScreenCaptureSimple.ps1"

# Log our action
Add-Content -Path $logFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Starting child safety monitoring"

# Run the simple version
if (Test-Path -Path $simplePath) {
    Add-Content -Path $logFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Running ScreenCaptureSimple.ps1"
    & $simplePath
} else {
    Add-Content -Path $logFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] ERROR: ScreenCaptureSimple.ps1 not found"
}


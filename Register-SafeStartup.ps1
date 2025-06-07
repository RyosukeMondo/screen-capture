#Requires -Version 5.1
<#
.SYNOPSIS
    Registers the child safety screen capture tool to run at startup
.DESCRIPTION
    Creates a shortcut in the Windows Startup folder to run the simplified screen
    capture script whenever the user logs in
#>

# Define parameters and paths
$scriptName = "ScreenCaptureSimple.ps1"
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath $scriptName
$verifyScriptName = "SafeStartup.ps1" 
$verifyScriptPath = Join-Path -Path $PSScriptRoot -ChildPath $verifyScriptName

# Get the Windows Startup folder path
$startupFolder = [Environment]::GetFolderPath('Startup')
$shortcutPath = Join-Path -Path $startupFolder -ChildPath "ChildSafetyMonitor.lnk"

# Display header
Write-Host "Child Safety Monitor Setup" -ForegroundColor Cyan
Write-Host "==========================" -ForegroundColor Cyan
Write-Host "Creating startup shortcut in: $startupFolder" -ForegroundColor Yellow
Write-Host ""

# Check if the script exists
if (-not (Test-Path -Path $scriptPath)) {
    Write-Host "Error: Script not found at $scriptPath" -ForegroundColor Red
    Write-Host "Please make sure the script exists before running this registration tool."
    exit 1
}

# Remove existing shortcut if it exists
if (Test-Path -Path $shortcutPath) {
    Remove-Item -Path $shortcutPath -Force
    Write-Host "Removed existing startup shortcut." -ForegroundColor Yellow
    Write-Host ""
}

# Create a verification script to help with startup troubleshooting
$verifyScriptContent = @"
# Child Safety Monitor startup script
`$logDir = Join-Path -Path `$env:USERPROFILE -ChildPath 'screen_capture_logs'
if (-not (Test-Path -Path `$logDir)) {
    New-Item -Path `$logDir -ItemType Directory -Force | Out-Null
}
`$logFile = Join-Path -Path `$logDir -ChildPath 'startup_log.txt'
Add-Content -Path `$logFile -Value "[`$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Child Safety Monitor started"

# Determine script directory
`$scriptDir = Split-Path -Parent `$MyInvocation.MyCommand.Path

# Run the simple capture script that won't be blocked
`$simplePath = Join-Path -Path `$scriptDir -ChildPath "$scriptName"

if (Test-Path -Path `$simplePath) {
    Add-Content -Path `$logFile -Value "[`$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Starting $scriptName"
    & `$simplePath
} else {
    Add-Content -Path `$logFile -Value "[`$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] ERROR: Script not found: $scriptName"
}
"@

# Write the verification script
Set-Content -Path $verifyScriptPath -Value $verifyScriptContent
Write-Host "Created startup helper script: $verifyScriptPath" -ForegroundColor Green

# Create a shortcut in the Startup folder
try {
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = "powershell.exe"
    $shortcut.Arguments = "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$verifyScriptPath`""
    $shortcut.WorkingDirectory = $PSScriptRoot
    $shortcut.Description = "Child Safety Monitor"
    $shortcut.Save()
    
    Write-Host "Startup item successfully registered." -ForegroundColor Green
    Write-Host "The child safety monitor will start automatically when you log on."
    Write-Host ""
}
catch {
    Write-Host "Error creating startup shortcut: $_" -ForegroundColor Red
    exit 1
}

# Ask if user wants to start the capture now
$startNow = Read-Host -Prompt "Do you want to start the child safety monitoring now? (Y/N)"
if ($startNow -eq "Y" -or $startNow -eq "y") {
    Write-Host "Starting child safety monitoring..." -ForegroundColor Cyan
    Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File `"$scriptPath`"" -NoNewWindow
}

Write-Host "`nSetup complete. Screenshots will be saved to: $env:USERPROFILE\screen_capture" -ForegroundColor Green
Write-Host "Log files are stored at: $env:USERPROFILE\screen_capture_logs" -ForegroundColor Green

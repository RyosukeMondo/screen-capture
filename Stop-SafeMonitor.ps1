#Requires -Version 5.1
<#
.SYNOPSIS
    Stops the child safety monitoring and removes it from startup
.DESCRIPTION
    Terminates any running screen capture processes and removes
    the startup shortcut to prevent future automatic execution
#>

Write-Host "Child Safety Monitor - Stop Script" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan

# Step 1: Find and stop any running screen capture processes
Write-Host "Stopping any running capture processes..." -ForegroundColor Yellow
$stoppedCount = 0
$processes = @()
$monitoringScripts = @(
    "ScreenCaptureSimple.ps1", 
    "SafeStartup.ps1", 
    "StartupVerify.ps1"
)

# Method 1: Try using WMI/CIM which provides more complete command line info
try {
    Write-Host "Checking for processes using WMI method..." -ForegroundColor Yellow
    
    # Get all PowerShell processes with their command lines
    $wmiProcesses = Get-CimInstance Win32_Process -Filter "name = 'powershell.exe'" -ErrorAction Stop
    
    # Filter for our monitoring scripts
    $wmiMatches = @()
    foreach ($proc in $wmiProcesses) {
        foreach ($script in $monitoringScripts) {
            if ($proc.CommandLine -like "*$script*") {
                $wmiMatches += $proc
                break
            }
        }
    }
    
    $processes += $wmiMatches
    Write-Host "Found $($wmiMatches.Count) monitoring processes using WMI method." -ForegroundColor Yellow
}
catch {
    $errorMsg = $_.Exception.Message
    Write-Host "WMI method failed: $errorMsg" -ForegroundColor Yellow
}

# Method 2: Use standard Get-Process as a backup
try {
    Write-Host "Checking for processes using standard method..." -ForegroundColor Yellow
    $stdProcesses = @(Get-Process -Name powershell -ErrorAction SilentlyContinue)
    $stdMatches = @()
    
    foreach ($proc in $stdProcesses) {
        # Skip if we can't get command line (might need elevation)
        if (-not $proc.CommandLine) { continue }
        
        foreach ($script in $monitoringScripts) {
            if ($proc.CommandLine -like "*$script*") {
                # Skip if we already found this process via WMI
                if ($processes | Where-Object { $_.Id -eq $proc.Id }) {
                    continue
                }
                $stdMatches += $proc
                break
            }
        }
    }
    
    $processes += $stdMatches
    Write-Host "Found $($stdMatches.Count) additional monitoring processes using standard method." -ForegroundColor Yellow
}
catch {
    $errorMsg = $_.Exception.Message
    Write-Host "Standard process check failed: $errorMsg" -ForegroundColor Yellow
}

# Method 3: Use Get-WmiObject as a last resort (different API)
try {
    Write-Host "Performing final check with Get-WmiObject..." -ForegroundColor Yellow
    $wmiObjProcesses = @(Get-WmiObject Win32_Process | Where-Object { $_.Name -eq 'powershell.exe' })
    $wmiObjMatches = @()
    
    foreach ($proc in $wmiObjProcesses) {
        $cmdLine = $proc.CommandLine
        if (-not $cmdLine) { continue }
        
        foreach ($script in $monitoringScripts) {
            if ($cmdLine -like "*$script*") {
                # Skip if we already found this process
                if ($processes | Where-Object { $_.ProcessId -eq $proc.ProcessId -or $_.Id -eq $proc.ProcessId }) {
                    continue
                }
                $wmiObjMatches += $proc
                break
            }
        }
    }
    
    $processes += $wmiObjMatches
    Write-Host "Found $($wmiObjMatches.Count) additional monitoring processes using WmiObject method." -ForegroundColor Yellow
}
catch {
    $errorMsg = $_.Exception.Message
    Write-Host "WmiObject process check failed: $errorMsg" -ForegroundColor Yellow
}

# Report total processes found
Write-Host "Total monitoring processes found: $($processes.Count)" -ForegroundColor Yellow

# Stop each discovered process
foreach ($process in $processes) {
    try {
        # Handle different process object types (WMI/CimInstance vs Process vs WmiObject)
        $processId = if ($process.ProcessId) { $process.ProcessId } else { $process.Id }
        $processType = $process.GetType().Name
        
        # Log the process we're stopping
        Write-Host "Stopping process ID: $processId (Type: $processType)" -ForegroundColor Yellow
        
        # Use appropriate termination method based on object type
        switch ($processType) {
            'CimInstance' {
                $process | Invoke-CimMethod -MethodName Terminate -ErrorAction Stop | Out-Null
            }
            'ManagementObject' {
                $process.Terminate() | Out-Null
            }
            default {
                $process | Stop-Process -Force -ErrorAction Stop
            }
        }
        
        $stoppedCount++
        Write-Host "Successfully stopped process ID: $processId" -ForegroundColor Green
    }
    catch {
        $errorMsg = $_.Exception.Message
        Write-Host "Failed to stop process $processId`: $errorMsg" -ForegroundColor Red
    }
}

# Report results
if ($stoppedCount -gt 0) {
    Write-Host "Stopped a total of $stoppedCount capture processes." -ForegroundColor Green
}
else {
    Write-Host "No running capture processes found." -ForegroundColor Yellow
}

# Step 2: Remove the startup shortcut
$startupFolder = [Environment]::GetFolderPath('Startup')
$shortcutPath = Join-Path -Path $startupFolder -ChildPath "ChildSafetyMonitor.lnk"

if (Test-Path -Path $shortcutPath) {
    try {
        Remove-Item -Path $shortcutPath -Force
        Write-Host "Removed startup shortcut. Child safety monitoring will not start automatically." -ForegroundColor Green
    }
    catch {
        $errorMsg = $_.Exception.Message
        Write-Host "Failed to remove startup shortcut: $errorMsg" -ForegroundColor Red
    }
}
else {
    Write-Host "No startup shortcut found." -ForegroundColor Yellow
}

# Final summary
Write-Host "`nSummary:" -ForegroundColor Cyan
Write-Host "-------" -ForegroundColor Cyan
Write-Host "Total processes stopped: $stoppedCount" -ForegroundColor Green
if (Test-Path -Path $shortcutPath) {
    Write-Host "Startup shortcut removal: Failed" -ForegroundColor Red
} else {
    Write-Host "Startup shortcut removal: Success" -ForegroundColor Green
}

Write-Host "`nChild safety monitoring has been stopped." -ForegroundColor Green
Write-Host "To start monitoring again, run Register-SafeStartup.ps1" -ForegroundColor Cyan

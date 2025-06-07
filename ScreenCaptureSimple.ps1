#Requires -Version 5.1
<#
.SYNOPSIS
    Simple and reliable screen capture script for child safety monitoring
.DESCRIPTION
    Creates screenshots at regular intervals and stores them in the user profile
    directory, with minimal dependencies to avoid security software blocking
#>

param (
    [Parameter(Mandatory=$false)]
    [switch]$RunOnce,
    
    [Parameter(Mandatory=$false)]
    [switch]$CleanOnly,
    
    [Parameter(Mandatory=$false)]
    [switch]$PrimaryOnly,
    
    [Parameter(Mandatory=$false)]
    [switch]$ListScreens
)

# Initialize logging
function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet('Info', 'Warning', 'Error')]
        [string]$Level = 'Info'
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    # Write to console with color based on level
    switch ($Level) {
        'Info' { Write-Host $logMessage -ForegroundColor Gray }
        'Warning' { Write-Host $logMessage -ForegroundColor Yellow }
        'Error' { Write-Host $logMessage -ForegroundColor Red }
        default { Write-Host $logMessage -ForegroundColor Gray }
    }
    
    try {
        # Create log file path in user profile
        $logDirectory = Join-Path -Path $env:USERPROFILE -ChildPath 'screen_capture_logs'
        $logFile = Join-Path -Path $logDirectory -ChildPath "screencapture_$(Get-Date -Format 'yyyyMMdd').log"
        
        # Ensure log directory exists
        if (-not (Test-Path -Path $logDirectory)) {
            New-Item -ItemType Directory -Path $logDirectory -Force | Out-Null
        }
        
        # Write to log file
        Add-Content -Path $logFile -Value $logMessage
    }
    catch {
        Write-Host "[ERROR] Failed to write to log file: $_" -ForegroundColor Red
    }
}

# Get configuration from YAML file
function Get-Configuration {
    [CmdletBinding()]
    param ()
    
    $configPath = Join-Path -Path $PSScriptRoot -ChildPath "config.yaml"
    Write-Log "Loading configuration from $configPath"
    
    # Default configuration
    $defaultConfig = @{
        'capture' = @{
            'interval_seconds' = 30  # Setting higher default for child safety (less intrusive)
            'output_directory' = Join-Path -Path $env:USERPROFILE -ChildPath 'screen_capture'
            'retention_days' = 7
            'image_quality' = 30
            'scaling_factor' = 1.0  # Default scaling factor (1.0 = 100%)
        }
    }
    
    # Return defaults if config file doesn't exist
    if (-not (Test-Path -Path $configPath)) {
        Write-Log "Configuration file not found. Using default values." -Level 'Warning'
        return $defaultConfig
    }
    
    try {
        # Read YAML content
        $configYaml = Get-Content -Path $configPath -Raw
        
        # Simple parsing with regex (avoiding external dependencies)
        if ($configYaml -match 'interval_seconds:\s*(\d+)') {
            $defaultConfig['capture']['interval_seconds'] = [int]$Matches[1]
        }
        
        if ($configYaml -match 'output_directory:\s*"([^"]+)"') {
            $dir = $Matches[1] -replace '%USERPROFILE%', $env:USERPROFILE
            $defaultConfig['capture']['output_directory'] = $dir
        }
        
        if ($configYaml -match 'retention_days:\s*(\d+)') {
            $defaultConfig['capture']['retention_days'] = [int]$Matches[1]
        }
        
        if ($configYaml -match 'image_quality:\s*(\d+)') {
            $defaultConfig['capture']['image_quality'] = [int]$Matches[1]
        }
        
        if ($configYaml -match 'scaling_factor:\s*(\d+\.?\d*)') {
            $defaultConfig['capture']['scaling_factor'] = [double]$Matches[1]
        }
        
        return $defaultConfig
    }
    catch {
        Write-Log "Error loading configuration: $_" -Level 'Error'
        return $defaultConfig
    }
}

# Create output directory
function Initialize-OutputDirectory {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$Path
    )
    
    try {
        # Ensure directory exists
        if (-not (Test-Path -Path $Path)) {
            Write-Log "Creating output directory: $Path"
            New-Item -ItemType Directory -Path $Path -Force | Out-Null
        }
        
        return $Path
    }
    catch {
        Write-Log "Failed to create directory: $_" -Level 'Error'
        
        # Fallback to temp directory
        $tempDir = Join-Path -Path $env:TEMP -ChildPath 'screen_capture'
        if (-not (Test-Path -Path $tempDir)) {
            New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
        }
        
        Write-Log "Using fallback directory: $tempDir" -Level 'Warning'
        return $tempDir
    }
}

# Simple screen capture function
# Import the Get-ScreenCapture function from its dedicated file
. "$PSScriptRoot\Get-ScreenCapture.ps1"

# Remove old images
function Remove-OldImages {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$OutputDirectory,
        
        [Parameter(Mandatory=$true)]
        [int]$RetentionDays
    )
    
    Write-Log "Cleaning up old screenshots" -Level 'Info'
    
    try {
        $cutoffDate = (Get-Date).AddDays(-$RetentionDays)
        
        # Find old files
        $oldFiles = Get-ChildItem -Path $OutputDirectory -Filter "screenshot_*.png" | 
                    Where-Object { $_.LastWriteTime -lt $cutoffDate }
        
        $count = ($oldFiles | Measure-Object).Count
        
        if ($count -gt 0) {
            Write-Log "Removing $count old screenshots" -Level 'Info'
            $oldFiles | Remove-Item -Force
        }
        else {
            Write-Log "No old screenshots to remove" -Level 'Info'
        }
    }
    catch {
        Write-Log "Error cleaning up old files: $_" -Level 'Error'
    }
}

# Main capture loop
function Start-ScreenCapture {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [int]$Interval,
        
        [Parameter(Mandatory=$true)]
        [string]$OutputDir,
        
        [Parameter(Mandatory=$true)]
        [int]$RetentionDays,
        
        [Parameter(Mandatory=$false)]
        [double]$ScalingFactor = 1.0
    )
    
    Write-Log "Starting screen capture monitoring" -Level 'Info'
    Write-Log "Saving screenshots to: $OutputDir" -Level 'Info'
    Write-Log "Capture interval: $Interval seconds" -Level 'Info'
    Write-Log "Retention period: $RetentionDays days" -Level 'Info'
    Write-Log "Display scaling factor: $ScalingFactor" -Level 'Info'
    
    try {
        while ($true) {
            $startTime = Get-Date
            
            # Take screenshot
            Get-ScreenCapture -OutputDirectory $OutputDir -PrimaryOnly:$PrimaryOnly -ScalingFactor $ScalingFactor
            
            # Clean up old files once an hour
            if ((Get-Date).Minute -eq 0 -and (Get-Date).Second -lt $Interval) {
                Remove-OldImages -OutputDirectory $OutputDir -RetentionDays $RetentionDays
            }
            
            # Calculate sleep time
            $processingTime = (Get-Date) - $startTime
            $sleepTime = [Math]::Max(1, $Interval - $processingTime.TotalSeconds)
            
            Write-Log "Waiting $([Math]::Round($sleepTime)) seconds until next capture" -Level 'Info'
            Start-Sleep -Seconds ([Math]::Round($sleepTime))
        }
    }
    catch {
        Write-Log "Error in capture loop: $_" -Level 'Error'
    }
}

# Main execution
try {
    Write-Log "Starting child safety monitoring" -Level 'Info'
    Write-Log "PowerShell version: $($PSVersionTable.PSVersion)" -Level 'Info'
    Write-Log "Windows version: $([Environment]::OSVersion.Version)" -Level 'Info'
    
    # Load configuration
    $config = Get-Configuration
    
    # Setup directories
    $outputDir = $config['capture']['output_directory']
    $outputDir = Initialize-OutputDirectory -Path $outputDir
    
    # Handle cleanup only
    if ($CleanOnly) {
        Write-Log "Running cleanup only" -Level 'Info'
        Remove-OldImages -OutputDirectory $outputDir -RetentionDays $config['capture']['retention_days']
        exit 0
    }
    
    # Handle list screens only
    if ($ListScreens) {
        Write-Log "Listing available screens" -Level 'Info'
        Add-Type -AssemblyName System.Windows.Forms
        $screens = [System.Windows.Forms.Screen]::AllScreens
        $screenCount = $screens.Count
        
        # Get virtual screen dimensions
        $vLeft = [System.Windows.Forms.SystemInformation]::VirtualScreen.Left
        $vTop = [System.Windows.Forms.SystemInformation]::VirtualScreen.Top
        $vWidth = [System.Windows.Forms.SystemInformation]::VirtualScreen.Width
        $vHeight = [System.Windows.Forms.SystemInformation]::VirtualScreen.Height
        
        Write-Log "Total monitors detected: $screenCount" -Level 'Info'
        Write-Log "Virtual screen dimensions: Left=$vLeft, Top=$vTop, Width=$vWidth, Height=$vHeight" -Level 'Info'
        
        # Display information for each screen
        for ($i = 0; $i -lt $screenCount; $i++) {
            $screen = $screens[$i]
            $isPrimary = if ($screen.Primary) { "(Primary)" } else { "" }
            Write-Log "Screen $($i+1) $isPrimary" -Level 'Info'
            Write-Log "  Device name: $($screen.DeviceName)" -Level 'Info'
            Write-Log "  Bounds: X=$($screen.Bounds.X), Y=$($screen.Bounds.Y), Width=$($screen.Bounds.Width), Height=$($screen.Bounds.Height)" -Level 'Info'
            Write-Log "  Working area: X=$($screen.WorkingArea.X), Y=$($screen.WorkingArea.Y), Width=$($screen.WorkingArea.Width), Height=$($screen.WorkingArea.Height)" -Level 'Info'
            Write-Log "  BitsPerPixel: $($screen.BitsPerPixel)" -Level 'Info'
        }
        exit 0
    }
    
    # Handle single capture
    if ($RunOnce) {
        Write-Log "Running single capture" -Level 'Info'
        Get-ScreenCapture -OutputDirectory $outputDir -PrimaryOnly:$PrimaryOnly -ScalingFactor $config['capture']['scaling_factor']
        exit 0
    }
    
    # Start continuous capturing
    Start-ScreenCapture `
        -Interval $config['capture']['interval_seconds'] `
        -OutputDir $outputDir `
        -RetentionDays $config['capture']['retention_days'] `
        -ScalingFactor $config['capture']['scaling_factor']
}
catch {
    Write-Log "Critical error: $_" -Level 'Error'
    exit 1
}

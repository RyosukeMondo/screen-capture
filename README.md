# Screen Capture Solution

A Windows application that captures all screens in multi-display setups at regular intervals.

## Features

- Captures all screens in multi-display setups
- Configurable capture interval (default: 5 seconds)
- Configurable output directory (default: %USERPROFILE%\screen_capture)
- Automatic cleanup of old captures (default: 7 days retention)
- Easy registration/unregistration with Windows Startup folder (no admin rights needed)
- Optimized PNG image quality (default: 30 - low quality for smaller file size)
- Runs automatically at user login

## Requirements

- Windows 10 or later
- PowerShell 5.1 or higher (comes pre-installed with Windows 10/11)
- No administrator access needed - runs with standard user permissions

## Installation

1. Download and extract the ZIP file containing all application files
2. Right-click on `Register-StartupItem.ps1` and select "Run with PowerShell" to:
   - Add the application to your Windows Startup folder
   - Start the capture service immediately (optional)

## Configuration

The application can be configured by editing `config.yaml`:

```yaml
# Screen capture configuration
capture:
  interval_seconds: 5  # Default capture interval in seconds
  output_directory: "C:\\screen_capture"  # Default output directory
  retention_days: 7  # How long to keep images before deletion
  image_quality: 30  # PNG quality (lower = smaller file size)
```

## Usage


## Files

- `ScreenCaptureSimple.ps1` - Main script that takes screenshots
- `Register-SafeStartup.ps1` - Adds monitoring to Windows startup
- `Stop-SafeMonitor.ps1` - Stops monitoring and removes from startup
- `config.yaml` - Configuration file (interval, output directory, etc.)
- `SafeStartup.ps1` - Helper script (automatically created)

## Quick Start

### Start Monitoring

```powershell
.\Register-SafeStartup.ps1
```

This adds the monitoring to Windows startup and begins capturing immediately.

### Stop Monitoring

```powershell
.\Stop-SafeMonitor.ps1
```

This stops any running capture processes and removes the startup shortcut.

### Take Single Screenshot

```powershell
.\ScreenCaptureSimple.ps1 -RunOnce
```

Takes one screenshot without starting continuous monitoring.

### Clean Up Old Screenshots

```powershell
.\ScreenCaptureSimple.ps1 -CleanOnly
```

## Configuration

Edit `config.yaml` to customize:

- `interval_seconds` - Time between captures (default: 30)
- `output_directory` - Where to save screenshots (default: %USERPROFILE%\screen_capture)
- `retention_days` - When to delete old screenshots (default: 7)
- `image_quality` - Screenshot quality (default: 30, lower = smaller files)

## Locations

- **Screenshots**: `C:\Users\[username]\screen_capture`
- **Log files**: `C:\Users\[username]\screen_capture_logs`
- **Startup shortcut**: `C:\Users\[username]\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\ChildSafetyMonitor.lnk`

## Troubleshooting

If screenshots aren't being captured:

1. Check the log files in `C:\Users\[username]\screen_capture_logs`
2. Make sure no security software is blocking PowerShell scripts
3. Verify that the script can access `System.Drawing` and `System.Windows.Forms`

## License

This project is licensed under the MIT License - see the LICENSE file for details.

function Get-ScreenCapture {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$OutputDirectory,
        
        [Parameter(Mandatory=$false)]
        [switch]$PrimaryOnly,
        
        [Parameter(Mandatory=$false)]
        [double]$ScalingFactor = 1.0
    )
    
    Write-Log "Taking screenshot" -Level 'Info'
    
    try {
        # Load required assemblies
        Add-Type -AssemblyName System.Windows.Forms
        Add-Type -AssemblyName System.Drawing
        
        # Create timestamp for filename
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        
        # Apply scaling factor to adjust for Windows display scaling
        if ($ScalingFactor -ne 1.0) {
            Write-Log "Using display scaling factor: $ScalingFactor" -Level 'Info'
        }
        
        # Determine if we want all screens or just the primary
        if ($PrimaryOnly) {
            Write-Log "Capturing primary screen only" -Level 'Info'
            $outputPath = Join-Path -Path $OutputDirectory -ChildPath "screenshot_primary_$timestamp.png"
            
            # Get primary screen information
            $screen = [System.Windows.Forms.Screen]::PrimaryScreen
            $width = $screen.Bounds.Width
            $height = $screen.Bounds.Height
            
            # Apply scaling if necessary
            if ($ScalingFactor -ne 1.0) {
                $scaledWidth = [int]($width * $ScalingFactor)
                $scaledHeight = [int]($height * $ScalingFactor)
                Write-Log "Screen size: ${width}x${height} (logical) ${scaledWidth}x${scaledHeight} (scaled)" -Level 'Info'
            } else {
                Write-Log "Primary screen size: ${width}x${height}" -Level 'Info'
            }
            
            # Create a bitmap for the primary screen
            $bitmap = New-Object System.Drawing.Bitmap $width, $height
            
            # Create a graphics object
            $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
            
            # Copy the screen to the bitmap
            $graphics.CopyFromScreen(0, 0, 0, 0, $bitmap.Size)
            
            # If scaling is required and not 100%, create a scaled version
            if ($ScalingFactor -ne 1.0) {
                $scaledBitmap = New-Object System.Drawing.Bitmap $scaledWidth, $scaledHeight
                $scaledGraphics = [System.Drawing.Graphics]::FromImage($scaledBitmap)
                $scaledGraphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
                $scaledGraphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
                $scaledGraphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
                $scaledGraphics.DrawImage($bitmap, (New-Object System.Drawing.Rectangle 0, 0, $scaledWidth, $scaledHeight))
                
                # Release original resources and replace with scaled versions
                $graphics.Dispose()
                $bitmap.Dispose()
                $bitmap = $scaledBitmap
                $graphics = $scaledGraphics
            }
            
            # Save the image
            Write-Log "Saving to $outputPath" -Level 'Info'
            $bitmap.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)
            
            # Release resources
            $graphics.Dispose()
            $bitmap.Dispose()
        }
        else {
            # Get all screens and calculate the virtual screen bounds
            $screens = [System.Windows.Forms.Screen]::AllScreens
            $screenCount = $screens.Count
            Write-Log "Detected $screenCount monitors" -Level 'Info'
            
            $outputPath = Join-Path -Path $OutputDirectory -ChildPath "screenshot_all_$timestamp.png"
            
            # Calculate the virtual screen dimensions (this accounts for all monitors and their positions)
            $left = [System.Windows.Forms.SystemInformation]::VirtualScreen.Left
            $top = [System.Windows.Forms.SystemInformation]::VirtualScreen.Top
            $width = [System.Windows.Forms.SystemInformation]::VirtualScreen.Width
            $height = [System.Windows.Forms.SystemInformation]::VirtualScreen.Height
            
            # Calculate scaled dimensions if needed
            if ($ScalingFactor -ne 1.0) {
                $scaledWidth = [int]($width * $ScalingFactor)
                $scaledHeight = [int]($height * $ScalingFactor)
                Write-Log "Virtual screen bounds: Left=$left, Top=$top, Width=$width, Height=$height (logical) ${scaledWidth}x${scaledHeight} (scaled)" -Level 'Info'
            } else {
                Write-Log "Virtual screen bounds: Left=$left, Top=$top, Width=$width, Height=$height" -Level 'Info'
            }
            
            # Create a bitmap big enough for the entire virtual screen
            $bitmap = New-Object System.Drawing.Bitmap $width, $height
            
            # Create a graphics object
            $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
            
            # Copy the entire virtual screen to the bitmap
            $graphics.CopyFromScreen($left, $top, 0, 0, $bitmap.Size)
            
            # If scaling is required and not 100%, create a scaled version
            if ($ScalingFactor -ne 1.0) {
                $scaledBitmap = New-Object System.Drawing.Bitmap $scaledWidth, $scaledHeight
                $scaledGraphics = [System.Drawing.Graphics]::FromImage($scaledBitmap)
                $scaledGraphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
                $scaledGraphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
                $scaledGraphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
                $scaledGraphics.DrawImage($bitmap, (New-Object System.Drawing.Rectangle 0, 0, $scaledWidth, $scaledHeight))
                
                # Release original resources and replace with scaled versions
                $graphics.Dispose()
                $bitmap.Dispose()
                $bitmap = $scaledBitmap
                $graphics = $scaledGraphics
            }
            
            # Save the image
            Write-Log "Saving all screens to $outputPath" -Level 'Info'
            $bitmap.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)
            
            # Release resources
            $graphics.Dispose()
            $bitmap.Dispose()
        }
        
        Write-Log "Screenshot saved successfully" -Level 'Info'
        return $outputPath
    }
    catch {
        Write-Log "Screenshot failed: $_" -Level 'Error'
        Write-Log "Exception details: $($_.Exception)" -Level 'Error'
        return $null
    }
}

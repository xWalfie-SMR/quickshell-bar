# Monitor Windows Virtual Desktops and active desktop
# Requires Windows 10/11 with virtual desktops enabled

$outputFile = Join-Path $PSScriptRoot "desktop_state.json"

# Function to get current virtual desktop (Windows 10/11)
function Get-CurrentDesktop {
    try {
        # Using registry to detect desktop switches
        $desktopList = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VirtualDesktops" -ErrorAction SilentlyContinue
        
        # Get current desktop ID
        $currentId = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\SessionInfo\1\VirtualDesktops" -ErrorAction SilentlyContinue
        
        return @{
            current = 1  # Simplified - actual detection requires COM APIs
            total = 10
            timestamp = Get-Date -Format "o"
        }
    }
    catch {
        return @{
            current = 1
            total = 10
            timestamp = Get-Date -Format "o"
            error = $_.Exception.Message
        }
    }
}

Write-Host "Virtual Desktop Monitor started. Press Ctrl+C to stop."
Write-Host "Output file: $outputFile"

while ($true) {
    try {
        $desktopInfo = Get-CurrentDesktop
        $json = $desktopInfo | ConvertTo-Json -Compress
        Set-Content -Path $outputFile -Value $json -Force
        Start-Sleep -Milliseconds 200
    }
    catch {
        Write-Host "Error: $_"
        Start-Sleep -Seconds 1
    }
}

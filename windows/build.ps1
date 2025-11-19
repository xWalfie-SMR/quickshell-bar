# This script automatically builds the VirtualDesktopPlugin for Windows

param(
    [string]$QtPath = "",
    [switch]$Clean = $false
)

# Colors for output
$Green = [System.ConsoleColor]::Green
$Red = [System.ConsoleColor]::Red
$Yellow = [System.ConsoleColor]::Yellow

function Write-ColorOutput($message, $color) {
    if ($null -eq $color) {
        Write-Host $message
    } else {
        Write-Host $message -ForegroundColor $color
    }
}

function Test-Admin {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Find-QtInstallation {
    # Check common environment variables first
    $envVars = @("QTDIR", "QT_ROOT", "CMAKE_PREFIX_PATH", "Qt6_DIR")
    foreach ($envVar in $envVars) {
        $envPath = [Environment]::GetEnvironmentVariable($envVar, "Machine")
        if (-not $envPath) {
            $envPath = [Environment]::GetEnvironmentVariable($envVar, "User")
        }
        if ($envPath -and (Test-Path $envPath)) {
            Write-ColorOutput "Found Qt via environment variable $envVar`: $envPath" $Green
            return $envPath
        }
    }
    
    # List of toolchain directories to look for
    $toolchains = @("msvc2022_64", "msvc2019_64", "msvc2021_64", "msvc2020_64", "mingw_64")
    
    $qtPaths = @("C:\Qt", "C:\Qt\6.*", "C:\Program Files\Qt", "C:\Program Files (x86)\Qt")
    $versions = @()
    
    foreach ($qtBase in $qtPaths) {
        $resolvedPaths = Resolve-Path $qtBase -ErrorAction SilentlyContinue
        if ($resolvedPaths) {
            foreach ($path in $resolvedPaths) {
                Write-ColorOutput "Searching in Qt base directory: $path" $Green
                
                # Look for version directories (like 6.6.0, 6.5.0, etc.)
                $versionDirs = Get-ChildItem -Path $path -Directory | Where-Object { $_.Name -match '^\d+\.\d+\.\d+$' }
                foreach ($versionDir in $versionDirs) {
                    Write-ColorOutput "Checking version directory: $($versionDir.Name)" $Green
                    
                    # Look for toolchain directories within version directory
                    foreach ($toolchain in $toolchains) {
                        $toolchainPath = Join-Path $versionDir.FullName $toolchain
                        if (Test-Path $toolchainPath) {
                            Write-ColorOutput "Found valid Qt installation: $toolchainPath" $Green
                            return $toolchainPath
                        }
                    }
                }
                
                # Also check if the base directory itself is a toolchain directory
                foreach ($toolchain in $toolchains) {
                    if ($path.Name -eq $toolchain) {
                        Write-ColorOutput "Found valid Qt installation: $path" $Green
                        return $path
                    }
                }
            }
        }
    }
    
    return $null
}

# Check if running as Administrator
if (-not (Test-Admin)) {
    Write-ColorOutput "Warning: Not running as Administrator. Some operations may fail." $Yellow
}

Write-ColorOutput "========================================" $Green
Write-ColorOutput "Quickshell Bar Windows Build Script" $Green
Write-ColorOutput "========================================" $Green
Write-ColorOutput ""

# Set paths
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$pluginDir = Join-Path $scriptDir "VirtualDesktopPlugin"
$buildDir = Join-Path $scriptDir "build"
$outputDir = Join-Path $scriptDir "output"

# Find Qt installation if not specified
if (-not $QtPath) {
    Write-ColorOutput "Searching for Qt installation..." $Green
    $detectedPath = Find-QtInstallation
    if ($detectedPath) {
        $QtPath = $detectedPath
        Write-ColorOutput "Auto-detected Qt at: $QtPath" $Green
    } else {
        Write-ColorOutput "Error: Qt installation not found" $Red
        Write-ColorOutput "Please specify the correct Qt path using -QtPath parameter" $Yellow
        Write-ColorOutput "Example: .\build.ps1 -QtPath 'C:\Qt\6.6.0\msvc2022_64'" $Yellow
        exit 1
    }
}

# Check if Qt path exists
if (-not (Test-Path $QtPath)) {
    Write-ColorOutput "Error: Qt path not found at $QtPath" $Red
    Write-ColorOutput "Please specify the correct Qt path using -QtPath parameter" $Yellow
    Write-ColorOutput "Example: .\build.ps1 -QtPath 'C:\Qt\6.6.0\msvc2022_64'" $Yellow
    exit 1
}

Write-ColorOutput "Using Qt from: $QtPath" $Green
Write-ColorOutput ""

# Clean if requested
if ($Clean) {
    Write-ColorOutput "Cleaning build directory..." $Green
    if (Test-Path $buildDir) {
        Remove-Item -Recurse -Force $buildDir
        Write-ColorOutput "Build directory cleaned." $Green
    }
}

# Create build directory if it doesn't exist
if (-not (Test-Path $buildDir)) {
    New-Item -ItemType Directory -Path $buildDir | Out-Null
    Write-ColorOutput "Created build directory: $buildDir" $Green
}

# Change to build directory
Push-Location $buildDir

try {
    # Setup Visual Studio environment for NMake
    Write-ColorOutput "Setting up Visual Studio environment..." $Green
    
    # Try to find and run vcvarsall.bat
    $vsWhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
    if (Test-Path $vsWhere) {
        $vsPath = & $vsWhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
        if ($vsPath) {
            $vcvarsall = "$vsPath\VC\Auxiliary\Build\vcvarsall.bat"
            if (Test-Path $vcvarsall) {
                Write-ColorOutput "Found Visual Studio at: $vsPath" $Green
                Write-ColorOutput "Running vcvarsall.bat to set up build environment..." $Green
                cmd /c "`"$vcvarsall`" x64 && set" | ForEach-Object {
                    if ($_ -match '^(.+?)=(.*)$') {
                        [System.Environment]::SetEnvironmentVariable($matches[1], $matches[2], "Process")
                    }
                }
                Write-ColorOutput "Visual Studio environment configured successfully." $Green
            } else {
                Write-ColorOutput "Warning: vcvarsall.bat not found at $vcvarsall" $Yellow
            }
        } else {
            Write-ColorOutput "Warning: Visual Studio installation not found with required C++ tools" $Yellow
        }
    } else {
        Write-ColorOutput "Warning: Visual Studio installer (vswhere.exe) not found" $Yellow
    }
    
    # Verify that nmake and cl are available
    try {
        $nmakeVersion = nmake /? 2>&1 | Select-Object -First 1
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "NMake is available" $Green
        } else {
            throw "NMake not found"
        }
    } catch {
        Write-ColorOutput "Error: NMake not found in PATH. Make sure Visual Studio is properly installed and configured." $Red
        Write-ColorOutput "You may need to run this script from a Developer Command Prompt, or install Visual Studio with C++ tools." $Yellow
        exit 1
    }
    
    Write-ColorOutput ""
    
    # Configure with CMake
    Write-ColorOutput "Configuring with CMake..." $Green
    $cmakeCommand = "cmake `"$pluginDir`" -G `"NMake Makefiles`" -DCMAKE_PREFIX_PATH=`"$QtPath`" -DCMAKE_BUILD_TYPE=Release"
    
    Invoke-Expression $cmakeCommand
    if ($LASTEXITCODE -ne 0) {
        Write-ColorOutput "CMake configuration failed!" $Red
        exit 1
    }
    
    Write-ColorOutput "CMake configuration completed successfully." $Green
    Write-ColorOutput ""
    
    # Build
    Write-ColorOutput "Building with NMake..." $Green
    nmake
    if ($LASTEXITCODE -ne 0) {
        Write-ColorOutput "Build failed!" $Red
        exit 1
    }
    
    Write-ColorOutput "Build completed successfully." $Green
    Write-ColorOutput ""
    
    # Copy output files
    Write-ColorOutput "Copying files to output directory..." $Green
    
    # Create output directory if it doesn't exist
    if (-not (Test-Path $outputDir)) {
        New-Item -ItemType Directory -Path $outputDir | Out-Null
    }
    
    # Copy DLL
    $dllPath = Join-Path $buildDir "VirtualDesktopPlugin.dll"
    if (Test-Path $dllPath) {
        Copy-Item -Path $dllPath -Destination $outputDir -Force
        Write-ColorOutput "Copied DLL: $(Split-Path $dllPath -Leaf)" $Green
    } else {
        Write-ColorOutput "Warning: DLL not found at $dllPath" $Yellow
    }
    
    # Copy qmldir
    $qmldirSource = Join-Path $pluginDir "qmldir"
    if (Test-Path $qmldirSource) {
        Copy-Item -Path $qmldirSource -Destination $outputDir -Force
        Write-ColorOutput "Copied qmldir file" $Green
    }
    
    # Copy plugin.cpp and headers (for reference)
    $pluginCpp = Join-Path $pluginDir "plugin.cpp"
    if (Test-Path $pluginCpp) {
        Copy-Item -Path $pluginCpp -Destination $outputDir -Force
        Write-ColorOutput "Copied plugin.cpp" $Green
    }
    
    $headerFiles = Get-ChildItem -Path $pluginDir -Filter "*.h"
    foreach ($header in $headerFiles) {
        Copy-Item -Path $header.FullName -Destination $outputDir -Force
        Write-ColorOutput "Copied header: $($header.Name)" $Green
    }
    
    Write-ColorOutput ""
    Write-ColorOutput "Build completed successfully!" $Green
    Write-ColorOutput "Output files are available in: $outputDir" $Green
    
} catch {
    Write-ColorOutput "Error during build: $($_.Exception.Message)" $Red
    exit 1
} finally {
    # Return to original directory
    Pop-Location
}

Write-ColorOutput ""
Write-ColorOutput "Build script finished." $Green
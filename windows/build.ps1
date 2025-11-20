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

function Request-AdminElevation {
    param([string]$ScriptPath, [array]$Arguments)
    
    Write-ColorOutput "This script requires Administrator privileges to install Qt." $Yellow
    Write-ColorOutput "Requesting elevation..." $Yellow
    
    Write-ColorOutput "Please re-run this script from an elevated PowerShell (right-click PowerShell and choose 'Run as Administrator')." $Yellow
    return $false
}

function Refresh-Path {
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
}

function Test-CommandExists {
    param([string]$Command)
    
    # First check if it's in PATH
    if (Get-Command $Command -ErrorAction SilentlyContinue) {
        return $true
    }
    
    # Refresh PATH and try again (in case something was just installed)
    Refresh-Path
    if (Get-Command $Command -ErrorAction SilentlyContinue) {
        return $true
    }
    
    return $false
}

# Locate an existing Qt installation (search env vars, common paths, and toolchains)
function Find-QtInstallation {
    # Check common environment variables first
    $envVars = @('QTDIR','QT_ROOT','CMAKE_PREFIX_PATH','Qt6_DIR')
    foreach ($envVar in $envVars) {
        $envPath = [Environment]::GetEnvironmentVariable($envVar, 'Machine')
        if (-not $envPath) { $envPath = [Environment]::GetEnvironmentVariable($envVar, 'User') }
        if ($envPath -and (Test-Path $envPath)) { return $envPath }
    }

    # Preferred toolchains (prioritize MSVC 2022)
    $toolchains = @('msvc2022_64','msvc2021_64','msvc2019_64','msvc2020_64','mingw_64')

    # Common base locations to search
    $qtBases = @('C:\Qt','C:\Qt\6.*','C:\Program Files\Qt','C:\Program Files (x86)\Qt',$env:USERPROFILE+'\Qt','C:\Qt6')

    foreach ($base in $qtBases) {
        $resolved = Resolve-Path $base -ErrorAction SilentlyContinue
        if (-not $resolved) { continue }
        foreach ($r in $resolved) {
            # Look for version directories like 6.6.0
            $versions = Get-ChildItem -Path $r -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '^\d+\.\d+\.\d+$' } | Sort-Object Name -Descending
            foreach ($v in $versions) {
                foreach ($t in $toolchains) {
                    $candidate = Join-Path $v.FullName $t
                    if (Test-Path $candidate) { return $candidate }
                }
            }
        }
    }

    return $null
}

function Install-QtViaAqt {
    Write-ColorOutput "Installing Qt6 via Python aqtinstall (unattended)..." $Green
    Write-ColorOutput "This may take some time (downloading Qt archives)." $Yellow

    # Desired Qt version and toolchain
    $qtVersion = '6.6.0'
    $toolchain = 'msvc2022_64'
    $installBase = "C:\Qt\$qtVersion"

    # Find Python executable (prefer 'python', fallback to 'py')
    $pyExe = $null
    $pyExtraArgs = @()
    if (Get-Command python -ErrorAction SilentlyContinue) { $pyExe = 'python' }
    elseif (Get-Command py -ErrorAction SilentlyContinue) { $pyExe = 'py'; $pyExtraArgs = @('-3') }

    if (-not $pyExe) {
        Write-ColorOutput "Python 3 is required but was not found on PATH. Please install Python 3 and ensure 'python' or 'py' is available." $Red
        throw "Python 3 not found"
    }
    # Ensure pip and aqtinstall are installed
    try {
        $pipArgs = $pyExtraArgs + @('-m','pip','install','--upgrade','pip','aqtinstall')
        Write-ColorOutput "Ensuring pip and aqtinstall are installed via: $pyExe $($pipArgs -join ' ')" $Green
        & $pyExe @pipArgs 2>&1 | ForEach-Object { Write-Host $_ }
        if ($LASTEXITCODE -ne 0) { throw "Failed to install aqtinstall via pip" }
    } catch {
        Write-ColorOutput "Error installing aqtinstall: $($_.Exception.Message)" $Red
        throw $_
    }

    # Run aqtinstall to fetch Qt
    try {
        Write-ColorOutput "Attempting to install Qt $qtVersion using known architecture tokens (may try several)..." $Green

        # Try several MSVC2022 token variants first (some mirrors/name schemes use toolset suffixes like _143)
        $candidateTokens = @(
            'win64_msvc2022_143', 'win64_msvc2022_64', 'win64_msvc2022',
            'win64_msvc2021_64','win64_msvc2019_64','win64_mingw'
        )
        $selectedArch = $null
        foreach ($candidate in $candidateTokens) {
            Write-ColorOutput "Trying architecture token: $candidate" $Yellow
            $aqtArgs = $pyExtraArgs + @('-m','aqt') + @('install-qt','windows','desktop',$qtVersion,$candidate,'--outputdir',$installBase)
            & $pyExe @aqtArgs 2>&1 | ForEach-Object { Write-Host $_ }
            if ($LASTEXITCODE -eq 0) {
                $selectedArch = $candidate
                break
            } else {
                Write-ColorOutput "Install with $candidate failed (exit $LASTEXITCODE), trying next token..." $Yellow
            }
        }

        if (-not $selectedArch) {
            Write-ColorOutput "All known architecture tokens failed to install Qt $qtVersion. Please run 'python -m aqt list-qt windows desktop' to inspect available tokens and run the script with -QtPath manually." $Red
            throw "aqtinstall failed for all known tokens"
        }
        Write-ColorOutput "Qt installation succeeded with architecture token: $selectedArch" $Green
    } catch {
        Write-ColorOutput "Error during aqtinstall: $($_.Exception.Message)" $Red
        throw $_
    }

    # aqtinstall creates nested structure: $installBase/<version>/<toolchain>
    # e.g., C:\Qt\6.6.0\6.6.0\msvc2019_64
    # The architecture token (e.g., 'win64_msvc2019_64') differs from the directory name (e.g., 'msvc2019_64')
    
    # Look for version directories under $installBase
    if (Test-Path $installBase) {
        $versionDirs = Get-ChildItem -Path $installBase -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '^\d+\.\d+\.\d+$' } | Sort-Object Name -Descending
        
        foreach ($versionDir in $versionDirs) {
            # Look for toolchain directories under the version directory
            $toolchainDirs = Get-ChildItem -Path $versionDir.FullName -Directory -ErrorAction SilentlyContinue | Where-Object { 
                $_.Name -match '(msvc|mingw|gcc|clang).*_64$' 
            }
            
            if ($toolchainDirs) {
                # Return the first toolchain found (prefer MSVC variants if multiple)
                $preferred = $toolchainDirs | Where-Object { $_.Name -match 'msvc' } | Select-Object -First 1
                if (-not $preferred) {
                    $preferred = $toolchainDirs | Select-Object -First 1
                }
                
                $qtPath = $preferred.FullName
                Write-ColorOutput "Qt installed successfully at: $qtPath" $Green
                return $qtPath
            }
        }
    }

    throw "Qt installation completed but Qt path not found under $installBase (expected version/toolchain structure)"
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
        Write-ColorOutput "The build needs a Qt kit (for example: C:\Qt\6.6.0\msvc2022_64)." $Yellow
        Write-ColorOutput ""
        
        # Offer automated installation (uses Python aqtinstall)
        $answer = Read-Host "Qt not found. Install Qt automatically using Python aqtinstall? (Y/N) [Y]"
        if (-not $answer) { $answer = 'Y' }

        if ($answer.Trim().ToUpper().StartsWith('Y')) {
            if (-not (Test-Admin)) {
                Write-ColorOutput "Administrator privileges are required to install Qt. Please re-run this script from an elevated PowerShell (Run as Administrator)." $Yellow
                exit
            }

            try {
                $QtPath = Install-QtViaAqt
            } catch {
                Write-ColorOutput "Error during Qt installation: $($_.Exception.Message)" $Red
                Write-ColorOutput ""
                Write-ColorOutput "Please install Qt manually and specify the path:" $Yellow
                Write-ColorOutput "Example: .\build.ps1 -QtPath 'C:\Qt\6.6.0\msvc2022_64'" $Yellow
                exit 1
            }
        } else {
            Write-ColorOutput "Please specify the correct Qt path using -QtPath parameter" $Yellow
            Write-ColorOutput "Example: .\build.ps1 -QtPath 'C:\Qt\6.6.0\msvc2022_64'" $Yellow
            exit 1
        }
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
    Refresh-Path
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
    
    $headerFiles = Get-ChildItem -Path $pluginDir -Filter "*.h" -ErrorAction SilentlyContinue
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
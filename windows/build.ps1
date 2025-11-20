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
            # Look for version directories like 6.8.3
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

    $qtVersion = '6.8.3'
    $qtInstallRoot = "C:\Qt"
    $qtVersionDir = Join-Path $qtInstallRoot $qtVersion

    if (-not (Test-Path $qtInstallRoot)) {
        New-Item -ItemType Directory -Path $qtInstallRoot -Force | Out-Null
    }

    $pyExe = $null
    $pyExtraArgs = @()
    if (Get-Command python -ErrorAction SilentlyContinue) { $pyExe = 'python' }
    elseif (Get-Command py -ErrorAction SilentlyContinue) { $pyExe = 'py'; $pyExtraArgs = @('-3') }

    if (-not $pyExe) {
        Write-ColorOutput "Python 3 is required but was not found on PATH. Please install Python 3 and ensure 'python' or 'py' is available." $Red
        throw "Python 3 not found"
    }

    try {
        $pipArgs = $pyExtraArgs + @('-m','pip','install','--upgrade','pip','aqtinstall')
        Write-ColorOutput "Ensuring pip and aqtinstall are installed via: $pyExe $($pipArgs -join ' ')" $Green
        & $pyExe @pipArgs 2>&1 | ForEach-Object { Write-Host $_ }
        if ($LASTEXITCODE -ne 0) { throw "Failed to install aqtinstall via pip" }
    } catch {
        Write-ColorOutput "Error installing aqtinstall: $($_.Exception.Message)" $Red
        throw $_
    }

    try {
        Write-ColorOutput "Attempting to install Qt $qtVersion using known architecture tokens (may try several)..." $Green

        $candidateTokens = @(
            @{ Token='win64_msvc2022_64'; Toolchain='msvc2022_64' },
            @{ Token='win64_msvc2022_arm64_cross_compiled'; Toolchain='msvc2022_arm64_cross_compiled' },
            @{ Token='win64_llvm_mingw'; Toolchain='llvm_mingw_64' },
            @{ Token='win64_mingw'; Toolchain='mingw_64' }
        )

        $selectedArch = $null
        foreach ($candidate in $candidateTokens) {
            $token = $candidate.Token
            Write-ColorOutput "Trying architecture token: $token" $Yellow
            $aqtArgs = $pyExtraArgs + @('-m','aqt','install-qt','windows','desktop',$qtVersion,$token,'--outputdir',$qtInstallRoot)
            & $pyExe @aqtArgs 2>&1 | ForEach-Object { Write-Host $_ }
            if ($LASTEXITCODE -eq 0) {
                $selectedArch = $candidate
                break
            } else {
                Write-ColorOutput "Install with $token failed (exit $LASTEXITCODE), trying next token..." $Yellow
            }
        }

        if (-not $selectedArch) {
            Write-ColorOutput "All known architecture tokens failed to install Qt $qtVersion. Please run 'python -m aqt list-qt windows desktop' to inspect available tokens and run the script with -QtPath manually." $Red
            throw "aqtinstall failed for all known tokens"
        }
        Write-ColorOutput "Qt installation succeeded with architecture token: $($selectedArch.Token)" $Green
    } catch {
        Write-ColorOutput "Error during aqtinstall: $($_.Exception.Message)" $Red
        throw $_
    }

    if (-not (Test-Path $qtVersionDir)) {
        throw "Qt installation completed but version directory not found at $qtVersionDir"
    }

    $nameHints = @()
    if ($selectedArch.Toolchain) { $nameHints += $selectedArch.Toolchain }
    if ($selectedArch.Token) {
        $nameHints += $selectedArch.Token
        if ($selectedArch.Token -match '^win(?:32|64)_(.+)$') {
            $nameHints += $matches[1]
        }
    }

    $nameHints = $nameHints | Where-Object { $_ } | Select-Object -Unique

    foreach ($name in $nameHints) {
        $candidatePath = Join-Path $qtVersionDir $name
        if (Test-Path $candidatePath) {
            Write-ColorOutput "Qt installed successfully at: $candidatePath" $Green
            return $candidatePath
        }
    }

    $recentKit = Get-ChildItem -Path $qtVersionDir -Directory -ErrorAction SilentlyContinue |
        Where-Object { Test-Path (Join-Path $_.FullName "bin\qmake.exe") } |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1

    if ($recentKit) {
        $kitPath = $recentKit.FullName
        Write-ColorOutput "Qt installed successfully at: $kitPath" $Green
        return $kitPath
    }

    $autoDetected = Find-QtInstallation
    if ($autoDetected) {
        Write-ColorOutput "Qt installed successfully at: $autoDetected" $Green
        return $autoDetected
    }

    throw "Qt installation completed but Qt path not found under $qtVersionDir"
}

function Get-VsWherePath {
    $possiblePaths = @(
        "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe",
        "${env:ProgramFiles}\Microsoft Visual Studio\Installer\vswhere.exe"
    ) | Where-Object { $_ }

    foreach ($path in $possiblePaths) {
        if (Test-Path $path) { return $path }
    }

    return $null
}

function Get-VsInstallPath {
    $vsWhere = Get-VsWherePath
    if (-not $vsWhere) { return $null }

    $vsPath = & $vsWhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
    if ($LASTEXITCODE -ne 0) { return $null }
    if ($vsPath) { return $vsPath.Trim() }

    return $null
}

function Install-VisualStudioBuildTools {
    Write-ColorOutput "Installing Visual Studio Build Tools (unattended)..." $Green
    Write-ColorOutput "This may take several minutes." $Yellow

    if (-not (Test-Admin)) {
        throw "Administrator privileges are required to install Visual Studio Build Tools"
    }

    $installerUrl = "https://aka.ms/vs/17/release/vs_BuildTools.exe"
    $tempInstaller = Join-Path ([System.IO.Path]::GetTempPath()) "vs_BuildTools.exe"

    try {
        Write-ColorOutput "Downloading Visual Studio Build Tools bootstrapper..." $Green
        Invoke-WebRequest -Uri $installerUrl -OutFile $tempInstaller -UseBasicParsing
    } catch {
        throw "Failed to download Visual Studio Build Tools: $($_.Exception.Message)"
    }

    if (-not (Test-Path $tempInstaller)) {
        throw "Visual Studio Build Tools bootstrapper download failed"
    }

    $arguments = @(
        "--quiet",
        "--wait",
        "--norestart",
        "--nocache",
        "--add","Microsoft.VisualStudio.Workload.VCTools",
        "--add","Microsoft.VisualStudio.Component.VC.Tools.x86.x64",
        "--add","Microsoft.VisualStudio.Component.Windows10SDK.22621",
        "--add","Microsoft.VisualStudio.Component.VC.CMake.Project",
        "--includeRecommended"
    )

    try {
        $process = Start-Process -FilePath $tempInstaller -ArgumentList $arguments -Wait -PassThru -NoNewWindow
        if ($process.ExitCode -ne 0) {
            throw "Installer exited with code $($process.ExitCode)"
        }
    } catch {
        throw "Visual Studio Build Tools installation failed: $($_.Exception.Message)"
    } finally {
        if (Test-Path $tempInstaller) {
            Remove-Item $tempInstaller -Force -ErrorAction SilentlyContinue
        }
    }
}

function Ensure-VisualStudioInstall {
    $vsPath = Get-VsInstallPath
    if ($vsPath) { return $vsPath }

    Write-ColorOutput "Visual Studio C++ build tools not found. Installing automatically..." $Yellow
    Install-VisualStudioBuildTools
    Refresh-Path

    return Get-VsInstallPath
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
    $QtPath = Find-QtInstallation
    if ($QtPath) {
        Write-ColorOutput "Auto-detected Qt at: $QtPath" $Green
    } else {
        Write-ColorOutput "Qt installation not found. Installing automatically..." $Yellow
        if (-not (Test-Admin)) {
            Write-ColorOutput "Administrator privileges are required to install Qt automatically. Please re-run this script from an elevated PowerShell session." $Red
            exit 1
        }

        try {
            $QtPath = Install-QtViaAqt
        } catch {
            Write-ColorOutput "Error during Qt installation: $($_.Exception.Message)" $Red
            Write-ColorOutput ""
            Write-ColorOutput "Please install Qt manually and specify the path:" $Yellow
            Write-ColorOutput "Example: .\build.ps1 -QtPath 'C:\Qt\6.8.3\msvc2022_64'" $Yellow
            exit 1
        }
    }
}

# Check if Qt path exists
if (-not (Test-Path $QtPath)) {
    Write-ColorOutput "Error: Qt path not found at $QtPath" $Red
    Write-ColorOutput "Please specify the correct Qt path using -QtPath parameter" $Yellow
    Write-ColorOutput "Example: .\build.ps1 -QtPath 'C:\Qt\6.8.3\msvc2022_64'" $Yellow
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

    $vsPath = Get-VsInstallPath
    if (-not $vsPath) {
        if (-not (Test-Admin)) {
            Write-ColorOutput "Visual Studio C++ build tools not found. Please run this script as Administrator so it can install the required components automatically." $Red
            exit 1
        }

        try {
            $vsPath = Ensure-VisualStudioInstall
        } catch {
            Write-ColorOutput "Failed to install Visual Studio Build Tools: $($_.Exception.Message)" $Red
            exit 1
        }
    }

    if (-not $vsPath) {
        Write-ColorOutput "Unable to locate Visual Studio Build Tools even after attempting installation." $Red
        exit 1
    }

    $vcvarsall = Join-Path $vsPath "VC\Auxiliary\Build\vcvarsall.bat"
    if (-not (Test-Path $vcvarsall)) {
        Write-ColorOutput "vcvarsall.bat not found at $vcvarsall" $Red
        exit 1
    }

    Write-ColorOutput "Found Visual Studio at: $vsPath" $Green
    Write-ColorOutput "Running vcvarsall.bat to set up build environment..." $Green

    # Create a temporary batch file that will run vcvarsall and output environment
    $tempBatch = [System.IO.Path]::GetTempFileName() + ".bat"

    @"
@echo off
call "$vcvarsall" x64 >nul 2>&1
if errorlevel 1 (
    echo ERROR: vcvarsall.bat failed
    exit /b 1
)
set
"@ | Out-File -FilePath $tempBatch -Encoding ASCII

    # Run the batch file and capture output
    $result = & cmd.exe /c $tempBatch 2>&1
    Remove-Item $tempBatch -ErrorAction SilentlyContinue

    # Parse and set environment variables
    $envVarsSet = 0
    foreach ($line in $result) {
        if ($line -match '^([^=]+)=(.*)$') {
            $varName = $matches[1]
            $varValue = $matches[2]
            [System.Environment]::SetEnvironmentVariable($varName, $varValue, "Process")
            $envVarsSet++
        }
    }

    if ($envVarsSet -gt 0) {
        Write-ColorOutput "Visual Studio environment configured successfully ($envVarsSet environment variables set)." $Green
    } else {
        Write-ColorOutput "Warning: No environment variables were captured from vcvarsall.bat" $Yellow
    }

    # Verify that nmake and cl are available
    # Note: Do NOT call Refresh-Path here as it will overwrite the PATH set by vcvarsall.bat
    $nmakeFound = $false
    try {
        $nmakeTest = Get-Command nmake -ErrorAction SilentlyContinue
        if ($nmakeTest) {
            $nmakeVersion = & nmake /? 2>&1 | Select-Object -First 1
            Write-ColorOutput "NMake is available: $nmakeVersion" $Green
            $nmakeFound = $true
        }
    } catch {
        # Silently continue to the error message below
    }
    
    if (-not $nmakeFound) {
        Write-ColorOutput "Error: NMake not found in PATH. Make sure Visual Studio is properly installed and configured." $Red
        Write-ColorOutput "You may need to install Visual Studio with C++ tools." $Yellow
        Write-ColorOutput ""
        Write-ColorOutput "To install Visual Studio with C++ tools:" $Yellow
        Write-ColorOutput "1. Download Visual Studio from https://visualstudio.microsoft.com/downloads/" $Yellow
        Write-ColorOutput "2. Run the installer and select 'Desktop development with C++'" $Yellow
        Write-ColorOutput "3. Make sure 'MSVC v143 - VS 2022 C++ x64/x86 build tools' is checked" $Yellow
        Write-ColorOutput "4. Complete the installation and re-run this script" $Yellow
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
Write-ColorOutput "" $Green
# Permanently add Qt bin to User PATH
$currentUserPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
if ($currentUserPath -notlike "*${QtPath}\bin*") {
    $newUserPath = "$currentUserPath;${QtPath}\bin"
    [System.Environment]::SetEnvironmentVariable("Path", $newUserPath, "User")
    Write-ColorOutput "Permanently added Qt bin to User PATH: ${QtPath}\bin" $Green
} else {
    Write-ColorOutput "Qt bin already in User PATH: ${QtPath}\bin" $Yellow
}
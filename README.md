# Quickshell Bar

A customizable status bar for both Hyprland (Linux) and Windows systems.

## Hyprland (Linux) Setup

### Prerequisites

- Hyprland window manager
- Quickshell
- Qt 6
- PulseAudio (for volume display)

### Installation

1. Clone this repository
2. Run Quickshell with the linux directory:
   ```bash
   quickshell -p /path/to/quickshell-bar/linux
   ```

### Features

- **Logo**: Displays a custom icon (arch-mauve.svg)
- **Media Info**: Shows currently playing music from MPRIS-compatible players (Spotify, VLC, etc.)
- **Workspaces**: Interactive workspace indicators (1-10) with smooth animations
- **Time/Date**: Current time and date display
- **Volume**: Real-time volume display with instant updates via PulseAudio events

### Configuration

Edit `linux/shell.qml` to customize:

- Colors (border, workspace indicators)
- Panel height and margins
- Time/date format
- Workspace count
- Font sizes

Customize fonts and icons in `linux/Globals.qml`.

## Windows Setup

### Prerequisites

- Qt 6.5 or later with QML development tools
- CMake 3.16 or later
- Visual Studio 2019 or later with C++ desktop development workload
- Windows 10/11

### Quick Build

Use the automated build script:

```powershell
cd path\to\quickshell-bar\windows
.\build.ps1
```

The script will configure, build, and set up everything automatically.

### Running the Application (Windows)

After building, run:

```powershell
cd path\to\quickshell-bar\windows
$env:QML2_IMPORT_PATH = "$PWD"
qml .\windows.qml
```

### Windows Features

- Click on workspace indicators to switch virtual desktops
- The bar automatically tracks which desktop you're on
- Works with Windows 10/11 virtual desktops

### Documentation

- **[BUILD.md](windows/BUILD.md)** - Detailed build instructions (automated and manual)
- **[PLUGIN_QUICK_START.md](windows/PLUGIN_QUICK_START.md)** - 5-minute plugin usage guide
- **[PLUGIN_USAGE.md](windows/PLUGIN_USAGE.md)** - Comprehensive plugin documentation

### Troubleshooting (Windows)

If the plugin doesn't load:

1. Make sure Qt bin directory is in your PATH
2. Verify the plugin DLL was built successfully
3. Check that qmldir file is in the same directory as the DLL
4. Run with `QML_IMPORT_TRACE=1` to see import debugging
5. See [PLUGIN_USAGE.md](windows/PLUGIN_USAGE.md#troubleshooting) for more help

## License

See LICENSE file for details.

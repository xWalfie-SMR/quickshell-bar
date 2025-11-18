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
2. Ensure `arch-mauve.svg` is in the same directory as `shell.qml`
3. Run Quickshell:
   ```bash
   quickshell -p /path/to/quickshell-bar
   ```

### Features

- **Logo**: Displays a custom icon (arch-mauve.svg)
- **Media Info**: Shows currently playing music from MPRIS-compatible players (Spotify, VLC, etc.)
- **Workspaces**: Interactive workspace indicators (1-10) with smooth animations
- **Time/Date**: Current time and date display
- **Volume**: Real-time volume display with instant updates via PulseAudio events

### Configuration

Edit `shell.qml` to customize:

- Colors (border, workspace indicators)
- Panel height and margins
- Time/date format
- Workspace count
- Font sizes

## Windows Setup

### Prerequisites

- Qt 6.5 or later with QML development tools
- CMake 3.16 or later
- Visual Studio 2019 or later with C++ desktop development workload
- Windows 10/11

### Build Steps

1. **Open Developer Command Prompt for Visual Studio**

   ```
   Start Menu -> Visual Studio 2022 -> Developer Command Prompt for VS 2022
   ```

2. **Navigate to the plugin directory**

   ```cmd
   cd path\to\quickshell-bar\windows\VirtualDesktopPlugin
   ```

3. **Create build directory**

   ```cmd
   mkdir build
   cd build
   ```

4. **Configure with CMake**

   ```cmd
   cmake .. -G "NMake Makefiles" -DCMAKE_PREFIX_PATH="C:\Qt\6.5.0\msvc2019_64"
   ```

   _Note: Adjust the Qt path to match your Qt installation_

5. **Build the plugin**

   ```cmd
   nmake
   ```

6. **Copy the plugin to QML imports directory**

   From the build directory, copy the built files:

   ```cmd
   copy VirtualDesktopPlugin.dll ..\VirtualDesktop\
   copy qmldir ..\VirtualDesktop\
   ```

   The plugin files should now be in `quickshell-bar\windows\VirtualDesktop\` alongside the qmldir file.

### Running the Application (Windows)

After building, run:

```powershell
cd path\to\quickshell-bar\windows
$env:QML2_IMPORT_PATH = "$PWD"
qml .\windows.qml
```

### Windows Features

- Click on workspace indicators to switch virtual desktops (uses Win+Ctrl+Number)
- The bar will automatically track which desktop you're on
- Works with Windows 10/11 virtual desktops

### Troubleshooting (Windows)

If the plugin doesn't load:

1. Make sure Qt bin directory is in your PATH
2. Verify the plugin DLL was built successfully
3. Check that qmldir file is in the same directory as the DLL
4. Run with `QML_IMPORT_TRACE=1` to see import debugging

## License

See LICENSE file for details.

# Windows Build Instructions

## Prerequisites

- Qt 6.5 or later with QML development tools
- CMake 3.16 or later
- Visual Studio 2019 or later with C++ desktop development workload
- Windows 10/11
- Administrator privileges (required for the build script)

## Automatic Build (Recommended)

The easiest way to build is using the provided PowerShell script:

### Using PowerShell Script

1. **Open PowerShell as Administrator**
   
   Right-click on PowerShell and select "Run as administrator"

2. **Navigate to the windows directory**

   ```powershell
   cd path\to\quickshell-bar\windows
   ```

3. **Run the build script**

   ```powershell
   .\build.ps1
   ```

   If you have Qt installed in a non-standard location, specify the path:

   ```powershell
   .\build.ps1 -QtPath "C:\Qt\6.6.0\msvc2022_64"
   ```

4. **Clean and rebuild (if needed)**

   ```powershell
   .\build.ps1 -Clean
   ```

The script will:
- Configure the project with CMake
- Build the VirtualDesktopPlugin
- Copy the compiled plugin to the `VirtualDesktop` directory
- Display instructions for running the application

## Manual Build

If you prefer to build manually:

1. **Open Developer Command Prompt for Visual Studio**

   Start Menu → Visual Studio 2022 → Developer Command Prompt for VS 2022

2. **Navigate to the plugin directory**

   ```cmd
   cd path\to\quickshell-bar\windows\VirtualDesktopPlugin
   ```

3. **Create and enter build directory**

   ```cmd
   mkdir build
   cd build
   ```

4. **Configure with CMake**

   ```cmd
   cmake .. -G "NMake Makefiles" -DCMAKE_PREFIX_PATH="C:\Qt\6.5.0\msvc2019_64"
   ```

   _Note: Adjust the Qt path to match your installation_

5. **Build the plugin**

   ```cmd
   nmake
   ```

6. **Copy the built files**

   ```cmd
   copy VirtualDesktopPlugin.dll ..\VirtualDesktop\
   copy qmldir ..\VirtualDesktop\
   ```

## Running the Application

After a successful build:

1. **Set the QML import path**

   ```powershell
   $env:QML2_IMPORT_PATH = "$PWD"
   ```

2. **Run the application**

   ```powershell
   qml .\windows.qml
   ```

## Features

- **Virtual Desktop Indicators**: Click on the desktop indicators to switch between virtual desktops
- **Time and Date Display**: Shows current time and date in the status bar
- **Themed UI**: Matches the Linux Hyprland variant with Catppuccin Mauve theme

## Troubleshooting

### Plugin doesn't load

1. Make sure Qt bin directory is in your PATH
2. Verify the plugin DLL was built successfully
3. Check that `qmldir` file is in the same directory as the DLL
4. Run with debug flag to see import errors:

   ```powershell
   $env:QML_IMPORT_TRACE = "1"
   qml .\windows.qml
   ```

### CMake configuration fails

- Verify Qt installation path is correct
- Make sure CMake is installed and in your PATH
- Try cleaning and rebuilding:

   ```powershell
   .\build.ps1 -Clean
   ```

### Build fails with compiler errors

- Check that Visual Studio is properly installed with C++ tools
- Run the Developer Command Prompt to ensure environment variables are set
- Check that your Qt version matches the CMakeLists.txt configuration

## Building for Different Visual Studio Versions

Modify the CMake generator in the build script:

- **Visual Studio 2022**: Use `"NMake Makefiles"` (default)
- **Visual Studio 2019**: Use `"NMake Makefiles"` with `msvc2019_64` Qt path
- **Visual Studio 2017**: Use `"NMake Makefiles"` with `msvc2017_64` Qt path

## Environment Variables

- `QML2_IMPORT_PATH`: Set this to the windows directory for QML to find the plugin
- `QML_IMPORT_TRACE`: Set to "1" for verbose import debugging

## Development

The C++ plugin source code is located in:
- `VirtualDesktopPlugin/virtualdesktopmanager.h` - Header file
- `VirtualDesktopPlugin/virtualdesktopmanager.cpp` - Implementation
- `VirtualDesktopPlugin/plugin.cpp` - Plugin entry point

The QML interface is in:
- `windows.qml` - Main application UI

## License

See LICENSE file in the project root for details.

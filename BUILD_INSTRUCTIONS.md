# Virtual Desktop Plugin Build Instructions

## Prerequisites

- Qt 6.5 or later with QML development tools
- CMake 3.16 or later
- Visual Studio 2019 or later with C++ desktop development workload
- Windows 10/11

## Build Steps

1. **Open Developer Command Prompt for Visual Studio**

   ```
   Start Menu -> Visual Studio 2022 -> Developer Command Prompt for VS 2022
   ```

2. **Navigate to the plugin directory**

   ```cmd
   cd C:\Users\1SMRA-aaljalk223\Documents\quickshell-bar\VirtualDesktopPlugin
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
   ```cmd
   mkdir "%USERPROFILE%\Documents\quickshell-bar\VirtualDesktop"
   copy VirtualDesktopPlugin.dll "%USERPROFILE%\Documents\quickshell-bar\VirtualDesktop\"
   copy qmldir "%USERPROFILE%\Documents\quickshell-bar\VirtualDesktop\"
   ```

## Running the Application

After building, run:

```powershell
cd C:\Users\1SMRA-aaljalk223\Documents\quickshell-bar
$env:QML2_IMPORT_PATH = "$PWD"
qml .\windows.qml
```

## Usage

- Click on workspace indicators to switch virtual desktops (uses Win+Ctrl+Number)
- The bar will automatically track which desktop you're on
- Works with Windows 10/11 virtual desktops

## Troubleshooting

If the plugin doesn't load:

1. Make sure Qt bin directory is in your PATH
2. Verify the plugin DLL was built successfully
3. Check that qmldir file is in the same directory as the DLL
4. Run with `QML_IMPORT_TRACE=1` to see import debugging

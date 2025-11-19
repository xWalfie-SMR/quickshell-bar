# Windows QML Plugin Documentation

This document explains where to find documentation and how to use the VirtualDesktopPlugin with the Quickshell Bar Windows variant.

## Documentation Files

### [PLUGIN_QUICK_START.md](PLUGIN_QUICK_START.md) - **Start here!**

A 5-minute quick start guide with the essentials to get you running:

- How to import the plugin
- How to create a manager instance
- 5 common tasks with code examples
- Key points to remember
- Quick snippets for common operations

**Best for**: Developers who want to get started quickly and understand the basics in minutes.

### [PLUGIN_USAGE.md](PLUGIN_USAGE.md) - **Complete Reference**

Comprehensive documentation covering everything about the VirtualDesktopPlugin:

- Overview and capabilities
- Plugin setup and environment configuration
- Complete API reference (properties, methods, signals)
- Detailed examples with explanations
- Performance considerations and optimization tips
- Troubleshooting section
- Full integration example

**Best for**: Developers building complex features and needing detailed reference material.

### [BUILD.md](BUILD.md) - **Build Instructions**

Instructions for building the VirtualDesktopPlugin:

- Automatic build using PowerShell script (recommended)
- Manual build steps
- Running the application
- Troubleshooting build failures
- Development setup

**Best for**: Getting the plugin compiled and ready to use.

### [../README.md](../README.md) - **Project Overview**

Main project documentation covering both Linux and Windows variants with links to all resources.

**Best for**: Project overview and understanding the complete Quickshell Bar system.

## Quick Navigation

### I want to...

#### **...get started immediately**
→ Read [PLUGIN_QUICK_START.md](PLUGIN_QUICK_START.md) (5 minutes)

#### **...understand what the plugin can do**
→ Start with [PLUGIN_USAGE.md Overview](PLUGIN_USAGE.md#overview) section

#### **...use the plugin in my QML code**
→ Check [PLUGIN_USAGE.md Properties](PLUGIN_USAGE.md#properties) and [PLUGIN_USAGE.md Methods](PLUGIN_USAGE.md#methods)

#### **...build the plugin**
→ Follow [BUILD.md Automatic Build](BUILD.md#automatic-build-recommended) section

#### **...see working code**
→ Look at [windows.qml](windows.qml) for the complete working example

#### **...fix a build problem**
→ Check [BUILD.md Troubleshooting](BUILD.md#troubleshooting)

#### **...fix a plugin loading issue**
→ See [PLUGIN_USAGE.md Troubleshooting](PLUGIN_USAGE.md#troubleshooting)

#### **...optimize performance**
→ Read [PLUGIN_USAGE.md Performance Considerations](PLUGIN_USAGE.md#performance-considerations)

## Key Concepts

### Plugin Architecture

The VirtualDesktopPlugin consists of:

1. **C++ Backend** (`VirtualDesktopPlugin.dll`)
   - Compiled Qt QML plugin
   - Exposes `VirtualDesktopManager` class to QML
   - Uses Win32 APIs to interact with Windows virtual desktops

2. **QML Module** (`VirtualDesktop`)
   - Imported in QML with `import VirtualDesktop 1.0`
   - Provides `VirtualDesktopManager` type

3. **Module Metadata** (`qmldir`)
   - Tells Qt QML engine how to load the plugin
   - Located in `VirtualDesktop/` directory alongside the DLL

### Workflow

```
┌─────────────────────────────────────────────┐
│ 1. Build the plugin (build.ps1)             │
│    → Compiles C++ code to VirtualDesktopPlugin.dll
└─────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────┐
│ 2. Set environment (QML2_IMPORT_PATH)       │
│    → Tells Qt where to find the plugin
└─────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────┐
│ 3. Import in QML (import VirtualDesktop 1.0)│
│    → Makes the plugin available to QML code
└─────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────┐
│ 4. Use in QML (VirtualDesktopManager)       │
│    → Create instances and bind to properties
└─────────────────────────────────────────────┘
```

## Common Tasks with Examples

### Display Virtual Desktop Indicators

```qml
import VirtualDesktop 1.0

Row {
    spacing: 10

    VirtualDesktopManager {
        id: windowManager
    }

    Repeater {
        model: windowManager.desktops

        Rectangle {
            width: modelData.isActive ? 60 : 20
            height: 20
            color: modelData.isActive ? "blue" : "gray"
            radius: 10

            MouseArea {
                anchors.fill: parent
                onClicked: windowManager.switchToDesktop(index)
            }
        }
    }
}
```

### React to Desktop Changes

```qml
VirtualDesktopManager {
    id: windowManager

    onCurrentDesktopChanged: {
        console.log("Switched to desktop: " + (currentDesktop + 1))
        // Update UI or perform other actions
    }

    onActiveWindowChanged: {
        console.log("Active window: " + activeWindowTitle)
    }
}
```

### Display Current Status

```qml
Column {
    spacing: 10

    Text {
        text: "Desktop: " + (windowManager.currentDesktop + 1) + "/" + windowManager.desktops.length
    }

    Text {
        text: "Active: " + windowManager.activeWindowTitle
    }

    Text {
        text: "Total windows: " + windowManager.windows.length
    }
}
```

## Plugin Properties Reference

| Property | Type | Description |
|----------|------|-------------|
| `desktops` | QVariantList | List of desktop objects, each with `index` and `isActive` |
| `currentDesktop` | int | Index (0-based) of currently active desktop |
| `windows` | QVariantList | List of open window objects |
| `activeWindowTitle` | string | Title of the currently active window |

## Plugin Methods Reference

| Method | Parameters | Description |
|--------|-----------|-------------|
| `switchToDesktop` | int index | Switch to desktop at index (0-based) |
| `activateWindow` | int index | Activate window at index |

## Debugging Tips

### Enable verbose logging

```powershell
$env:QML_IMPORT_TRACE = "1"
qml .\windows.qml
```

This shows which modules Qt is trying to load and where it's looking for them.

### Check if plugin loads

```qml
import VirtualDesktop 1.0

Window {
    Component.onCompleted: {
        console.log("Plugin loaded successfully!")
    }
}
```

### Monitor property changes

```qml
VirtualDesktopManager {
    id: windowManager

    onDesktopsChanged: console.log("Desktops changed:", desktops.length)
    onCurrentDesktopChanged: console.log("Active desktop:", currentDesktop)
    onWindowsChanged: console.log("Windows count:", windows.length)
    onActiveWindowChanged: console.log("Window changed:", activeWindowTitle)
}
```

## What's Inside the Plugin

### Class: VirtualDesktopManager

Exposed to QML as `VirtualDesktopManager` type.

**Location**: `VirtualDesktopPlugin/virtualdesktopmanager.h` and `.cpp`

**Capabilities**:
- Queries Windows virtual desktop information
- Tracks active desktop and window
- Provides methods to switch desktops
- Emits signals when state changes
- Updates approximately every 500ms

### Entry Point

**Location**: `VirtualDesktopPlugin/plugin.cpp`

Registers the `VirtualDesktopManager` class with Qt's QML engine.

## Integration with Quickshell Bar

The main Quickshell Bar application (`windows.qml`) demonstrates full integration:

1. **Imports the plugin**
   ```qml
   import VirtualDesktop 1.0
   ```

2. **Creates a manager instance**
   ```qml
   VirtualDesktopManager {
       id: windowManager
   }
   ```

3. **Uses desktop indicators**
   ```qml
   Repeater {
       model: windowManager.desktops
       // Creates animated indicators for each desktop
   }
   ```

4. **Handles clicks to switch desktops**
   ```qml
   MouseArea {
       onClicked: windowManager.switchToDesktop(index)
   }
   ```

5. **Displays status information**
   ```qml
   Text {
       text: Qt.formatDateTime(new Date(), "ddd dd/MM")
   }
   ```

## Support

For issues or questions:

1. Check the [Troubleshooting section](PLUGIN_USAGE.md#troubleshooting) in PLUGIN_USAGE.md
2. Review the [BUILD.md Troubleshooting](BUILD.md#troubleshooting) for build issues
3. Enable `QML_IMPORT_TRACE=1` for debugging
4. Check Windows Event Viewer for permission issues
5. Verify all prerequisites are installed

## File Structure

```
quickshell-bar/
├── windows/
│   ├── PLUGIN_QUICK_START.md          ← 5-minute guide
│   ├── PLUGIN_USAGE.md                ← Complete reference
│   ├── BUILD.md                       ← Build instructions
│   ├── WINDOWS_QML_DOCUMENTATION.md   ← This file
│   ├── windows.qml                    ← Main QML application
│   ├── VirtualDesktop/
│   │   ├── VirtualDesktopPlugin.dll   ← Compiled plugin (after build)
│   │   └── qmldir                     ← Module metadata
│   ├── VirtualDesktopPlugin/
│   │   ├── CMakeLists.txt
│   │   ├── plugin.cpp
│   │   ├── virtualdesktopmanager.h
│   │   └── virtualdesktopmanager.cpp
│   └── build.ps1                      ← Build script
├── README.md                          ← Project overview
└── ...
```

## License

See LICENSE file in the project root.

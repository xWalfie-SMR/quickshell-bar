# VirtualDesktopPlugin Usage Guide for Windows QML

This guide explains how to use the `VirtualDesktopPlugin` in your Windows QML applications to interact with virtual desktops and manage windows.

## Overview

The `VirtualDesktopPlugin` is a Qt C++ plugin that provides QML bindings to interact with Windows virtual desktops and active window information. It exposes the `VirtualDesktopManager` class to QML, allowing you to:

- Query the list of available virtual desktops
- Determine which desktop is currently active
- Switch between virtual desktops programmatically
- Retrieve information about open windows
- Get the title of the currently active window

## Plugin Setup

### Prerequisites

Before using the plugin, ensure:

1. The plugin has been built (see [BUILD.md](BUILD.md) for build instructions)
2. The compiled `VirtualDesktopPlugin.dll` is in the `VirtualDesktop/` directory
3. The `qmldir` file is in the `VirtualDesktop/` directory
4. The `QML2_IMPORT_PATH` environment variable includes the parent directory of `VirtualDesktop/`

### Environment Setup

To run a QML application using this plugin, set the import path:

```powershell
# Navigate to the windows directory
cd path\to\quickshell-bar\windows

# Set the QML import path
$env:QML2_IMPORT_PATH = "$PWD"

# Run your QML application
qml .\windows.qml
```

Alternatively, use the `-I` flag with the qml command:

```powershell
qml -I . .\windows.qml
```

## Import and Basic Usage

### Importing the Plugin

In your QML file, import the VirtualDesktop module:

```qml
import VirtualDesktop 1.0
```

### Creating an Instance

Create an instance of `VirtualDesktopManager`:

```qml
VirtualDesktopManager {
    id: windowManager
}
```

## Properties

The `VirtualDesktopManager` exposes the following properties:

### `desktops` (QVariantList, read-only)

A list of desktop objects. Each desktop object has:
- `index`: Integer index of the desktop (0-based)
- `isActive`: Boolean indicating if the desktop is currently active

**Example:**

```qml
VirtualDesktopManager {
    id: windowManager
}

Column {
    spacing: 10

    Repeater {
        model: windowManager.desktops

        Rectangle {
            width: 40
            height: 40
            color: modelData.isActive ? "blue" : "gray"
            radius: 5

            MouseArea {
                anchors.fill: parent
                onClicked: windowManager.switchToDesktop(index)
            }

            Text {
                anchors.centerIn: parent
                text: modelData.index + 1
                color: "white"
            }
        }
    }
}
```

### `currentDesktop` (int, read-only)

The index of the currently active desktop (0-based).

**Example:**

```qml
Text {
    text: "Current Desktop: " + (windowManager.currentDesktop + 1)
}
```

### `windows` (QVariantList, read-only)

A list of open window objects. Each window object contains window information (for future expansion).

**Example:**

```qml
Text {
    text: "Open windows: " + windowManager.windows.length
}
```

### `activeWindowTitle` (string, read-only)

The title of the currently active window.

**Example:**

```qml
Text {
    text: "Active window: " + windowManager.activeWindowTitle
    color: "white"
}
```

## Methods

The `VirtualDesktopManager` provides the following invokable methods:

### `switchToDesktop(int index)`

Switch to a specific virtual desktop by index (0-based).

**Parameters:**
- `index` (int): The 0-based index of the desktop to switch to

**Example:**

```qml
Rectangle {
    MouseArea {
        anchors.fill: parent
        onClicked: windowManager.switchToDesktop(0)  // Switch to first desktop
    }
}

Button {
    text: "Go to Desktop 3"
    onClicked: windowManager.switchToDesktop(2)  // Switch to third desktop
}
```

### `activateWindow(int index)`

Activate a specific window by index (for future use).

**Parameters:**
- `index` (int): The window index to activate

**Example:**

```qml
Button {
    text: "Activate Window"
    onClicked: windowManager.activateWindow(0)
}
```

## Signals

The `VirtualDesktopManager` emits the following signals when properties change:

- `desktopsChanged()`: Emitted when the desktop list changes
- `currentDesktopChanged()`: Emitted when the active desktop changes
- `windowsChanged()`: Emitted when the window list changes
- `activeWindowChanged()`: Emitted when the active window changes

**Example:**

```qml
VirtualDesktopManager {
    id: windowManager

    onCurrentDesktopChanged: {
        console.log("Switched to desktop: " + (currentDesktop + 1))
    }

    onActiveWindowChanged: {
        console.log("Active window: " + activeWindowTitle)
    }
}
```

## Complete Example

Here's a complete example showing how to build a simple desktop switcher:

```qml
pragma ComponentBehavior: Bound
import QtQuick 6.5
import QtQuick.Window 6.5
import VirtualDesktop 1.0

Window {
    id: root
    visible: true
    width: 400
    height: 100
    title: "Virtual Desktop Switcher"

    VirtualDesktopManager {
        id: desktopManager
    }

    Rectangle {
        anchors.fill: parent
        color: "#1e1e2e"
        border.color: "#cba6f7"
        border.width: 2
        radius: 8

        Column {
            anchors.centerIn: parent
            spacing: 15

            Text {
                text: "Current Desktop: " + (desktopManager.currentDesktop + 1)
                color: "white"
                font.pixelSize: 18
            }

            Row {
                spacing: 10
                anchors.horizontalCenter: parent.horizontalCenter

                Repeater {
                    model: desktopManager.desktops

                    Rectangle {
                        width: 50
                        height: 50
                        color: modelData.isActive ? "#cba6f7" : "#45475a"
                        radius: 5

                        Text {
                            anchors.centerIn: parent
                            text: modelData.index + 1
                            color: modelData.isActive ? "#1e1e2e" : "white"
                            font.bold: true
                            font.pixelSize: 16
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: desktopManager.switchToDesktop(modelData.index)
                        }
                    }
                }
            }

            Text {
                text: "Active: " + desktopManager.activeWindowTitle
                color: "#cba6f7"
                font.pixelSize: 12
                elide: Text.ElideRight
                width: 350
            }
        }
    }
}
```

## Performance Considerations

### Update Frequency

The `VirtualDesktopManager` updates desktop and window information approximately every 500ms (configurable in the C++ implementation). This balance ensures:

- Responsive UI updates
- Low CPU usage
- Minimal system impact

### Optimization Tips

1. **Use Repeater for Dynamic Lists**: Use `Repeater` for desktop indicators instead of manually creating components
2. **Bind Only What You Need**: Only bind to properties you actually use
3. **Debounce Updates**: If you need real-time information, consider debouncing rapid changes

**Example with debouncing:**

```qml
VirtualDesktopManager {
    id: desktopManager

    onCurrentDesktopChanged: {
        updateTimer.restart()
    }
}

Timer {
    id: updateTimer
    interval: 100
    running: false
    repeat: false

    onTriggered: {
        console.log("Desktop changed to: " + (desktopManager.currentDesktop + 1))
        // Perform expensive operations here
    }
}
```

## Troubleshooting

### Plugin Fails to Load

**Error:** `module "VirtualDesktop" is not installed`

**Solution:**
1. Verify the plugin DLL was built successfully
2. Check that `VirtualDesktop/qmldir` exists alongside the DLL
3. Set `QML2_IMPORT_PATH` correctly:
   ```powershell
   $env:QML2_IMPORT_PATH = "$PWD"
   qml -I . .\windows.qml
   ```

### Plugin Doesn't Respond

**Error:** `VirtualDesktopManager` is instantiated but no changes are detected

**Solution:**
1. Ensure the application has permissions to query desktop information
2. Run the application with administrative privileges if needed
3. Check Windows Event Viewer for permission-related errors

### Properties Don't Update

**Error:** Properties remain static and don't reflect desktop changes

**Solution:**
1. Verify the application has focus and is not minimized
2. Check that signals are properly connected (`onCurrentDesktopChanged`, etc.)
3. Monitor with debug output:
   ```qml
   onCurrentDesktopChanged: console.log("Desktop changed!")
   ```

## Integration with Quickshell Bar

The main Quickshell Bar application (`windows.qml`) demonstrates a complete integration:

```qml
VirtualDesktopManager {
    id: windowManager
}

// Desktop indicators with animations
Repeater {
    model: windowManager.desktops

    Rectangle {
        width: modelData.isActive ? 60 : 20
        height: 20
        radius: 10
        color: modelData.isActive ? "#cba6f7" : "#45475a"

        Behavior on width {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutCubic
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                windowManager.switchToDesktop(index)
            }
        }
    }
}
```

## API Reference

### VirtualDesktopManager

#### Properties

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `desktops` | QVariantList | read-only | List of desktop objects |
| `currentDesktop` | int | read-only | Index of active desktop |
| `windows` | QVariantList | read-only | List of window objects |
| `activeWindowTitle` | string | read-only | Title of active window |

#### Methods

| Method | Parameters | Description |
|--------|-----------|-------------|
| `switchToDesktop` | int index | Switch to specified desktop |
| `activateWindow` | int index | Activate specified window |

#### Signals

| Signal | Description |
|--------|-------------|
| `desktopsChanged()` | Desktop list changed |
| `currentDesktopChanged()` | Active desktop changed |
| `windowsChanged()` | Window list changed |
| `activeWindowChanged()` | Active window changed |

## See Also

- [BUILD.md](BUILD.md) - Build instructions
- [../README.md](../README.md) - Main project readme
- [Qt QML Documentation](https://doc.qt.io/qt-6/qml-index.html)
- [Windows Virtual Desktops API](https://learn.microsoft.com/en-us/windows/win32/shell/virtual-desktop-manager)

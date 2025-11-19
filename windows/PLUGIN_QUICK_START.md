# VirtualDesktopPlugin Quick Start

Get started with the VirtualDesktopPlugin in 5 minutes!

## 1. Import the Plugin

In your QML file:

```qml
import VirtualDesktop 1.0
```

## 2. Create a Manager Instance

```qml
VirtualDesktopManager {
    id: windowManager
}
```

## 3. Use Desktop Indicators

Display clickable desktop indicators:

```qml
Row {
    spacing: 10

    Repeater {
        model: windowManager.desktops

        Rectangle {
            width: modelData.isActive ? 60 : 20
            height: 20
            radius: 10
            color: modelData.isActive ? "blue" : "gray"

            MouseArea {
                anchors.fill: parent
                onClicked: windowManager.switchToDesktop(index)
            }
        }
    }
}
```

## 4. Display Current Desktop

```qml
Text {
    text: "Desktop: " + (windowManager.currentDesktop + 1)
}
```

## 5. Show Active Window Title

```qml
Text {
    text: "Active: " + windowManager.activeWindowTitle
}
```

## 6. React to Changes

```qml
VirtualDesktopManager {
    id: windowManager

    onCurrentDesktopChanged: {
        console.log("Now on desktop " + (currentDesktop + 1))
    }
}
```

## Key Points

- **Desktops are 0-based**: Desktop 1 = index 0, Desktop 2 = index 1, etc.
- **Set the import path**: `$env:QML2_IMPORT_PATH = "$PWD"`
- **Build first**: Run `build.ps1` before using the plugin
- **Always check `isActive`**: Use `modelData.isActive` to style active desktop differently

## Common Task Snippets

### Switch to Desktop 3
```qml
windowManager.switchToDesktop(2)  // Note: 0-based index
```

### Disable Desktop Switching
```qml
Rectangle {
    MouseArea {
        anchors.fill: parent
        onClicked: {
            // Do nothing - prevents desktop switching
        }
    }
}
```

### Add Desktop Labels
```qml
Text {
    text: (index + 1)  // Shows 1, 2, 3, ... instead of 0, 1, 2, ...
    color: modelData.isActive ? "white" : "gray"
}
```

### Monitor Window Changes
```qml
VirtualDesktopManager {
    id: windowManager

    onWindowsChanged: {
        console.log("Windows count: " + windows.length)
    }

    onActiveWindowChanged: {
        console.log("Window changed: " + activeWindowTitle)
    }
}
```

## Next Steps

- Read [PLUGIN_USAGE.md](PLUGIN_USAGE.md) for comprehensive documentation
- Check [BUILD.md](BUILD.md) for build troubleshooting
- See [windows.qml](windows.qml) for a complete working example

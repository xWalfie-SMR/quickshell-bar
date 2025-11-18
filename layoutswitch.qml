import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick

ShellRoot {
    id: root

    property var layouts: ["us", "es", "es:nodeadkeys"]
    property var layoutNames: ["English | US", "Español | ES", "Español | NDK"]
    property int currentIndex: 0
    property bool showPopup: false
    property string lastContent: ""

    // TEST MODE: Show on startup
    Component.onCompleted: {
        console.log("Component loaded, showing test popup")
        showPopup = true
    }

    // Poll for trigger file changes
    Timer {
        interval: 100
        running: true
        repeat: true
        onTriggered: {
            // Restart the process each time to read fresh content
            if (!triggerCheck.running) {
                triggerCheck.running = true
            }
        }
    }

    Process {
        id: triggerCheck
        command: ["cat", "/tmp/quickshell_layout_trigger"]
        running: false
        
        stdout: SplitParser {
            onRead: data => {
                var content = data.trim()
                console.log("Read from trigger file:", content)
                
                if (content && content !== root.lastContent) {
                    console.log("Triggering layout cycle")
                    root.lastContent = content
                    root.cycleLayout()
                }
                
                // Stop the process after reading
                triggerCheck.running = false
            }
        }
    }

    // Process for setting keyboard layout
    Process {
        id: setLayout
        running: false
    }

    // Process for setting keyboard variant
    Process {
        id: setVariant
        running: false
    }

    function cycleLayout() {
        console.log("Cycling layout...")
        
        // Cycle to next layout
        currentIndex = (currentIndex + 1) % layouts.length
        console.log("New index:", currentIndex, "Layout:", layouts[currentIndex])
        
        // Apply layout
        var layout = layouts[currentIndex]
        if (layout.includes(":")) {
            var parts = layout.split(":")
            // Set layout
            setLayout.command = ["hyprctl", "keyword", "input:kb_layout", parts[0]]
            setLayout.running = true
            // Set variant
            setVariant.command = ["hyprctl", "keyword", "input:kb_variant", parts[1]]
            setVariant.running = true
        } else {
            // Set layout
            setLayout.command = ["hyprctl", "keyword", "input:kb_layout", layout]
            setLayout.running = true
            // Clear variant
            setVariant.command = ["hyprctl", "keyword", "input:kb_variant", ""]
            setVariant.running = true
        }
        
        // Show popup
        console.log("Showing popup")
        showPopup = true
        hideTimer.restart()
    }

    // Auto-hide timer
    Timer {
        id: hideTimer
        interval: 1500
        repeat: false
        onTriggered: {
            console.log("Hiding popup")
            root.showPopup = false
        }
    }

    // Popup window with custom title
    FloatingWindow {
        id: popup
        visible: root.showPopup
        title: "quickshell-layout-popup"
        
        width: 300
        height: 240
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            color: '#11111b'
            border.color: '#cba6f7'
            border.width: 3
            radius: 12

            Column {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 10

                // Header with keyboard icon
                Rectangle {
                    width: parent.width
                    height: 50
                    color: '#89b4fa'
                    radius: 8

                    Text {
                        anchors.centerIn: parent
                        text: "⌨"
                        color: '#11111b'
                        font.pixelSize: 24
                        font.family: "JetBrains Mono Nerd Font"
                    }
                }

                // Layout options
                Repeater {
                    model: root.layoutNames

                    Rectangle {
                        width: parent.width
                        height: 45
                        color: index === root.currentIndex ? '#cba6f7' : '#313244'
                        radius: 8

                        Behavior on color {
                            ColorAnimation {
                                duration: 200
                                easing.type: Easing.OutCubic
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: modelData
                            color: index === root.currentIndex ? '#11111b' : '#eff1f5'
                            font.pixelSize: 14
                            font.family: "JetBrains Mono Nerd Font"

                            Behavior on color {
                                ColorAnimation {
                                    duration: 200
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
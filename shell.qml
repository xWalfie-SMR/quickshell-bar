import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Hyprland
import QtQuick
import QtMultimedia

ShellRoot {
    PanelWindow {
        anchors {
            top: true
            left: true
            right: true
        }
        margins {
            left: 15
            right: 15
            top: 15
        }
        height: 50
        color: "transparent"

        // Border + Background Rectangle
        Rectangle {
            anchors.fill: parent
            color: '#1e1e2e'
            border.color: '#cba6f7'
            border.width: 5
            radius: 16
        }

        // Logo
        Image {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 15
            source: "./arch-mauve.svg"
            width: 24
            height: 24
        }

        // Media Info
        Item {
            id: mediaInfo
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 50
            width: parent.width / 6
            height: parent.height
            
            property var currentPlayer: Mpris.players.values[0] || null
            
            // Update currentPlayer when players change
            Text {
                text: {
                    if (parent.currentPlayer && parent.currentPlayer.metadata) {
                        var artist = parent.currentPlayer.metadata["xesam:artist"] || ""
                        var title = parent.currentPlayer.metadata["xesam:title"] || ""

                        if (Array.isArray(artist)) {
                            artist = artist.join(", ")
                        }

                        if (artist && title) {
                            return artist + " - " + title
                        }
                    }
                    return ""
                }
                color: "white"
                font.pixelSize: 16
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.right: parent.right
                elide: Text.ElideRight
            }
        }

        // Workspaces
        Row {
            id: workspaces
            anchors.left: mediaInfo.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 0
            spacing: 12

            Repeater {
                model: 10 // Number of workspaces

                Rectangle {
                    width: Hyprland.focusedWorkspace.id === (index + 1) ? 30 : 15
                    height: 15
                    radius: 7.5
                    color: Hyprland.focusedWorkspace.id === (index + 1) ? "#cba6f7" : "#45475a"

                    // Smooth animation for width changes
                    Behavior on width {
                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.OutCubic
                        }
                    }

                    // Smooth animation for color changes
                    Behavior on color {
                        ColorAnimation {
                            duration: 200
                            easing.type: Easing.OutCubic
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: Hyprland.dispatch("workspace", (index + 1).toString())
                    }
                }
            }
        }

        Item {
            id: time
            anchors.centerIn: parent
            Timer {
                interval: 1000
                running: true
                repeat: true
                onTriggered: timeText.text = Qt.formatDateTime(new Date(), "h:mm a | ddd dd/MM")
            }
            Text {
                id: timeText
                text: Qt.formatDateTime(new Date(), "h:mm a | ddd dd/MM")
                color: "white"
                font.pixelSize: 16
                anchors.centerIn: parent
            }
        }
    }
}
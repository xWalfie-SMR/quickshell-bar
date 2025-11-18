import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick

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
        implicitHeight: 50
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
            anchors.leftMargin: 20
            source: "./arch-mauve.svg"
            width: 24
            height: 24
        }

        // Separator after logo
        Rectangle {
            anchors.left: parent.left
            anchors.leftMargin: 54
            anchors.verticalCenter: parent.verticalCenter
            width: 2
            height: parent.height - 10
            color: "#45475a"
        }

        // Media Info
        Item {
            id: mediaInfo
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 66
            width: parent.width / 6
            height: parent.height
            
            property var currentPlayer: Mpris.players.values[0] || null
            
            // Update currentPlayer when players change
            Row {
                spacing: 10
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 5

                Text {
                    text: "󰎈"
                    color: "#cba6f7"
                    font.pixelSize: 20
                    font.family: Globals.iconFont
                    anchors.verticalCenter: parent.verticalCenter
                    verticalAlignment: Text.AlignVCenter
                }

                Text {
                    text: {
                        if (mediaInfo.currentPlayer && mediaInfo.currentPlayer.metadata) {
                            var artist = mediaInfo.currentPlayer.metadata["xesam:artist"] || ""
                            var title = mediaInfo.currentPlayer.metadata["xesam:title"] || ""

                            if (Array.isArray(artist)) {
                                artist = artist.join(", ")
                            }

                            var fullText = ""
                            if (artist && title) {
                                fullText = artist + " - " + title
                            }
                            return fullText
                        }
                        return "No media playing"
                    }
                    color: "white"
                    font.pixelSize: 16
                    font.family: Globals.fontFamily
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        // Workspaces
        Row {
            id: workspaces
            anchors.centerIn: parent
            anchors.leftMargin: 0
            spacing: 12

            Repeater {
                model: 10 // Number of workspaces

                Rectangle {
                    width: (Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === (index + 1)) ? 60 : 20
                    height: 20
                    radius: 10
                    color: (Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === (index + 1)) ? "#cba6f7" : "#45475a"

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
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.rightMargin: 125
            Timer {
                interval: 1000
                running: true
                repeat: true
                onTriggered: {
                    timeText.text = Qt.formatDateTime(new Date(), "ddd dd/MM")
                    timeHour.text = Qt.formatDateTime(new Date(), "h:mma")
                }
            }
            Row {
                spacing: 10
                anchors.right: parent.right
                anchors.rightMargin: 5
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    text: "󰥔"
                    color: "#cba6f7"
                    font.pixelSize: 20
                    font.family: Globals.iconFont
                    anchors.verticalCenter: parent.verticalCenter
                    verticalAlignment: Text.AlignVCenter
                }

                Text {
                    id: timeHour
                    text: Qt.formatDateTime(new Date(), "h:mma")
                    color: "white"
                    font.pixelSize: 16
                    font.family: Globals.fontFamily
                    anchors.verticalCenter: parent.verticalCenter
                }

                Rectangle {
                    width: 2
                    height: parent.parent.parent.height - 10
                    color: "#45475a"
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    id: timeText
                    text: Qt.formatDateTime(new Date(), "ddd dd/MM")
                    color: "white"
                    font.pixelSize: 16
                    font.family: Globals.fontFamily
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        // Separator before volume
        Rectangle {
            anchors.right: parent.right
            anchors.rightMargin: 110
            anchors.verticalCenter: parent.verticalCenter
            width: 2
            height: parent.height - 10
            color: "#45475a"
        }

        Item {
            id: volume
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.rightMargin: 20
            width: 80
            height: parent.height

            property string volumeLevel: ""

            Process {
                id: volumeProcess
                running: true
                command: ["bash", "-c", "pactl subscribe | grep --line-buffered \"Event 'change' on sink\" | while read -r line; do pactl get-sink-volume @DEFAULT_SINK@ | grep -oE '[0-9]+%' | head -1; done"]
                stdout: SplitParser {
                    onRead: data => {
                        var vol = data.trim().replace('%', '')
                        if (vol) {
                            volume.volumeLevel = vol
                        }
                    }
                }
            }

            Process {
                id: initialVolume
                command: ["bash", "-c", "pactl get-sink-volume @DEFAULT_SINK@ | grep -oE '[0-9]+%' | head -1"]
                stdout: SplitParser {
                    onRead: data => {
                        var vol = data.trim().replace('%', '')
                        if (vol) {
                            volume.volumeLevel = vol
                        }
                    }
                }
            }

            Component.onCompleted: initialVolume.running = true

            Row {
                spacing: 10
                anchors.centerIn: parent

                Text {
                    text: "󰕾"
                    color: "#cba6f7"
                    font.pixelSize: 20
                    font.family: Globals.iconFont
                    anchors.verticalCenter: parent.verticalCenter
                    verticalAlignment: Text.AlignVCenter
                }

                Text {
                    id: volumeText
                    text: volume.volumeLevel ? volume.volumeLevel + "%" : "--"
                    color: "white"
                    font.pixelSize: 16
                    font.family: Globals.fontFamily
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }
}
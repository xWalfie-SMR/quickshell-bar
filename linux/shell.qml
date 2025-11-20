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
            source: "arch-mauve.svg"
            width: 24
            height: 24
        }

        // Separator after logo
        Rectangle {
            id: logoSeparator
            anchors.left: parent.left
            anchors.leftMargin: 54
            anchors.verticalCenter: parent.verticalCenter
            width: 2
            height: parent.height - 10
            color: "#45475a"
        }

        // Media Controls Container (properly sized to center controls)
        Item {
            id: mediaControlsContainer
            anchors.left: logoSeparator.right
            anchors.verticalCenter: parent.verticalCenter
            width: 130
            height: parent.height
            
            property var currentPlayer: Mpris.players.values[0] || null

            Row {
                spacing: 24
                anchors.centerIn: parent
                visible: mediaControlsContainer.currentPlayer !== null

                // Previous button
                Text {
                    text: "󰒮"
                    color: "#cba6f7"
                    font.pixelSize: 20
                    font.family: Globals.iconFont
                    anchors.verticalCenter: parent.verticalCenter
                    verticalAlignment: Text.AlignVCenter
                    opacity: mediaControlsContainer.currentPlayer && mediaControlsContainer.currentPlayer.canGoPrevious ? 1.0 : 0.5
                    
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (mediaControlsContainer.currentPlayer && mediaControlsContainer.currentPlayer.canGoPrevious) {
                                mediaControlsContainer.currentPlayer.previous()
                            }
                        }
                        hoverEnabled: true
                        onEntered: if (mediaControlsContainer.currentPlayer && mediaControlsContainer.currentPlayer.canGoPrevious) parent.opacity = 0.8
                        onExited: parent.opacity = mediaControlsContainer.currentPlayer && mediaControlsContainer.currentPlayer.canGoPrevious ? 1.0 : 0.5
                    }
                }

                // Play/Pause button
                Text {
                    text: mediaControlsContainer.currentPlayer && mediaControlsContainer.currentPlayer.playbackState === MprisPlaybackState.Playing ? "󰏤" : "󰐊"
                    color: "#cba6f7"
                    font.pixelSize: 20
                    font.family: Globals.iconFont
                    anchors.verticalCenter: parent.verticalCenter
                    verticalAlignment: Text.AlignVCenter
                    
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (mediaControlsContainer.currentPlayer) {
                                if (mediaControlsContainer.currentPlayer.playbackState === MprisPlaybackState.Playing) {
                                    if (mediaControlsContainer.currentPlayer.canPause) {
                                        mediaControlsContainer.currentPlayer.pause()
                                    }
                                } else {
                                    if (mediaControlsContainer.currentPlayer.canPlay) {
                                        mediaControlsContainer.currentPlayer.play()
                                    }
                                }
                            }
                        }
                        hoverEnabled: true
                        onEntered: parent.opacity = 0.8
                        onExited: parent.opacity = 1.0
                    }
                }

                // Next button
                Text {
                    text: "󰒭"
                    color: "#cba6f7"
                    font.pixelSize: 20
                    font.family: Globals.iconFont
                    anchors.verticalCenter: parent.verticalCenter
                    verticalAlignment: Text.AlignVCenter
                    opacity: mediaControlsContainer.currentPlayer && mediaControlsContainer.currentPlayer.canGoNext ? 1.0 : 0.5
                    
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (mediaControlsContainer.currentPlayer && mediaControlsContainer.currentPlayer.canGoNext) {
                                mediaControlsContainer.currentPlayer.next()
                            }
                        }
                        hoverEnabled: true
                        onEntered: if (mediaControlsContainer.currentPlayer && mediaControlsContainer.currentPlayer.canGoNext) parent.opacity = 0.8
                        onExited: parent.opacity = mediaControlsContainer.currentPlayer && mediaControlsContainer.currentPlayer.canGoNext ? 1.0 : 0.5
                    }
                }
            }
        }

        // Separator after media controls
        Rectangle {
            id: mediaControlsSeparator
            anchors.left: mediaControlsContainer.right
            anchors.verticalCenter: parent.verticalCenter
            width: 2
            height: parent.height - 10
            color: "#45475a"
            visible: mediaControlsContainer.currentPlayer !== null
        }

        // Media Info (song text)
        Item {
            id: mediaInfo
            anchors.left: mediaControlsSeparator.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 10
            width: parent.width / 3 - 20
            height: parent.height
            
            property var currentPlayer: Mpris.players.values[0] || null
            
            // Function to truncate text
            function truncateText(text, maxLength) {
                if (text.length <= maxLength) return text
                return text.substring(0, maxLength) + "..."
            }
            
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
                            return mediaInfo.truncateText(fullText, 50)
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
            anchors.rightMargin: 22.5
            width: 80
            height: parent.height

            property string volumeLevel: ""
            property bool muted: false
            property bool isToggling: false

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

            Process {
                id: muteStatus
                command: ["bash", "-c", "pactl get-sink-mute @DEFAULT_SINK@ | grep -oE 'yes|no'"]
                stdout: SplitParser {
                    onRead: data => {
                        volume.muted = (data.trim() === "yes")
                        if (volume.isToggling)
                            volume.isToggling = false
                    }
                }
            }

            Component.onCompleted: {
                initialVolume.running = true
                muteStatus.running = true
            }

            Row {
                spacing: 5
                anchors.centerIn: parent
                clip: false

                Text {
                    id: volumeIcon
                    width: 28
                    height: 28
                    text: volume.muted ? "󰖁" : "󰕾"
                    color: "#cba6f7"
                    font.pixelSize: 20
                    font.family: Globals.iconFont
                    anchors.verticalCenter: parent.verticalCenter
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        
                        onClicked: {
                            if (volume.isToggling)
                                return

                            volume.isToggling = true
                            muteToggle.command = ["bash", "-c", "pactl set-sink-mute @DEFAULT_SINK@ toggle"]
                            muteToggle.running = true
                            volume.muted = !volume.muted
                            muteStatusRefresh.start()
                        }

                        onEntered: parent.opacity = 0.6
                        onExited: parent.opacity = 1.0

                        Timer {
                            id: muteStatusRefresh
                            interval: 150
                            repeat: false
                            onTriggered: {
                                muteStatus.running = true
                                volume.isToggling = false
                            }
                        }

                        Process {
                            id: muteToggle
                            command: []
                        }
                    }
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
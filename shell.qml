import Quickshell
import Quickshell.Services.Mpris
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
            border.color: "#cba6f7"
            border.width: 5
            radius: 16
        }

        Image {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 15
            source: "./arch-mauve.svg"
            width: 24
            height: 24
        }

        Item {
            id: mediaInfo
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 50
            width: parent.width / 2 - anchors.leftMargin
            height: parent.height
            
            property var currentPlayer: Mpris.players.values[0] || null
            
            Text {
                text: {
                    if (parent.currentPlayer && parent.currentPlayer.metadata) {
                        // Retrieve artist and title from metadata
                        var artist = parent.currentPlayer.metadata["xesam:artist"] || ""
                        var title = parent.currentPlayer.metadata["xesam:title"] || ""

                        // Handle case where artist is an array
                        if (Array.isArray(artist)) {
                            artist = artist.join(", ")
                        }

                        // Combine artist and title
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
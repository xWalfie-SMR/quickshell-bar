pragma ComponentBehavior: Bound
import QtQuick 6.5
import QtQuick.Window 6.5
import QtCore 6.5
import VirtualDesktop 1.0

Window {
    id: root
    visible: true
    width: Screen.width - 30
    height: 50
    x: 15
    y: 15
    color: "transparent"
    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint

    VirtualDesktopManager {
        id: windowManager
    }

    Rectangle {
        id: panel
        anchors.fill: parent
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
            anchors.left: parent.left
            anchors.leftMargin: 54
            anchors.verticalCenter: parent.verticalCenter
            width: 2
            height: parent.height - 10
            color: "#45475a"
        }

        // Active Windows
        Row {
            id: windows
            anchors.left: parent.left
            anchors.leftMargin: 70
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            Repeater {
                model: windowManager.windows

                Rectangle {
                    required property var modelData
                    required property int index

                    width: windowTitle.implicitWidth + 20
                    height: 30
                    radius: 8
                    color: modelData.isActive ? "#cba6f7" : "#313244"
                    border.color: modelData.isActive ? "#cba6f7" : "#45475a"
                    border.width: 2

                    Behavior on color {
                        ColorAnimation {
                            duration: 200
                            easing.type: Easing.OutCubic
                        }
                    }

                    Behavior on border.color {
                        ColorAnimation {
                            duration: 200
                            easing.type: Easing.OutCubic
                        }
                    }

                    Text {
                        id: windowTitle
                        anchors.centerIn: parent
                        text: modelData.title.length > 30 ? modelData.title.substring(0, 30) + "..." : modelData.title
                        color: modelData.isActive ? "#1e1e2e" : "#cdd6f4"
                        font.pixelSize: 13
                        font.family: "Comfortaa"
                        font.bold: modelData.isActive

                        Behavior on color {
                            ColorAnimation {
                                duration: 200
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            windowManager.activateWindow(index);
                        }
                    }
                }
            }
        }

        // Time and Date
        Item {
            id: time
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.rightMargin: 20

            Timer {
                interval: 1000
                running: true
                repeat: true
                onTriggered: {
                    timeText.text = Qt.formatDateTime(new Date(), "ddd dd/MM")
                    timeHour.text = Qt.formatDateTime(new Date(), "h:mm a")
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
                    font.family: "JetBrainsMono Nerd Font"
                    anchors.verticalCenter: parent.verticalCenter
                    verticalAlignment: Text.AlignVCenter
                }

                Text {
                    id: timeHour
                    text: Qt.formatDateTime(new Date(), "h:mm a")
                    color: "white"
                    font.pixelSize: 16
                    font.family: "Comfortaa"
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
                    font.family: "Comfortaa"
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }
}

pragma ComponentBehavior: Bound
import QtQuick 6.5
import QtQuick.Window 6.5
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
            anchors.leftMargin: 15
            source: "../arch-mauve.svg"
            width: 24
            height: 24
        }

        // Windows/Tasks
        Row {
            id: windowTasks
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 50
            spacing: 12

            Repeater {
                model: windowManager.windows

                Rectangle {
                    required property var modelData
                    required property int index

                    width: 15
                    height: 15
                    radius: 7.5
                    color: modelData.isActive ? "#cba6f7" : "#45475a"

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            windowManager.activateWindow(parent.index);
                        }
                    }

                    Behavior on color {
                        ColorAnimation {
                            duration: 200
                            easing.type: Easing.OutCubic
                        }
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

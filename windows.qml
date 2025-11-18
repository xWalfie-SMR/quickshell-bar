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
        id: desktopManager
        onCurrentDesktopChanged: {
            workspaces.focusedWorkspace = currentDesktop;
        }
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

            // Placeholder for media info (Mpris not available on Windows)
            Text {
                text: "No Media Playing"
                color: "#6c7086"
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

            // Mock workspaces (Hyprland not available on Windows)
            property int focusedWorkspace: 1

            Repeater {
                model: 10 // Number of workspaces

                Rectangle {
                    required property int index
                    width: workspaces.focusedWorkspace === (index + 1) ? 40 : 15
                    height: 15
                    radius: 7.5
                    color: workspaces.focusedWorkspace === (index + 1) ? "#cba6f7" : "#45475a"

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
                        onClicked: {
                            desktopManager.switchToDesktop(parent.index + 1);
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

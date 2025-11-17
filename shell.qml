import Quickshell
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
        height: 50
        color: '#1e1e2e'

        
        Rectangle {
            anchors.fill: parent
            color: "transparent"
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
        
        Text {
            anchors.centerIn: parent
            text: "Quickshell Bar"
            color: "white"
            font.pixelSize: 16
        }
    }
}
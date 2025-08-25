import QtQuick
import Quickshell
import qs.Settings
import qs.Services

Row {
    id: layout
    spacing: 10
    visible: Settings.settings.showSystemInfoInBar

    Row {
        id: cpuUsageLayout
        spacing: 6

        Text {
            id: cpuUsageIcon
            font.family: "Material Symbols Outlined"
            font.pixelSize: Theme.fontSizeBody
            text: "speed"
            verticalAlignment: Text.AlignVCenter
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.accentPrimary
        }

        Text {
            id: cpuUsageText
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.textPrimary
            text: Sysinfo.cpuUsageStr
            anchors.verticalCenter: parent.verticalCenter
            verticalAlignment: Text.AlignVCenter
        }
    }

    // CPU Temperature Component
    Row {
        id: cpuTempLayout
        spacing: 3
        Text {
            font.family: "Material Symbols Outlined"
            font.pixelSize: Theme.fontSizeBody
            text: "thermometer"
            verticalAlignment: Text.AlignVCenter
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.accentPrimary
        }

        Text {
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.textPrimary
            text: Sysinfo.cpuTempStr
            anchors.verticalCenter: parent.verticalCenter
            verticalAlignment: Text.AlignVCenter
        }
    }

    // Memory Usage Component
    Row {
        id: memoryUsageLayout
        spacing: 3
        Text {
            font.family: "Material Symbols Outlined"
            font.pixelSize: Theme.fontSizeBody
            text: "memory"
            color: Theme.accentPrimary
            verticalAlignment: Text.AlignVCenter
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.textPrimary
            text: Sysinfo.memoryUsageStr
            anchors.verticalCenter: parent.verticalCenter
            verticalAlignment: Text.AlignVCenter
        }
    }
}

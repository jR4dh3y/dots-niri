import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import qs.Settings
import qs.Widgets
import qs.Helpers
import qs.Services
import qs.Components

Rectangle {
    id: systemWidget
    width: 440
    height: 80
    color: "transparent"
    anchors.horizontalCenterOffset: -2

    Rectangle {
        id: card
        anchors.fill: parent
        color: Theme.surface
        radius: 18

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 12

            // User info row
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                // Profile image
                Rectangle {
                    width: 48
                    height: 48
                    radius: 24
                    color: Theme.accentPrimary

                    // Border
                    Rectangle {
                        anchors.fill: parent
                        color: "transparent"
                        radius: 24
                        border.color: Theme.accentPrimary
                        border.width: 2
                        z: 2
                    }

                    OpacityMask {
                        anchors.fill: parent
                        source: Image {
                            id: avatarImage
                            anchors.fill: parent
                            source: Settings.settings.profileImage !== undefined ? Settings.settings.profileImage : ""
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: false
                            sourceSize.width: 44
                            sourceSize.height: 44
                        }
                        maskSource: Rectangle {
                            width: 44
                            height: 44
                            radius: 22
                            visible: false
                        }
                        visible: Settings.settings.profileImage !== undefined && Settings.settings.profileImage !== ""
                        z: 1
                    }

                    // Fallback icon
                    Text {
                        anchors.centerIn: parent
                        text: "person"
                        font.family: "Material Symbols Outlined"
                        font.pixelSize: 24
                        color: Theme.onAccent
                        visible: Settings.settings.profileImage === undefined || Settings.settings.profileImage === ""
                        z: 0
                    }
                }

                // User info text
                ColumnLayout {
                    spacing: 4
                    Layout.fillWidth: true

                    Text {
                        text: Quickshell.env("USER")
                        font.family: Theme.fontFamily
                        font.pixelSize: 16
                        font.bold: true
                        color: Theme.textPrimary
                    }

                    Text {
                        text: "System Uptime: " + uptimeText
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        color: Theme.textSecondary
                    }
                }

                // Spacer
                Item {
                    Layout.fillWidth: true
                }

                // System menu button
                Rectangle {
                    id: systemButton
                    width: 32
                    height: 32
                    radius: 16
                    color: systemButtonArea.containsMouse || systemButtonArea.pressed ? Theme.accentPrimary : "transparent"
                    border.color: Theme.accentPrimary
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "power_settings_new"
                        font.family: "Material Symbols Outlined"
                        font.pixelSize: 16
                        color: systemButtonArea.containsMouse || systemButtonArea.pressed ? Theme.backgroundPrimary : Theme.accentPrimary
                    }

                    MouseArea {
                        id: systemButtonArea
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: {
                            systemMenu.visible = !systemMenu.visible;
                        }
                    }
                    StyledTooltip {
                        id: systemTooltip
                        text: "System"
                        targetItem: systemButton
                        tooltipVisible: systemButtonArea.containsMouse
                    }
                }
            }
        }
    }

    PanelWithOverlay {
        id: systemMenu
        anchors.top: systemButton.bottom
        anchors.right: systemButton.right
        // System menu popup
        Rectangle {

            width: 160
            height: 220
            color: Theme.surface
            radius: 8
            border.color: Theme.outline
            border.width: 1
            visible: true
            z: 9999
            anchors.top: parent.top
            anchors.right: parent.right

            // Position below system button
            anchors.rightMargin: 32
            anchors.topMargin: systemButton.y + systemButton.height + 48

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 4

                // Lock button
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 36
                    radius: 6
                    color: lockButtonArea.containsMouse ? Theme.accentPrimary : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 8

                        Text {
                            text: "lock_outline"
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 16
                            color: lockButtonArea.containsMouse ? Theme.onAccent : Theme.textPrimary
                        }

                        Text {
                            text: "Lock Screen"
                            font.family: Theme.fontFamily
                            font.pixelSize: 14
                            color: lockButtonArea.containsMouse ? Theme.onAccent : Theme.textPrimary
                            Layout.fillWidth: true
                        }
                    }

                    MouseArea {
                        id: lockButtonArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            lockScreen.locked = true;
                            systemMenu.visible = false;
                        }
                    }
                }

                // Suspend button
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 36
                    radius: 6
                    color: suspendButtonArea.containsMouse ? Theme.accentPrimary : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 8

                        Text {
                            text: "bedtime"
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 16
                            color: suspendButtonArea.containsMouse ? Theme.onAccent : Theme.textPrimary
                        }

                        Text {
                            text: "Suspend"
                            font.pixelSize: 14
                            color: suspendButtonArea.containsMouse ? Theme.onAccent : Theme.textPrimary
                            Layout.fillWidth: true
                        }
                    }

                    MouseArea {
                        id: suspendButtonArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            suspend();
                            systemMenu.visible = false;
                        }
                    }
                }

                // Reboot button
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 36
                    radius: 6
                    color: rebootButtonArea.containsMouse ? Theme.accentPrimary : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 8

                        Text {
                            text: "refresh"
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 16
                            color: rebootButtonArea.containsMouse ? Theme.onAccent : Theme.textPrimary
                        }

                        Text {
                            text: "Reboot"
                            font.family: Theme.fontFamily
                            font.pixelSize: 14
                            color: rebootButtonArea.containsMouse ? Theme.onAccent : Theme.textPrimary
                            Layout.fillWidth: true
                        }
                    }

                    MouseArea {
                        id: rebootButtonArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            reboot();
                            systemMenu.visible = false;
                        }
                    }
                }

                // Logout button
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 36
                    radius: 6
                    color: logoutButtonArea.containsMouse ? Theme.accentPrimary : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 8

                        Text {
                            text: "exit_to_app"
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 16
                            color: logoutButtonArea.containsMouse ? Theme.onAccent : Theme.textPrimary
                        }

                        Text {
                            text: "Logout"
                            font.pixelSize: 14
                            color: logoutButtonArea.containsMouse ? Theme.onAccent : Theme.textPrimary
                            Layout.fillWidth: true
                        }
                    }

                    MouseArea {
                        id: logoutButtonArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            logout();
                            systemMenu.visible = false;
                        }
                    }
                }

                // Shutdown button
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 36
                    radius: 6
                    color: shutdownButtonArea.containsMouse ? Theme.accentPrimary : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 8

                        Text {
                            text: "power_settings_new"
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 16
                            color: shutdownButtonArea.containsMouse ? Theme.onAccent : Theme.textPrimary
                        }

                        Text {
                            text: "Shutdown"
                            font.pixelSize: 14
                            color: shutdownButtonArea.containsMouse ? Theme.onAccent : Theme.textPrimary
                            Layout.fillWidth: true
                        }
                    }

                    MouseArea {
                        id: shutdownButtonArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            shutdown();
                            systemMenu.visible = false;
                        }
                    }
                }
            }
        }
    }

    // Properties
    property string uptimeText: "--:--"

    // Process to get uptime
    Process {
        id: uptimeProcess
        command: ["sh", "-c", "uptime | awk -F 'up ' '{print $2}' | awk -F ',' '{print $1}' | xargs"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                uptimeText = this.text.trim();
                uptimeProcess.running = false;
            }
        }
    }

    Process {
        id: shutdownProcess
        command: ["shutdown", "-h", "now"]
        running: false
    }

    Process {
        id: rebootProcess
        command: ["reboot"]
        running: false
    }

    Process {
        id: suspendProcess
        command: ["systemctl", "suspend"]
        running: false
    }

    Process {
        id: logoutProcess
        command: ["loginctl", "terminate-user", Quickshell.env("USER")]
        running: false
    }

    function logout() {
        logoutProcess.running = true;
    }

    function suspend() {
        suspendProcess.running = true;
    }

    function shutdown() {
        shutdownProcess.running = true;
    }

    function reboot() {
        rebootProcess.running = true;
    }


    property bool panelVisible: false

    // Trigger initial update when panel becomes visible
    onPanelVisibleChanged: {
        if (panelVisible) {
            updateSystemInfo();
        }
    }

    // Timer to update uptime - only runs when panel is visible
    Timer {
        interval: 60000 // Update every minute
        repeat: true
        running: panelVisible
        onTriggered: updateSystemInfo()
    }

    Component.onCompleted: {
        uptimeProcess.running = true;
    }

    function updateSystemInfo() {
        uptimeProcess.running = true;
    }

    // Add lockscreen instance (hidden by default)
    LockScreen {
        id: lockScreen
    }
}
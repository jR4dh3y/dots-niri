import QtQuick 
import Quickshell
import Quickshell.Io
import qs.Settings
import qs.Components

Item {
    id: root
    width: 22; height: 22
    property bool isSilence: false

    // Process for executing CLI commands
    Process {
        id: rightClickProcess
        command: ["qs","ipc", "call", "globalIPC", "toggleNotificationPopup"]
    }

    // Bell icon/button
    Item {
        id: bell
        width: 22; height: 22
        Text {
            id: bellText
            anchors.centerIn: parent
            text: notificationHistoryWin.hasUnread ? "notifications_unread" : "notifications"
            font.family: mouseAreaBell.containsMouse ? "Material Symbols Rounded" : "Material Symbols Outlined"
            font.pixelSize: 16
            font.weight: notificationHistoryWin.hasUnread ? Font.Bold : Font.Normal
            color: mouseAreaBell.containsMouse ? Theme.accentPrimary : (notificationHistoryWin.hasUnread ? Theme.accentPrimary : Theme.textDisabled)
        }
        MouseArea {
            id: mouseAreaBell
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: function(mouse) {
                if (mouse.button === Qt.RightButton) {
                    root.isSilence = !root.isSilence;
                    rightClickProcess.running = true;
                    bellText.text = root.isSilence ? "notifications_off" : "notifications"
                }

                if (mouse.button === Qt.LeftButton){
                     notificationHistoryWin.visible = !notificationHistoryWin.visible
                     return;
                }

            }
            onEntered: notificationTooltip.tooltipVisible = true
            onExited: notificationTooltip.tooltipVisible = false
        }
    }

    StyledTooltip {
        id: notificationTooltip
        text: "Notification History"
        tooltipVisible: false
        targetItem: bell
        delay: 200
    }
}
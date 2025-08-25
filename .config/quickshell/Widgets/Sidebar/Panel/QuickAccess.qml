import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import qs.Settings

Rectangle {
    id: quickAccessWidget
    width: 440
    height: 80
    color: "transparent"
    anchors.horizontalCenterOffset: -2
    
    required property bool isRecording
    
    signal recordingRequested()
    signal stopRecordingRequested()
    signal recordingStateMismatch(bool actualState)
    signal settingsRequested()
    signal wallpaperRequested()

    Rectangle {
        id: card
        anchors.fill: parent
        color: Theme.surface
        radius: 18

        RowLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 12

            // Settings Button
            Rectangle {
                id: settingsButton
                Layout.fillWidth: true
                Layout.preferredHeight: 44
                radius: 12
                color: settingsButtonArea.containsMouse ? Theme.accentPrimary : "transparent"
                border.color: Theme.accentPrimary
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    Text {
                        text: "settings"
                        font.family: settingsButtonArea.containsMouse ? "Material Symbols Rounded" : "Material Symbols Outlined"
                        font.pixelSize: 16
                        color: settingsButtonArea.containsMouse ? Theme.onAccent : Theme.accentPrimary
                    }

                    Text {
                        text: "Settings"
                        font.family: Theme.fontFamily
                        font.pixelSize: 14
                        font.bold: true
                        color: settingsButtonArea.containsMouse ? Theme.onAccent : Theme.textPrimary
                        Layout.fillWidth: true
                    }
                }

                MouseArea {
                    id: settingsButtonArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: {
                        settingsRequested()
                    }
                }
            }

            // Screen Recorder Button
            Rectangle {
                id: recorderButton
                Layout.fillWidth: true
                Layout.preferredHeight: 44
                radius: 12
                color: isRecording ? Theme.accentPrimary : 
                       (recorderButtonArea.containsMouse ? Theme.accentPrimary : "transparent")
                border.color: Theme.accentPrimary
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    Text {
                        text: isRecording ? "radio_button_checked" : "radio_button_unchecked"
                        font.family: (isRecording || recorderButtonArea.containsMouse) ? "Material Symbols Rounded" : "Material Symbols Outlined"
                        font.pixelSize: 16
                        color: isRecording || recorderButtonArea.containsMouse ? Theme.onAccent : Theme.accentPrimary
                    }

                    Text {
                        text: isRecording ? "End" : "Record"
                        font.family: Theme.fontFamily
                        font.pixelSize: 14
                        font.bold: true
                        color: isRecording || recorderButtonArea.containsMouse ? Theme.onAccent : Theme.textPrimary
                        Layout.fillWidth: true
                    }
                }

                MouseArea {
                    id: recorderButtonArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: {
                        if (isRecording) {
                            stopRecordingRequested()
                        } else {
                            recordingRequested()
                        }
                    }
                }
            }

            // Wallpaper Button
            Rectangle {
                id: wallpaperButton
                Layout.fillWidth: true
                Layout.preferredHeight: 44
                radius: 12
                color: wallpaperButtonArea.containsMouse ? Theme.accentPrimary : "transparent"
                border.color: Theme.accentPrimary
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    Text {
                        text: "image"
                        font.family: "Material Symbols Outlined"
                        font.pixelSize: 16
                        color: wallpaperButtonArea.containsMouse ? Theme.onAccent : Theme.accentPrimary
                    }

                    Text {
                        text: "Wallpaper"
                        font.family: Theme.fontFamily
                        font.pixelSize: 14
                        font.bold: true
                        color: wallpaperButtonArea.containsMouse ? Theme.onAccent : Theme.textPrimary
                        Layout.fillWidth: true
                    }
                }

                MouseArea {
                    id: wallpaperButtonArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: {
                        wallpaperRequested()
                    }
                }
            }
        }
    }

    // Properties
    property bool panelVisible: false

    // Timer to check if recording is active
    Timer {
        interval: 2000
        repeat: true
        running: panelVisible
        onTriggered: checkRecordingStatus()
    }

    function checkRecordingStatus() {
        if (isRecording) {
            checkRecordingProcess.running = true
        }
    }

    // Process to check if gpu-screen-recorder is running
    Process {
        id: checkRecordingProcess
        command: ["pgrep", "-f", "gpu-screen-recorder.*portal"]
        onExited: function(exitCode, exitStatus) {
            var isActuallyRecording = exitCode === 0
            if (isRecording && !isActuallyRecording) {
                recordingStateMismatch(isActuallyRecording)
            }
        }
    }
} 
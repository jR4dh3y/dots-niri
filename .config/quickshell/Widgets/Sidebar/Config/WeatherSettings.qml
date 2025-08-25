import QtQuick
import QtQuick.Layouts
import qs.Settings

Rectangle {
    id: weatherSettingsCard
    Layout.fillWidth: true
    Layout.preferredHeight: 320
    color: Theme.surface
    radius: 18

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 12

        // Weather Settings Header
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Text {
                text: "wb_sunny"
                font.family: "Material Symbols Outlined"
                font.pixelSize: 20
                color: Theme.accentPrimary
            }

            Text {
                text: "Weather Settings"
                font.family: Theme.fontFamily
                font.pixelSize: 16
                font.bold: true
                color: Theme.textPrimary
                Layout.fillWidth: true
            }
        }

        // Weather City Setting
        ColumnLayout {
            spacing: 8
            Layout.fillWidth: true

            Text {
                text: "City"
                font.family: Theme.fontFamily
                font.pixelSize: 13
                font.bold: true
                color: Theme.textPrimary
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                radius: 16
                color: Theme.surfaceVariant
                border.color: cityInput.activeFocus ? Theme.accentPrimary : Theme.outline
                border.width: 1

                TextInput {
                    id: cityInput
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    anchors.topMargin: 6
                    anchors.bottomMargin: 6
                    text: Settings.settings.weatherCity
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    color: Theme.textPrimary
                    verticalAlignment: TextInput.AlignVCenter
                    clip: true
                    focus: true
                    selectByMouse: true
                    activeFocusOnTab: true
                    inputMethodHints: Qt.ImhNone

                    onTextChanged: {
                        Settings.settings.weatherCity = text;
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.IBeamCursor
                        onClicked: {
                            cityInput.forceActiveFocus();
                        }
                    }
                }
            }
        }

        // Temperature Unit Setting
        RowLayout {
            spacing: 12
            Layout.fillWidth: true

            Text {
                text: "Temperature Unit"
                font.family: Theme.fontFamily
                font.pixelSize: 13
                font.bold: true
                color: Theme.textPrimary
            }

            Item {
                Layout.fillWidth: true
            }

            // Custom Material 3 Switch
            Rectangle {
                id: customSwitch
                width: 52
                height: 32
                radius: 16
                color: Theme.accentPrimary
                border.color: Theme.accentPrimary
                border.width: 2

                Rectangle {
                    id: thumb
                    width: 28
                    height: 28
                    radius: 14
                    color: Theme.surface
                    border.color: Theme.outline
                    border.width: 1
                    y: 2
                    x: Settings.settings.useFahrenheit ? customSwitch.width - width - 2 : 2

                    Text {
                        anchors.centerIn: parent
                        text: Settings.settings.useFahrenheit ? "\u00b0F" : "\u00b0C"
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        font.bold: true
                        color: Theme.textPrimary
                    }

                    Behavior on x {
                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Settings.settings.useFahrenheit = !Settings.settings.useFahrenheit;
                    }
                }
            }

        
        }

            // Random Wallpaper Setting
            RowLayout {
                spacing: 8
                Layout.fillWidth: true
                Layout.topMargin: 8

                Text {
                    text: "Use 12 Hour Clock"
                    font.pixelSize: 13
                    font.bold: true
                    color: Theme.textPrimary
                }

                Item {
                    Layout.fillWidth: true
                }

                // Custom Material 3 Switch
                Rectangle {
                    id: use12HourClockSwitch
                    width: 52
                    height: 32
                    radius: 16
                    color: Settings.settings.use12HourClock ? Theme.accentPrimary : Theme.surfaceVariant
                    border.color: Settings.settings.use12HourClock ? Theme.accentPrimary : Theme.outline
                    border.width: 2

                    Rectangle {
                        id: randomWallpaperThumb
                        width: 28
                        height: 28
                        radius: 14
                        color: Theme.surface
                        border.color: Theme.outline
                        border.width: 1
                        y: 2
                        x: Settings.settings.use12HourClock ? use12HourClockSwitch.width - width - 2 : 2

                        Behavior on x {
                            NumberAnimation {
                                duration: 200
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Settings.settings.use12HourClock = !Settings.settings.use12HourClock;
                        }
                    }
                }
            }

            // Reverse Day Month Setting
            RowLayout {
                spacing: 8
                Layout.fillWidth: true
                Layout.topMargin: 8

                Text {
                    text: "US Style Date"
                    font.pixelSize: 13
                    font.bold: true
                    color: Theme.textPrimary
                }

                Item {
                    Layout.fillWidth: true
                }

                // Custom Material 3 Switch
                Rectangle {
                    id: reverseDayMonthSwitch
                    width: 52
                    height: 32
                    radius: 16
                    color: Settings.settings.reverseDayMonth ? Theme.accentPrimary : Theme.surfaceVariant
                    border.color: Settings.settings.reverseDayMonth ? Theme.accentPrimary : Theme.outline
                    border.width: 2

                    Rectangle {
                        id: reverseDayMonthThumb
                        width: 28
                        height: 28
                        radius: 14
                        color: Theme.surface
                        border.color: Theme.outline
                        border.width: 1
                        y: 2
                        x: Settings.settings.reverseDayMonth ? reverseDayMonthSwitch.width - width - 2 : 2

                        Behavior on x {
                            NumberAnimation {
                                duration: 200
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Settings.settings.reverseDayMonth = !Settings.settings.reverseDayMonth;
                        }
                    }
                }
            }
    }
}

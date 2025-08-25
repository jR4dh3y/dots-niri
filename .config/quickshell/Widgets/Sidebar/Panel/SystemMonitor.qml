import QtQuick 
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Io
import qs.Components
import qs.Services
import qs.Settings

Rectangle {
    id: systemMonitor
    width: 70
    height: 250
    color: "transparent"

    property bool isVisible: false

    Rectangle {
        id: card
        anchors.fill: parent
        color: Theme.surface
        radius: 18

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 12
            Layout.alignment: Qt.AlignVCenter

            // CPU Usage
            Item {
                width: 50; height: 50
                CircularProgressBar {
                    id: cpuBar
                    progress: Sysinfo.cpuUsage / 100
                    size: 50
                    strokeWidth: 4
                    hasNotch: true
                    notchIcon: "speed"
                    notchIconSize: 14
                    Layout.alignment: Qt.AlignHCenter
                }
                MouseArea {
                    id: cpuBarMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: cpuTooltip.tooltipVisible = true
                    onExited: cpuTooltip.tooltipVisible = false
                }
                StyledTooltip {
                    id: cpuTooltip
                    text: 'CPU Usage: ' + Sysinfo.cpuUsage + '%'
                    tooltipVisible: false
                    targetItem: cpuBar
                    delay: 200
                }
            }

            // Cpu Temp
            Item {
                width: 50; height: 50
                CircularProgressBar {
                    id: tempBar
                    progress: Sysinfo.cpuTemp / 100
                    size: 50
                    strokeWidth: 4
                    hasNotch: true
                    units: "°C"
                    notchIcon: "thermometer"
                    notchIconSize: 14
                    Layout.alignment: Qt.AlignHCenter
                }
                MouseArea {
                    id: tempBarMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: tempTooltip.tooltipVisible = true
                    onExited: tempTooltip.tooltipVisible = false
                }
                StyledTooltip {
                    id: tempTooltip
                    text: 'CPU Temp: ' + Sysinfo.cpuTemp + '°C'
                    tooltipVisible: false
                    targetItem: tempBar
                    delay: 200
                }
            }

            // Memory Usage
            Item {
                width: 50; height: 50
                CircularProgressBar {
                    id: memBar
                    progress: Sysinfo.memoryUsagePer / 100
                    size: 50
                    strokeWidth: 4
                    hasNotch: true
                    notchIcon: "memory"
                    notchIconSize: 14
                    Layout.alignment: Qt.AlignHCenter
                }
                MouseArea {
                    id: memBarMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: memTooltip.tooltipVisible = true
                    onExited: memTooltip.tooltipVisible = false
                }
                StyledTooltip {
                    id: memTooltip
                    text: 'Memory Usage: ' + Sysinfo.memoryUsagePer + '% (' + Sysinfo.memoryUsageStr + ' used)'
                    tooltipVisible: false
                    targetItem: memBar
                    delay: 200
                }
            }
            // Gpu Usage
            Item {
                width: 50; height: 50
                CircularProgressBar {
                    id: gpuBar
                    progress: Sysinfo.gpuUsage / 100
                    size: 50
                    strokeWidth: 4
                    hasNotch: true
                    notchIcon: ""
                    notchIconSize: 14
                    Layout.alignment: Qt.AlignHCenter
                }
                MouseArea {
                    id: gpuBarMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: gpuTooltip.tooltipVisible = true
                    onExited: gpuTooltip.tooltipVisible = false
                }
                StyledTooltip {
                    id: gpuTooltip
                    text: 'GPU Usage: ' + Sysinfo.gpuUsage + '%'
                    tooltipVisible: false
                    targetItem: gpuBar
                    delay: 200
                }
            }

            // Disk Usage
            Item {
                width: 50; height: 50
                CircularProgressBar {
                    id: diskBar
                    progress: Sysinfo.diskUsage / 100
                    size: 50
                    strokeWidth: 4
                    hasNotch: true
                    notchIcon: "storage"
                    notchIconSize: 14
                    Layout.alignment: Qt.AlignHCenter
                }
                MouseArea {
                    id: diskBarMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: diskTooltip.tooltipVisible = true
                    onExited: diskTooltip.tooltipVisible = false
                }
                StyledTooltip {
                    id: diskTooltip
                    text: 'Disk Usage: ' + Sysinfo.diskUsage + '%'
                    tooltipVisible: false
                    targetItem: diskBar
                    delay: 200
                }
            }
        }
    }
} 
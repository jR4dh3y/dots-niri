import QtQuick 
import QtQuick.Layouts
import QtQuick.Controls
import qs.Settings

ColumnLayout {
    property alias title: headerText.text
    property bool expanded: false // Hidden by default
    default property alias content: contentItem.children

    Rectangle {
        Layout.fillWidth: true
        height: 44
        radius: 12
        color: Theme.surface
        border.color: Theme.accentPrimary
        border.width: 2
        RowLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 8
            Item { width: 2 }
            Text {
                id: headerText
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeBody
                font.bold: true
                color: Theme.textPrimary
            }
            Item { Layout.fillWidth: true }
            Rectangle {
                width: 32; height: 32
                color: "transparent"
                Text {
                    anchors.centerIn: parent
                    text: expanded ? "expand_less" : "expand_more"
                    font.family: "Material Symbols Outlined"
                    font.pixelSize: Theme.fontSizeBody
                    color: Theme.accentPrimary
                }
            }
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: expanded = !expanded
        }
    }
    Item { height: 8 }
    ColumnLayout {
        id: contentItem
        Layout.fillWidth: true
        visible: expanded
        spacing: 0
    }
} 
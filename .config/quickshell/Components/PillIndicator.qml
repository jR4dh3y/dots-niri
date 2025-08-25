import QtQuick
import QtQuick.Controls
import qs.Settings

Item {
    id: revealPill

    // External properties
    property string icon: ""
    property string text: ""
    property color pillColor: Theme.surfaceVariant
    property color textColor: Theme.textPrimary
    property color iconCircleColor: Theme.accentPrimary
    property color iconTextColor: Theme.backgroundPrimary
    property int pillHeight: 22
    property int iconSize: 22
    property int pillPaddingHorizontal: 14
    property bool autoHide: false

    // Internal state
    property bool showPill: false
    property bool shouldAnimateHide: false

    // Exposed width logic
    readonly property int pillOverlap: iconSize / 2
    readonly property int maxPillWidth: Math.max(1, textItem.implicitWidth + pillPaddingHorizontal * 2 + pillOverlap)

    signal shown
    signal hidden

    width: iconSize + (showPill ? maxPillWidth - pillOverlap : 0)
    height: pillHeight

    Rectangle {
        id: pill
        width: showPill ? maxPillWidth : 1  // Never 0 width
        height: pillHeight
        x: (iconCircle.x + iconCircle.width / 2) - width
        opacity: showPill ? 1 : 0
        color: pillColor
        topLeftRadius: pillHeight / 2
        bottomLeftRadius: pillHeight / 2
        anchors.verticalCenter: parent.verticalCenter

        Text {
            id: textItem
            anchors.centerIn: parent
            text: revealPill.text
            font.pixelSize: Theme.fontSizeSmall
            font.family: Theme.fontFamily
            font.weight: Font.Bold
            color: textColor
            visible: showPill // Hide text when pill is collapsed
        }

        Behavior on width {
            enabled: showAnim.running || hideAnim.running
            NumberAnimation {
                duration: 250
                easing.type: Easing.OutCubic
            }
        }
        Behavior on opacity {
            enabled: showAnim.running || hideAnim.running
            NumberAnimation {
                duration: 250
                easing.type: Easing.OutCubic
            }
        }
    }

    // Icon circle
    Rectangle {
        id: iconCircle
        width: iconSize
        height: iconSize
        radius: width / 2
        color: showPill ? iconCircleColor : "transparent"
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right

        Behavior on color {
            ColorAnimation {
                duration: 200
                easing.type: Easing.InOutQuad
            }
        }

        Text {
            anchors.centerIn: parent
            font.family: showPill ? "Material Symbols Rounded" : "Material Symbols Outlined"
            font.pixelSize: Theme.fontSizeSmall
            text: revealPill.icon
            color: showPill ? iconTextColor : textColor
        }
    }

    // Show animation
    ParallelAnimation {
        id: showAnim
        running: false
        NumberAnimation {
            target: pill
            property: "width"
            from: 1  // Start from 1 instead of 0
            to: maxPillWidth
            duration: 250
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: pill
            property: "opacity"
            from: 0
            to: 1
            duration: 250
            easing.type: Easing.OutCubic
        }
        onStarted: {
            showPill = true;
        }
        onStopped: {
            delayedHideAnim.start();
            shown();
        }
    }

    // Delayed auto-hide
    SequentialAnimation {
        id: delayedHideAnim
        running: false
        PauseAnimation {
            duration: 2500
        }
        ScriptAction {
            script: if (shouldAnimateHide)
                hideAnim.start()
        }
    }

    // Hide animation
    ParallelAnimation {
        id: hideAnim
        running: false
        NumberAnimation {
            target: pill
            property: "width"
            from: maxPillWidth
            to: 1  // End at 1 instead of 0
            duration: 250
            easing.type: Easing.InCubic
        }
        NumberAnimation {
            target: pill
            property: "opacity"
            from: 1
            to: 0
            duration: 250
            easing.type: Easing.InCubic
        }
        onStopped: {
            showPill = false;
            shouldAnimateHide = false;
            hidden();
        }
    }

    // Exposed functions
    function show() {
        if (!showPill) {
            shouldAnimateHide = autoHide;
            showAnim.start();
        } else {
            // Reset hide timer if already shown
            hideAnim.stop();
            delayedHideAnim.restart();
        }
    }

    function hide() {
        if (showPill) {
            hideAnim.start();
        }
        // Stop the show timer if it's running
        showTimer.stop();
    }

    function showDelayed() {
        if (!showPill) {
            shouldAnimateHide = autoHide;
            // Add a 500ms delay before showing
            showTimer.start();
        } else {
            // Reset hide timer if already shown
            hideAnim.stop();
            delayedHideAnim.restart();
        }
    }

    // Timer for delayed show
    Timer {
        id: showTimer
        interval: 500  // 500ms delay
        onTriggered: {
            if (!showPill) {
                showAnim.start();
            }
        }
    }
}

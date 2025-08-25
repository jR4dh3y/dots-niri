import QtQuick
import qs.Settings

Rectangle {
    id: circularProgressBar
    color: "transparent"
    
    // Properties
    property real progress: 0.0 // 0.0 to 1.0
    property int size: 80
    property color backgroundColor: Theme.surfaceVariant
    property color progressColor: Theme.accentPrimary
    property int strokeWidth: 6
    property bool showText: true
    property string units: "%"
    property string text: Math.round(progress * 100) + units
    property int textSize: 10
    property color textColor: Theme.textPrimary
    
    // Notch properties
    property bool hasNotch: false
    property real notchSize: 0.25 // Size of the notch as a fraction of the circle
    property string notchIcon: ""
    property int notchIconSize: 12
    property color notchIconColor: Theme.accentPrimary
    
    width: size
    height: size
    
    Canvas {
        id: canvas
        anchors.fill: parent
        
        onPaint: {
            var ctx = getContext("2d")
            var centerX = width / 2
            var centerY = height / 2
            var radius = Math.min(width, height) / 2 - strokeWidth / 2
            var startAngle = -Math.PI / 2 // Start from top
            var notchAngle = notchSize * 2 * Math.PI
            var notchStartAngle = -notchAngle / 2
            var notchEndAngle = notchAngle / 2
            
            // Clear canvas
            ctx.reset()
            
            // Background circle
            ctx.strokeStyle = backgroundColor
            ctx.lineWidth = strokeWidth
            ctx.lineCap = "round"
            ctx.beginPath()
            
            if (hasNotch) {
                // Draw background circle with notch on the right side
                // Draw the arc excluding the notch area (notch is at 0 radians, right side)
                ctx.arc(centerX, centerY, radius, notchEndAngle, 2 * Math.PI + notchStartAngle)
            } else {
                ctx.arc(centerX, centerY, radius, 0, 2 * Math.PI)
            }
            ctx.stroke()
            
            // Progress arc
            if (progress > 0) {
                ctx.strokeStyle = progressColor
                ctx.lineWidth = strokeWidth
                ctx.lineCap = "round"
                ctx.beginPath()
                
                if (hasNotch) {
                    // Calculate progress with notch consideration
                    var availableAngle = 2 * Math.PI - notchAngle
                    var progressAngle = availableAngle * progress
                    
                    // Start from where the notch cutout begins (top-right) and go clockwise
                    var adjustedStartAngle = notchEndAngle
                    var adjustedEndAngle = adjustedStartAngle + progressAngle
                    
                    // Ensure we don't exceed the available space
                    if (adjustedEndAngle > 2 * Math.PI + notchStartAngle) {
                        adjustedEndAngle = 2 * Math.PI + notchStartAngle
                    }
                    
                    if (adjustedEndAngle > adjustedStartAngle) {
                        ctx.arc(centerX, centerY, radius, adjustedStartAngle, adjustedEndAngle)
                    }
                } else {
                    ctx.arc(centerX, centerY, radius, startAngle, startAngle + (2 * Math.PI * progress))
                }
                ctx.stroke()
            }
        }
    }
    
    // Center text - always show the percentage
    Text {
        id: centerText
        anchors.centerIn: parent
        text: circularProgressBar.text
        font.pixelSize: textSize
        font.family: Theme.fontFamily
        font.bold: true
        color: textColor
        visible: showText
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
    
    // Notch icon - positioned further to the right
    Text {
        id: notchIconText
        anchors.right: parent.right
        anchors.rightMargin: -4
        anchors.verticalCenter: parent.verticalCenter
        text: notchIcon
        font.family: "Material Symbols Outlined"
        font.pixelSize: notchIconSize
        color: notchIconColor
        visible: hasNotch && notchIcon !== ""
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
    
    // Animate progress changes
    Behavior on progress {
        NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
    }
    
    // Redraw canvas when properties change
    onProgressChanged: canvas.requestPaint()
    onSizeChanged: canvas.requestPaint()
    onBackgroundColorChanged: canvas.requestPaint()
    onProgressColorChanged: canvas.requestPaint()
    onStrokeWidthChanged: canvas.requestPaint()
    onHasNotchChanged: canvas.requestPaint()
    onNotchSizeChanged: canvas.requestPaint()
} 
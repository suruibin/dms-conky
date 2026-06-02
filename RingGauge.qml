import QtQuick

Item {
    id: ring
    width: 50; height: 50
    property real pct: 0
    property color gaugeColor: "#5105DB"

    // Background ring — drawn once, never changes
    Canvas {
        id: bgCanvas
        anchors.fill: parent
        onPaint: {
            var ctx = getContext("2d")
            var cx = width / 2, cy = height / 2, r = 20, tw = 6
            ctx.beginPath(); ctx.arc(cx, cy, r, 0, Math.PI * 2)
            ctx.strokeStyle = "rgba(255,255,255,0.15)"; ctx.lineWidth = tw; ctx.stroke()
        }
    }

    // Foreground arc — redrawn only on pct / color change
    Canvas {
        id: fgCanvas
        anchors.fill: parent
        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            var cx = width / 2, cy = height / 2, r = 20, tw = 6
            var end = -Math.PI / 2 + Math.min(1, ring.pct) * Math.PI * 2
            ctx.beginPath(); ctx.arc(cx, cy, r, -Math.PI / 2, end)
            ctx.strokeStyle = ring.gaugeColor; ctx.lineWidth = tw; ctx.lineCap = "round"; ctx.stroke()
        }
    }

    onPctChanged: fgCanvas.requestPaint()
    onGaugeColorChanged: fgCanvas.requestPaint()
}

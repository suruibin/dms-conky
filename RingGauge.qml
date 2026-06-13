import QtQuick

Item {
    id: ring
    width: 50; height: 50
    property real pct: 0
    property color gaugeColor: "#5105DB"
    property color bgColor: "#26ffffff"
    property real _lastPct: -1

    Canvas {
        id: canvas
        anchors.fill: parent
        onPaint: {
            var ctx = getContext("2d")
            var cx = width / 2, cy = height / 2, r = 20, tw = 6
            
            ctx.beginPath()
            ctx.arc(cx, cy, r, 0, Math.PI * 2)
            ctx.strokeStyle = ring.bgColor
            ctx.lineWidth = tw
            ctx.stroke()
            
            var end = -Math.PI / 2 + Math.min(1, ring.pct) * Math.PI * 2
            ctx.beginPath()
            ctx.arc(cx, cy, r, -Math.PI / 2, end)
            ctx.strokeStyle = ring.gaugeColor
            ctx.lineWidth = tw
            ctx.lineCap = "round"
            ctx.stroke()
        }
    }

    onPctChanged: {
        if (Math.abs(pct - _lastPct) < 0.005) return
        _lastPct = pct
        canvas.requestPaint()
    }
    onGaugeColorChanged: canvas.requestPaint()
    onBgColorChanged: canvas.requestPaint()
}
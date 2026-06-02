import QtQuick

Canvas {
    id: graph
    width: 110; height: 24
    property var data: []
    property real maxVal: 1
    property color gradientStart: "#5105DB"
    property color gradientEnd: "#FF1493"

    onPaint: {
        var ctx = getContext("2d")
        var w = width, h = height, d = data
        ctx.clearRect(0, 0, w, h)
        if (d.length < 2) return
        var stepX = w / (d.length - 1)
        ctx.beginPath()
        ctx.moveTo(0, h)
        for (var i = 0; i < d.length; i++) {
            ctx.lineTo(i * stepX, h - (d[i] / maxVal) * h)
        }
        ctx.lineTo(w, h)
        ctx.closePath()
        var grad = ctx.createLinearGradient(0, 0, w, 0)
        grad.addColorStop(0, gradientStart)
        grad.addColorStop(1, gradientEnd)
        ctx.fillStyle = grad
        ctx.fill()
    }

    onDataChanged: requestPaint()
}

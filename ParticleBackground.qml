import QtQuick

Canvas {
    id: root
    anchors.fill: parent
    z: -1

    // --- Public properties ---
    property bool running: true
    property real particleOpacity: 1.0
    property int particleCount: 150
    property real particleSize: 8.0
    property string particleStyle: "stars"

    opacity: particleOpacity

    property var particles: []
    property int tick: 0

    function spawn() {
        if (particles.length >= particleCount) return
        particles.push({
            x: Math.random() * width,
            y: Math.random() * height,
            vx: (Math.random() - 0.5) * 12,
            vy: -(8 + Math.random() * 16),
            size: 1 + Math.random() * particleSize,
            life: 1.0,
            decay: 0.3 + Math.random() * 0.5,
            hue: Math.random(),
            sat: 0.7 + Math.random() * 0.3,
            lit: 0.7 + Math.random() * 0.28
        })
    }

    function drawShape(ctx, p) {
        var s = p.size * (0.3 + p.life * 0.7)
        var style = particleStyle || "circles"
        switch (style) {
            case "squares":
                ctx.fillRect(p.x - s/2, p.y - s/2, s, s); break
            case "triangles":
                ctx.beginPath()
                ctx.moveTo(p.x, p.y - s)
                ctx.lineTo(p.x - s * 0.866, p.y + s * 0.5)
                ctx.lineTo(p.x + s * 0.866, p.y + s * 0.5)
                ctx.closePath(); ctx.fill(); break
            case "stars":
                ctx.beginPath()
                var inner = s * 0.35
                for (var k = 0; k < 4; k++) {
                    var a = Math.PI / 2 * k - Math.PI / 2
                    ctx.lineTo(p.x + Math.cos(a) * s, p.y + Math.sin(a) * s)
                    ctx.lineTo(p.x + Math.cos(a + Math.PI/4) * inner, p.y + Math.sin(a + Math.PI/4) * inner)
                }
                ctx.closePath(); ctx.fill(); break
            case "lines":
                ctx.beginPath()
                ctx.moveTo(p.x - s, p.y); ctx.lineTo(p.x + s, p.y)
                ctx.lineWidth = Math.max(1, s * 0.4); ctx.stroke(); break
            default: // circles
                ctx.beginPath()
                ctx.arc(p.x, p.y, s, 0, Math.PI * 2); ctx.fill(); break
        }
    }

    onPaint: {
        var ctx = getContext("2d")
        ctx.clearRect(0, 0, width, height)
        ctx.shadowBlur = 4
        for (var i = 0; i < particles.length; i++) {
            var p = particles[i]
            if (p.life <= 0) continue
            ctx.globalAlpha = (0.25 + p.life * 0.75) * particleOpacity
            ctx.shadowColor = Qt.hsla(p.hue, p.sat, p.lit, 1.0)
            ctx.fillStyle = Qt.hsla(p.hue, p.sat, p.lit, 1.0)
            ctx.strokeStyle = Qt.hsla(p.hue, p.sat, p.lit, 1.0)
            root.drawShape(ctx, p)
        }
    }

    Timer {
        interval: 66; running: root.running; repeat: true
        onTriggered: {
            root.tick++
            if (root.tick % 3 === 0) root.spawn()
            if (root.tick % 5 === 0) root.spawn()

            var dt = 0.066
            var alive = []
            var p = root.particles
            for (var i = 0; i < p.length; i++) {
                var pt = p[i]
                pt.x += pt.vx * dt
                pt.y += pt.vy * dt
                pt.vy += 1.5 * dt
                pt.life -= pt.decay * dt
                if (pt.life > 0 && pt.y > -10 && pt.y < root.height + 10) {
                    alive.push(pt)
                }
            }
            root.particles = alive
            root.requestPaint()
        }
    }
}

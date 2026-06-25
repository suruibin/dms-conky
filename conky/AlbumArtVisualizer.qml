import QtQuick
import QtQuick.Shapes
import Quickshell
import qs.Common
import qs.Services
import qs.Widgets

Item {
    id: root
    property var host
    property var activePlayer
    property color blobColor

    Loader {
        active: root.activePlayer && root.activePlayer.isPlaying
        sourceComponent: Component { Ref { service: CavaService } }
    }

    Shape {
        id: morphingBlob
        width: parent.width * 1.3
        height: parent.height * 1.3
        anchors.centerIn: parent
        visible: CavaService.cavaAvailable && root.activePlayer && root.activePlayer.isPlaying
        asynchronous: false; antialiasing: true
        preferredRendererType: Shape.CurveRenderer
        z: 0

        readonly property real centerX: width / 2
        readonly property real centerY: height / 2
        readonly property real baseRadius: Math.min(width, height) * 0.41
        readonly property int segments: 24

        property var audioLevels: {
            if (!CavaService.cavaAvailable || CavaService.values.length === 0)
                return [0.5, 0.3, 0.7, 0.4, 0.6, 0.5, 0.8, 0.2, 0.9, 0.6]
            return CavaService.values
        }
        property var smoothedLevels: [0.5, 0.3, 0.7, 0.4, 0.6, 0.5, 0.8, 0.2, 0.9, 0.6]
        property var cubics: []

        Component { id: cubicSeg; PathCubic {} }

        Component.onCompleted: {
            shapePath2.pathElements.push(Qt.createQmlObject('import QtQuick; import QtQuick.Shapes; PathMove {}', shapePath2))
            for (let i = 0; i < segments; i++) {
                cubics.push(cubicSeg.createObject(shapePath2))
                shapePath2.pathElements.push(cubics[i])
            }
            updateMorph()
        }

        Connections {
            target: CavaService
            function onValuesChanged() { if (morphingBlob.visible) morphingBlob.updateMorph() }
        }

        function updateMorph() {
            if (cubics.length === 0) return
            var alpha = 0.35
            var minLen = Math.min(smoothedLevels.length, audioLevels.length)
            for (var i = 0; i < minLen; i++)
                smoothedLevels[i] += alpha * (audioLevels[i] - smoothedLevels[i])
            var angleStep = 2 * Math.PI / segments
            var t3 = 0.16666667
            var startMv = shapePath2.pathElements[0]
            var pts = new Array(segments)
            for (var i = 0; i < segments; i++) {
                var ang = i * angleStep
                var lvl = smoothedLevels[i % 10] || 0
                var cl = lvl < 0 ? 0 : (lvl > 100 ? 100 : lvl)
                var al = Math.max(0.15, Math.sqrt(cl * 0.01)) * 0.5
                var r = baseRadius * (1.0 + al)
                pts[i] = { x: centerX + Math.cos(ang) * r, y: centerY + Math.sin(ang) * r }
            }
            startMv.x = pts[0].x; startMv.y = pts[0].y
            for (var i = 0; i < segments; i++) {
                var p0 = pts[(i + segments - 1) % segments]
                var p1 = pts[i]; var p2 = pts[(i + 1) % segments]; var p3 = pts[(i + 2) % segments]
                var c = cubics[i]
                c.control1X = p1.x + (p2.x - p0.x) * t3; c.control1Y = p1.y + (p2.y - p0.y) * t3
                c.control2X = p2.x - (p3.x - p1.x) * t3; c.control2Y = p2.y - (p3.y - p1.y) * t3
                c.x = p2.x; c.y = p2.y
            }
        }

        ShapePath {
            id: shapePath2
            fillColor: root.blobColor
            strokeColor: "transparent"; strokeWidth: 0
            joinStyle: ShapePath.RoundJoin; fillRule: ShapePath.WindingFill
        }
    }

    property real _rotation: 0
    NumberAnimation {
        id: albumRotation
        target: root; property: "_rotation"
        from: 0; to: 360; duration: 20000
        running: root.activePlayer && root.activePlayer.isPlaying
        loops: Animation.Infinite
    }

    DankCircularImage {
        anchors.centerIn: parent; z: 1
        width: 48; height: 48
        imageSource: {
            var p = root.activePlayer
            if (!p || !p.metadata) return ""
            return p.metadata["mpris:artUrl"] || ""
        }
        fallbackIcon: "album"
        border.color: host.musicBorderColor; border.width: 1.5
        transform: Rotation { origin.x: 24; origin.y: 24; angle: root._rotation }
    }
}

import QtQuick
import QtQuick.Shapes
import Quickshell
import qs.Common
import qs.Services
import qs.Widgets

Item {
    id: content
    property Item host
    readonly property var activePlayer: MprisController.activePlayer

    // Listen for dead-player signal from updateTimer
    property int _resetWatch: host.musicResetTick
    on_ResetWatchChanged: {
        if (contentItem.musicUIVisible && !contentItem.userPaused) {
            contentItem.musicUIVisible = false
            contentItem.hideMusicUITimer.stop()
        }
    }

    FontLoader { id: abelFont; source: "./fonts/Abel-Regular.ttf" }
    FontLoader { id: bebasFont; source: "./fonts/BebasNeue-Regular.ttf" }
    FontLoader { id: materialFont; source: "./fonts/Material.ttf" }

    SystemClock { id: sysClock; precision: SystemClock.Seconds }
    readonly property var _w: WeatherService.weather  // cache to reduce QObject lookups

    // ============================================
    // CONKY VIEW (visible when mouse is outside)
    // ============================================
    Rectangle {
        anchors.fill: parent
        radius: 8
        color: host.bg
        border.width: 0

        Image {
            source: "./bg.png"
            x: 0; y: host.yBase + 65
            width: parent.width
            height: parent.width * 1000 / 650
            fillMode: Image.PreserveAspectFit
            opacity: 1.0
        }

        // Block wheel scrolling in Conky view
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            onWheel: function(wheel) { wheel.accepted = true }
        }

        Flickable {
            anchors.fill: parent
            anchors.topMargin: 10
            contentWidth: parent.width
            contentHeight: contentItem.height + 20
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            interactive: false

            Item {
                id: contentItem
                width: parent.width
                height: host.yBase + 480

                // ============================================
                // Clock
                // ============================================
                Row {
                    visible: host.showClock
                    x: host.leftX - 12; y: host.yBase + 0

                    Text {
                        text: { var d = sysClock.date; return d ? String(d.getHours()).padStart(2,'0') : "--" }
                        font.family: abelFont.name; font.bold: true; font.pixelSize: 40
                        color: host.clockHourColor
                    }
                    Text {
                        text: ":"; font.family: abelFont.name; font.bold: true; font.pixelSize: 40
                        color: host.clockColonColor
                    }
                    Text {
                        text: { var d = sysClock.date; return d ? String(d.getMinutes()).padStart(2,'0') : "--" }
                        font.family: abelFont.name; font.bold: true; font.pixelSize: 40
                        color: host.clockMinuteColor
                    }
                    Text {
                        text: ":"; font.family: abelFont.name; font.bold: true; font.pixelSize: 40
                        color: host.clockColonColor
                    }
                    Text {
                        text: { var d = sysClock.date; return d ? String(d.getSeconds()).padStart(2,'0') : "--" }
                        font.family: abelFont.name; font.bold: true; font.pixelSize: 40
                        color: host.clockSecondColor
                    }
                }

                Row {
                    visible: host.showClock
                    x: host.leftX + 160; y: host.yBase + 35
                    spacing: 4

                    Text {
                        text: sysClock.date?.toLocaleDateString(Qt.locale(), "dddd") ?? ""
                        font.bold: true; font.family: abelFont.name; font.pixelSize: 15
                        color: host.dateWeekdayColor
                    }
                    Text {
                        text: sysClock.date?.toLocaleDateString(Qt.locale(), "d") ?? ""
                        font.bold: true; font.family: abelFont.name; font.pixelSize: 15
                        color: host.dateDayColor
                    }
                    Text {
                        text: sysClock.date?.toLocaleDateString(Qt.locale(), "MMMM") ?? ""
                        font.bold: true; font.family: abelFont.name; font.pixelSize: 15
                        color: host.dateMonthColor
                    }
                }

                // ============================================
                // Weather (matches Mimosa: icon + temp + city + desc + wind + humidity)
                // ============================================
                Text {
                    visible: host.showWeather
                    x: host.leftX; y: host.yBase + 60
                    text: host.weatherIcon(content._w.wCode, content._w.isDay)
                    font.pixelSize: 25
                    color: host.fg
                }
                Text {
                    visible: host.showWeather
                    x: 95; y: host.yBase + 65
                    text: content._w.available ? content._w.temp + "°C" : "--°C"
                    font.family: bebasFont.name
                    font.pixelSize: 22
                    color: host.fg
                }
                Text {
                    visible: host.showWeather
                    x: host.leftX; y: host.yBase + 95
                    text: content._w.available ? content._w.city : "Offline"
                    font.family: abelFont.name
                    font.bold: true
                    font.pixelSize: 18
                    color: host.accent2
                    width: 155
                    elide: Text.ElideRight
                }
                Text {
                    visible: host.showWeather
                    x: host.leftX; y: host.yBase + 115
                    text: content._w.available ? WeatherService.getWeatherCondition(content._w.wCode) : ""
                    font.family: abelFont.name
                    font.pixelSize: 15
                    color: host.fg
                    width: 155
                    elide: Text.ElideRight
                }
                Text {
                    visible: host.showWeather
                    x: host.leftX; y: host.yBase + 135
                    text: "Wind : " + (content._w.available ? content._w.wind + "km/h" : "--")
                    font.family: abelFont.name
                    font.pixelSize: 15
                    color: host.fg
                    width: 155
                    elide: Text.ElideRight
                }
                Text {
                    visible: host.showWeather
                    x: host.leftX; y: host.yBase + 155
                    text: "Humidity : " + (content._w.available ? content._w.humidity + "%" : "--")
                    font.family: abelFont.name
                    font.pixelSize: 15
                    color: host.fg
                    width: 155
                    elide: Text.ElideRight
                }

                // ============================================
                // Network (right side)
                // ============================================
                Text {
                    visible: host.showNetwork
                    x: host.rightX; y: host.yBase + 70
                    text: ""
                    font.family: materialFont.name
                    font.pixelSize: 15
                    color: host.accent
                }
                Text {
                    visible: host.showNetwork
                    x: host.rightX + 25; y: host.yBase + 70
                    text: DMSNetworkService.currentWifiSSID || "Network"
                    font.family: abelFont.name
                    font.bold: true
                    font.pixelSize: 15
                    color: host.fg
                }

                Text {
                    visible: host.showNetwork
                    x: host.rightX; y: host.yBase + 90
                    text: "Down : " + host.fmtBytes(DgopService.networkRxRate) + "/s"
                    font.family: abelFont.name
                    font.pixelSize: 15
                    color: host.fg
                }

                NetworkGraph {
                    id: downGraph
                    visible: host.showNetwork
                    x: host.rightX; y: host.yBase + 105
                    gradientStart: host.accent
                    gradientEnd: host.accent2
                }

                Text {
                    visible: host.showNetwork
                    x: host.rightX; y: host.yBase + 140
                    text: "Up : " + host.fmtBytes(DgopService.networkTxRate) + "/s"
                    font.family: abelFont.name
                    font.pixelSize: 15
                    color: host.fg
                }

                NetworkGraph {
                    id: upGraph
                    visible: host.showNetwork
                    x: host.rightX; y: host.yBase + 155
                    gradientStart: host.accent
                    gradientEnd: host.accent2
                }

                Timer {
                    interval: 2000; running: host.showNetwork && content.visible; repeat: true
                    onTriggered: {
                        var rx = DgopService.networkHistory.rx
                        if (rx && rx.length > 0) {
                            downGraph.data = rx.slice()
                            downGraph.maxVal = Math.max(1, ...rx)
                        }
                        var tx = DgopService.networkHistory.tx
                        if (tx && tx.length > 0) {
                            upGraph.data = tx.slice()
                            upGraph.maxVal = Math.max(1, ...tx)
                        }
                    }
                }

                // ============================================
                // Ring Gauges: CPU, MEM, Battery, Temp
                // ============================================
                RingGauge { id: cpuRing; x: 19; y: host.yBase + 234; pct: DgopService.cpuUsage / 100; gaugeColor: host.cpuGaugeColor; bgColor: host.ringBgColor }
                Text {
                    x: 16; y: host.yBase + 290; width: 58
                    horizontalAlignment: Text.AlignHCenter
                    text: DgopService.cpuUsage.toFixed(0) + "%"
                    font.family: bebasFont.name; font.pixelSize: 14; color: host.fg
                }

                RingGauge { id: memRing; x: 88; y: host.yBase + 234; pct: DgopService.memoryUsage / 100; gaugeColor: host.memGaugeColor; bgColor: host.ringBgColor }
                Text {
                    x: 88; y: host.yBase + 290; width: 58
                    horizontalAlignment: Text.AlignHCenter
                    text: DgopService.memoryUsage.toFixed(0) + "%"
                    font.family: bebasFont.name; font.pixelSize: 14; color: host.fg
                }

                RingGauge { id: batteryRing; x: 158; y: host.yBase + 234; pct: BatteryService.batteryAvailable ? BatteryService.batteryLevel / 100 : 1.0; gaugeColor: BatteryService.batteryAvailable ? host.batteryGaugeColor : host.batteryAcGaugeColor; bgColor: host.ringBgColor }
                Text {
                    x: 155; y: host.yBase + 290; width: 58
                    horizontalAlignment: Text.AlignHCenter
                    text: BatteryService.batteryAvailable ? BatteryService.batteryLevel.toFixed(0) + "%" : "AC"
                    font.family: bebasFont.name; font.pixelSize: 14; color: host.fg
                }

                RingGauge { id: tempRing; x: 228; y: host.yBase + 234; pct: DgopService.cpuTemperature > 0 ? Math.min(100, DgopService.cpuTemperature) / 100 : 0; gaugeColor: host.tempGaugeColor; bgColor: host.ringBgColor }
                Text {
                    x: 228; y: host.yBase + 290; width: 58
                    horizontalAlignment: Text.AlignHCenter
                    text: DgopService.cpuTemperature > 0 ? DgopService.cpuTemperature.toFixed(0) + "°C" : "--°C"
                    font.family: bebasFont.name; font.pixelSize: 14; color: host.fg
                }

                // ============================================
                // Storage
                // ============================================
                Text {
                    visible: host.showStorage
                    x: host.leftX; y: host.yBase + 365
                    width: 111
                    horizontalAlignment: Text.AlignHCenter
                    text: "Storage"
                    font.family: abelFont.name
                    font.bold: true
                    font.pixelSize: 18
                    color: host.fg
                }

                Text {
                    visible: host.showStorage
                    x: host.leftX; y: host.yBase + 390
                    text: "Root :"
                    font.family: abelFont.name
                    font.pixelSize: 15
                    color: host.fg
                }

                Rectangle {
                    visible: host.showStorage
                    x: host.leftX; y: host.yBase + 415
                    width: 111; height: 15; radius: 2
                    color: "#18ffffff"
                    Rectangle {
                        width: parent.width * host.sysDiskPct
                        height: 15; radius: 2
                        color: host.sysDiskPct > 0.9 ? "#EF4444" : (host.sysDiskPct > 0.5 ? "#F59E0B" : "#22C55E")
                        Behavior on color { ColorAnimation { duration: 600 } }
                    }
                }

                Text {
                    visible: host.showStorage
                    x: host.leftX + 4; y: host.yBase + 416
                    text: host.sysDiskInfo
                    font.family: abelFont.name
                    font.pixelSize: 12
                    color: host.fg
                }

                Text {
                    visible: host.showStorage
                    x: host.leftX; y: host.yBase + 433
                    text: "Home :"
                    font.family: abelFont.name
                    font.pixelSize: 15
                    color: host.fg
                }

                Rectangle {
                    visible: host.showStorage
                    x: host.leftX; y: host.yBase + 455
                    width: 111; height: 15; radius: 2
                    color: "#18ffffff"
                    Rectangle {
                        width: parent.width * host.homeDiskPct
                        height: 15; radius: 2
                        color: host.homeDiskPct > 0.9 ? "#EF4444" : (host.homeDiskPct > 0.5 ? "#F59E0B" : "#22C55E")
                        Behavior on color { ColorAnimation { duration: 600 } }
                    }
                }

                Text {
                    visible: host.showStorage
                    x: host.leftX + 4; y: host.yBase + 456
                    text: host.homeDiskInfo
                    font.family: abelFont.name
                    font.pixelSize: 12
                    color: host.fg
                }

                // ============================================
                // Music Player / System Info (right side)
                // ============================================
                readonly property bool isPlaying: content.activePlayer && content.activePlayer.isPlaying
                property bool musicUIVisible: isPlaying
                property bool userPaused: false

                onIsPlayingChanged: {
                    if (isPlaying) {
                        // Playback started/resumed — show music UI immediately, restart chase
                        musicUIVisible = true
                        userPaused = false
                        musicInfoBox._tick = -1
                        hideMusicUITimer.stop()
                    } else if (userPaused) {
                        // User explicitly paused — hide immediately
                        musicUIVisible = false
                        userPaused = false
                        hideMusicUITimer.stop()
                    } else {
                        // Track transition — debounce before hiding
                        hideMusicUITimer.start()
                    }
                }

                Timer {
                    id: hideMusicUITimer
                    interval: 1500
                    repeat: false
                    onTriggered: musicUIVisible = false
                }

                // Hardware info (when no music playing)
                Text {
                    visible: host.showMusic && !parent.musicUIVisible
                    x: host.rightX - 20; y: host.yBase + 365
                    width: 145
                    horizontalAlignment: Text.AlignHCenter
                    text: "HardWare"
                    font.family: abelFont.name
                    font.bold: true
                    font.pixelSize: 18
                    color: host.fg
                }
                Text {
                    visible: host.showMusic && !parent.musicUIVisible
                    x: host.rightX; y: host.yBase + 392
                    text: "CPU:"
                    font.family: abelFont.name
                    font.pixelSize: 15
                    color: host.fg
                }
                Text {
                    visible: host.showMusic && !parent.musicUIVisible
                    x: host.rightX + 4; y: host.yBase + 413
                    text: host.cpuModel || "Detecting..."
                    font.family: abelFont.name
                    font.pixelSize: 12
                    color: host.cpuInfoColor
                    width: 145
                    elide: Text.ElideRight
                }
                Text {
                    visible: host.showMusic && !parent.musicUIVisible
                    x: host.rightX; y: host.yBase + 435
                    text: "GPU:"
                    font.family: abelFont.name
                    font.pixelSize: 15
                    color: host.fg
                }
                Text {
                    visible: host.showMusic && !parent.musicUIVisible
                    x: host.rightX + 4; y: host.yBase + 456
                    text: host.gpuModel || "Detecting..."
                    font.family: abelFont.name
                    font.pixelSize: 12
                    color: host.gpuInfoColor
                    width: 145
                    elide: Text.ElideRight
                }

                // Double-click on HardWare area → launch splayer or resume playback
                MouseArea {
                    visible: host.showMusic && !parent.musicUIVisible
                    x: host.rightX - 20; y: host.yBase + 365
                    width: 165; height: 115
                    acceptedButtons: Qt.LeftButton
                    onDoubleClicked: host.triggerSplayerOrResume()
                }

                // Rotating album art with audio visualization
                Item {
                    id: albumArtBox
                    visible: host.showMusic && host.showRotatingAlbum && parent.musicUIVisible
                    x: host.rightX + 24; y: host.yBase + 395
                    width: 62; height: 62

                    Shape {
                        id: morphingBlob
                        width: parent.width * 1.3
                        height: parent.height * 1.3
                        anchors.centerIn: parent
                        visible: CavaService.cavaAvailable && content.activePlayer && content.activePlayer.isPlaying
                        asynchronous: false; antialiasing: true
                        preferredRendererType: Shape.CurveRenderer
                        z: 0

                        readonly property real centerX: width / 2
                        readonly property real centerY: height / 2
                        readonly property real baseRadius: Math.min(width, height) * 0.41
                        readonly property int segments: 24

                        property var audioLevels: {
                            if (!CavaService.cavaAvailable || CavaService.values.length === 0) {
                                return [0.5, 0.3, 0.7, 0.4, 0.6, 0.5, 0.8, 0.2, 0.9, 0.6]
                            }
                            return CavaService.values
                        }
                        property var smoothedLevels: [0.5, 0.3, 0.7, 0.4, 0.6, 0.5, 0.8, 0.2, 0.9, 0.6]
                        property var cubics: []

                        Component {
                            id: cubicSeg
                            PathCubic {}
                        }

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
                            function onValuesChanged() {
                                if (morphingBlob.visible) morphingBlob.updateMorph()
                            }
                        }

                        function updateMorph() {
                            if (cubics.length === 0) return
                            var alpha = 0.35
                            var minLen = Math.min(smoothedLevels.length, audioLevels.length)
                            for (var i = 0; i < minLen; i++) {
                                smoothedLevels[i] += alpha * (audioLevels[i] - smoothedLevels[i])
                            }
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
                                var p1 = pts[i]; var p2 = pts[(i + 1) % segments]
                                var p3 = pts[(i + 2) % segments]
                                var c = cubics[i]
                                c.control1X = p1.x + (p2.x - p0.x) * t3
                                c.control1Y = p1.y + (p2.y - p0.y) * t3
                                c.control2X = p2.x - (p3.x - p1.x) * t3
                                c.control2Y = p2.y - (p3.y - p1.y) * t3
                                c.x = p2.x; c.y = p2.y
                            }
                        }

                        ShapePath {
                            id: shapePath2
                            fillColor: host.blobColor
                            strokeColor: "transparent"
                            strokeWidth: 0
                            joinStyle: ShapePath.RoundJoin
                            fillRule: ShapePath.WindingFill
                        }
                    }

                    property real _rotation: 0
                    NumberAnimation {
                        id: albumRotation
                        target: albumArtBox; property: "_rotation"
                        from: 0; to: 360; duration: 20000
                        running: content.activePlayer && content.activePlayer.isPlaying
                        loops: Animation.Infinite
                    }

                    DankCircularImage {
                        anchors.centerIn: parent; z: 1
                        width: 48; height: 48
                        imageSource: {
                            var p = content.activePlayer
                            if (!p || !p.metadata) return ""
                            return p.metadata["mpris:artUrl"] || ""
                        }
                        fallbackIcon: "album"
                        border.color: host.accent
                        border.width: 1.5
                        transform: Rotation {
                            origin.x: 24; origin.y: 24
                            angle: albumArtBox._rotation
                        }
                    }
                }

                // Music info (when playing)
                Item {
                    id: musicInfoBox
                    visible: host.showMusic && parent.musicUIVisible
                    x: host.rightX - 20; y: host.yBase + 365
                    width: 145; height: 22

                    property int _tick: -1

                    Timer {
                        interval: 2000
                        running: content.activePlayer && content.activePlayer.isPlaying
                        repeat: true
                        onTriggered: {
                            musicInfoBox._tick = (musicInfoBox._tick + 1) % 7
                            var colors = ["#FF1493","#F97316","#EAB308","#22C55E","#0EA5E9","#8B5CF6","#D946EF"]
                            var c = colors[musicInfoBox._tick]
                            // Icon and current char share same color
                            musicIcon.color = c
                            // Reset all chars to white, then light up only the active one
                            _pc0.color = host.fg; _pc1.color = host.fg; _pc2.color = host.fg; _pc3.color = host.fg
                            _pc4.color = host.fg; _pc5.color = host.fg; _pc6.color = host.fg
                            var chars = [_pc0, _pc1, _pc2, _pc3, _pc4, _pc5, _pc6]
                            chars[musicInfoBox._tick].color = c
                        }
                    }

                    Row {
                        anchors.centerIn: parent
                        spacing: 0

                        Text {
                            id: musicIcon
                            text: ""
                            font.family: materialFont.name
                            font.pixelSize: 18
                            color: host.accent2
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Item { width: 6; height: 1 }

                        Text { id: _pc0; text: "P"; font.family: abelFont.name; font.bold: true; font.pixelSize: 18; color: host.fg; anchors.verticalCenter: parent.verticalCenter }
                        Text { id: _pc1; text: "l"; font.family: abelFont.name; font.bold: true; font.pixelSize: 18; color: host.fg; anchors.verticalCenter: parent.verticalCenter }
                        Text { id: _pc2; text: "a"; font.family: abelFont.name; font.bold: true; font.pixelSize: 18; color: host.fg; anchors.verticalCenter: parent.verticalCenter }
                        Text { id: _pc3; text: "y"; font.family: abelFont.name; font.bold: true; font.pixelSize: 18; color: host.fg; anchors.verticalCenter: parent.verticalCenter }
                        Text { id: _pc4; text: "i"; font.family: abelFont.name; font.bold: true; font.pixelSize: 18; color: host.fg; anchors.verticalCenter: parent.verticalCenter }
                        Text { id: _pc5; text: "n"; font.family: abelFont.name; font.bold: true; font.pixelSize: 18; color: host.fg; anchors.verticalCenter: parent.verticalCenter }
                        Text { id: _pc6; text: "g"; font.family: abelFont.name; font.bold: true; font.pixelSize: 18; color: host.fg; anchors.verticalCenter: parent.verticalCenter }
                    }
                }
                Text {
                    visible: host.showMusic && !host.showRotatingAlbum && parent.musicUIVisible
                    x: host.rightX; y: host.yBase + 392
                    text: {
                        var p = content.activePlayer
                        if (!p || !p.metadata) return ""
                        return p.metadata["xesam:artist"] ? p.metadata["xesam:artist"].join(", ") : ""
                    }
                    font.family: abelFont.name
                    font.bold: true
                    font.pixelSize: 15
                    color: host.accent2
                    width: 110
                    elide: Text.ElideRight
                }
                Text {
                    visible: host.showMusic && !host.showRotatingAlbum && parent.musicUIVisible
                    x: host.rightX; y: host.yBase + 413
                    text: {
                        var p = content.activePlayer
                        if (!p || !p.metadata) return ""
                        return p.metadata["xesam:title"] || ""
                    }
                    font.family: abelFont.name
                    font.italic: true
                    font.pixelSize: 12
                    color: host.fg
                    width: 110
                    elide: Text.ElideRight
                }
                Text {
                    visible: host.showMusic && !host.showRotatingAlbum && parent.musicUIVisible
                    x: host.rightX; y: host.yBase + 435
                    text: host.musicElapsed
                    font.family: abelFont.name
                    font.pixelSize: 12
                    color: host.fg
                }

                // Double-click on music playing area → pause
                MouseArea {
                    visible: host.showMusic && parent.musicUIVisible
                    x: host.rightX - 20; y: host.yBase + 365
                    width: 165; height: 115
                    acceptedButtons: Qt.LeftButton
                    onDoubleClicked: {
                        var p = content.activePlayer
                        if (p) { contentItem.userPaused = true; p.togglePlaying() }
                    }
                }

                // Music control buttons (previous / play-pause / next)
                Row {
                    visible: host.showMusic && parent.musicUIVisible
                    x: host.rightX + 10; y: host.yBase + 456
                    spacing: 8

                        MouseArea {
                            width: 24; height: 24
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                var p = content.activePlayer
                                if (p) p.previous()
                            }
                            DankIcon {
                                anchors.centerIn: parent
                                name: "skip_previous"
                                size: 20
                                color: host.fg
                            }
                        }

                        MouseArea {
                            width: 24; height: 24
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                var p = content.activePlayer
                                if (p) { contentItem.userPaused = true; p.togglePlaying() }
                            }
                            DankIcon {
                                anchors.centerIn: parent
                                name: "pause"
                                size: 22
                                color: host.fg
                            }
                        }

                        MouseArea {
                            width: 24; height: 24
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                var p = content.activePlayer
                                if (p) p.next()
                            }
                            DankIcon {
                                anchors.centerIn: parent
                                name: "skip_next"
                                size: 20
                                color: host.fg
                            }
                        }
                    }

                // ============================================
                // Full-area ambient particles
                // ============================================
                Canvas {
                    id: bottomParticles
                    anchors.fill: parent
                    opacity: host.particleOpacity
                    z: -1

                    property var particles: []
                    property int tick: 0

                    function spawn() {
                        if (particles.length >= host.particleCount) return
                        particles.push({
                            x: Math.random() * width,
                            y: Math.random() * height,
                            vx: (Math.random() - 0.5) * 12,
                            vy: -(8 + Math.random() * 16),
                            size: 1 + Math.random() * host.particleSize,
                            life: 1.0,
                            decay: 0.3 + Math.random() * 0.5,
                            hue: Math.random(),
                            sat: 0.7 + Math.random() * 0.3,
                            lit: 0.7 + Math.random() * 0.28
                        })
                    }

                    function drawShape(ctx, p) {
                        var s = p.size * (0.3 + p.life * 0.7)
                        var style = host.particleStyle || "circles"
                        switch (style) {
                            case "squares":
                                ctx.fillRect(p.x - s/2, p.y - s/2, s, s)
                                break
                            case "triangles":
                                ctx.beginPath()
                                ctx.moveTo(p.x, p.y - s)
                                ctx.lineTo(p.x - s * 0.866, p.y + s * 0.5)
                                ctx.lineTo(p.x + s * 0.866, p.y + s * 0.5)
                                ctx.closePath()
                                ctx.fill()
                                break
                            case "stars":
                                ctx.beginPath()
                                var inner = s * 0.35
                                for (var k = 0; k < 4; k++) {
                                    var a = (Math.PI / 2) * k - Math.PI / 2
                                    ctx.lineTo(p.x + Math.cos(a) * s, p.y + Math.sin(a) * s)
                                    ctx.lineTo(p.x + Math.cos(a + Math.PI/4) * inner, p.y + Math.sin(a + Math.PI/4) * inner)
                                }
                                ctx.closePath()
                                ctx.fill()
                                break
                            case "lines":
                                ctx.beginPath()
                                ctx.moveTo(p.x - s, p.y)
                                ctx.lineTo(p.x + s, p.y)
                                ctx.lineWidth = Math.max(1, s * 0.4)
                                ctx.stroke()
                                break
                            default: // circles
                                ctx.beginPath()
                                ctx.arc(p.x, p.y, s, 0, Math.PI * 2)
                                ctx.fill()
                                break
                        }
                    }

                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.clearRect(0, 0, width, height)
                        ctx.shadowBlur = 4
                        for (var i = 0; i < particles.length; i++) {
                            var p = particles[i]
                            if (p.life <= 0) continue
                            ctx.globalAlpha = (0.25 + p.life * 0.75) * host.particleOpacity
                            ctx.shadowColor = Qt.hsla(p.hue, p.sat, p.lit, 1.0)
                            ctx.fillStyle = Qt.hsla(p.hue, p.sat, p.lit, 1.0)
                            ctx.strokeStyle = Qt.hsla(p.hue, p.sat, p.lit, 1.0)
                            bottomParticles.drawShape(ctx, p)
                        }
                    }

                    Timer {
                        interval: 66; running: content.visible; repeat: true
                        onTriggered: {
                            bottomParticles.tick++
                            if (bottomParticles.tick % 3 === 0) bottomParticles.spawn()
                            if (bottomParticles.tick % 5 === 0) bottomParticles.spawn()

                            var dt = 0.066
                            var alive = []
                            var p = bottomParticles.particles
                            for (var i = 0; i < p.length; i++) {
                                var pt = p[i]
                                pt.x += pt.vx * dt
                                pt.y += pt.vy * dt
                                pt.vy += 1.5 * dt
                                pt.life -= pt.decay * dt
                                if (pt.life > 0 && pt.y > -10 && pt.y < bottomParticles.height + 10) {
                                    alive.push(pt)
                                }
                            }
                            bottomParticles.particles = alive
                            bottomParticles.requestPaint()
                        }
                    }
                }
            }
        }
    }
}

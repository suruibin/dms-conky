import QtQuick
import Quickshell
import qs.Common
import qs.Services

Item {
    id: content
    property Item host

    FontLoader { id: abelFont; source: "./fonts/Abel-Regular.ttf" }
    FontLoader { id: bebasFont; source: "./fonts/BebasNeue-Regular.ttf" }
    FontLoader { id: materialFont; source: "./fonts/Material.ttf" }

    SystemClock { id: sysClock; precision: SystemClock.Seconds }

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

        Flickable {
            anchors.fill: parent
            anchors.topMargin: 10
            contentWidth: parent.width
            contentHeight: contentItem.height + 20
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Item {
                id: contentItem
                width: parent.width
                height: host.yBase + 480

                // ============================================
                // Clock
                // ============================================
                Text {
                    visible: host.showClock
                    x: host.leftX-12; y: host.yBase + 0
                    text: {
                        var d = sysClock.date
                        if (!d) return "--:--:--"
                        var h = d.getHours(), m = d.getMinutes(), s = d.getSeconds()
                        return String(h).padStart(2,'0') + ":" + String(m).padStart(2,'0') + ":" + String(s).padStart(2,'0')
                    }
                    font.family: abelFont.name
                    font.weight: Font.Bold
                    font.pixelSize: 40
                    color: host.fg
                }

                Text {
                    visible: host.showClock
                    x: host.leftX + 160; y: host.yBase + 35
                    text: sysClock.date?.toLocaleDateString(Qt.locale(), "dddd d MMMM") ?? ""
                    font.weight: Font.Bold
                    font.family: abelFont.name
                    font.pixelSize: 15
                    color: host.fg
                }

                // ============================================
                // Weather (matches Mimosa: icon + temp + city + desc + wind + humidity)
                // ============================================
                Text {
                    visible: host.showWeather
                    x: host.leftX; y: host.yBase + 60
                    text: host.weatherIcon(WeatherService.weather.wCode, WeatherService.weather.isDay)
                    font.pixelSize: 25
                    color: host.fg
                }
                Text {
                    visible: host.showWeather
                    x: 95; y: host.yBase + 65
                    text: WeatherService.weather.available ? WeatherService.weather.temp + "°C" : "--°C"
                    font.family: bebasFont.name
                    font.pixelSize: 22
                    color: host.fg
                }
                Text {
                    visible: host.showWeather
                    x: host.leftX; y: host.yBase + 95
                    text: WeatherService.weather.available ? WeatherService.weather.city : "Offline"
                    font.family: abelFont.name
                    font.weight: Font.Bold
                    font.pixelSize: 18
                    color: host.accent2
                    width: 155
                    elide: Text.ElideRight
                }
                Text {
                    visible: host.showWeather
                    x: host.leftX; y: host.yBase + 115
                    text: WeatherService.weather.available ? WeatherService.getWeatherCondition(WeatherService.weather.wCode) : ""
                    font.family: abelFont.name
                    font.pixelSize: 15
                    color: host.fg
                    width: 155
                    elide: Text.ElideRight
                }
                Text {
                    visible: host.showWeather
                    x: host.leftX; y: host.yBase + 135
                    text: "Wind : " + (WeatherService.weather.available ? WeatherService.weather.wind + "km/h" : "--")
                    font.family: abelFont.name
                    font.pixelSize: 15
                    color: host.fg
                    width: 155
                    elide: Text.ElideRight
                }
                Text {
                    visible: host.showWeather
                    x: host.leftX; y: host.yBase + 155
                    text: "Humidity : " + (WeatherService.weather.available ? WeatherService.weather.humidity + "%" : "--")
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
                    text: ""
                    font.family: materialFont.name
                    font.pixelSize: 15
                    color: host.accent
                }
                Text {
                    visible: host.showNetwork
                    x: host.rightX + 25; y: host.yBase + 70
                    text: DMSNetworkService.currentWifiSSID || "Network"
                    font.family: abelFont.name
                    font.weight: Font.Bold
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
                    interval: 1000; running: host.showNetwork; repeat: true
                    onTriggered: {
                        var rx = DgopService.networkHistory.rx
                        if (rx && rx.length > 0) {
                            downGraph.data = rx.slice()
                            downGraph.maxVal = Math.max(1, Math.max.apply(null, rx))
                        }
                        var tx = DgopService.networkHistory.tx
                        if (tx && tx.length > 0) {
                            upGraph.data = tx.slice()
                            upGraph.maxVal = Math.max(1, Math.max.apply(null, tx))
                        }
                    }
                }

                // ============================================
                // Ring Gauges: CPU, MEM, Battery, Temp
                // ============================================
                RingGauge { id: cpuRing; x: 19; y: host.yBase + 234; pct: DgopService.cpuUsage / 100; gaugeColor: host.accent }
                Text {
                    x: 16; y: host.yBase + 290; width: 58
                    horizontalAlignment: Text.AlignHCenter
                    text: DgopService.cpuUsage.toFixed(0) + "%"
                    font.family: bebasFont.name; font.pixelSize: 14; color: host.fg
                }

                RingGauge { id: memRing; x: 88; y: host.yBase + 234; pct: DgopService.memoryUsage / 100; gaugeColor: "#8B0AC3" }
                Text {
                    x: 88; y: host.yBase + 290; width: 58
                    horizontalAlignment: Text.AlignHCenter
                    text: DgopService.memoryUsage.toFixed(0) + "%"
                    font.family: bebasFont.name; font.pixelSize: 14; color: host.fg
                }

                RingGauge { id: batteryRing; x: 158; y: host.yBase + 234; pct: BatteryService.batteryAvailable ? BatteryService.batteryLevel / 100 : 0; gaugeColor: "#C20EAC" }
                Text {
                    x: 155; y: host.yBase + 290; width: 58
                    horizontalAlignment: Text.AlignHCenter
                    text: BatteryService.batteryAvailable ? BatteryService.batteryLevel.toFixed(0) + "%" : "--%"
                    font.family: bebasFont.name; font.pixelSize: 14; color: host.fg
                }

                RingGauge { id: tempRing; x: 228; y: host.yBase + 234; pct: DgopService.cpuTemperature > 0 ? Math.min(100, DgopService.cpuTemperature) / 100 : 0; gaugeColor: "#FF1493" }
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
                    x: host.leftX; y: host.yBase + 365
                    text: "Storage"
                    font.family: abelFont.name
                    font.weight: Font.Bold
                    font.pixelSize: 18
                    color: host.fg
                }

                Text {
                    x: host.leftX; y: host.yBase + 390
                    text: "System :"
                    font.family: abelFont.name
                    font.pixelSize: 15
                    color: host.fg
                }

                Rectangle {
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
                    x: host.leftX + 4; y: host.yBase + 416
                    text: host.sysDiskInfo
                    font.family: abelFont.name
                    font.pixelSize: 12
                    color: host.fg
                }

                Text {
                    x: host.leftX; y: host.yBase + 433
                    text: "Home :"
                    font.family: abelFont.name
                    font.pixelSize: 15
                    color: host.fg
                }

                Rectangle {
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
                    x: host.leftX + 4; y: host.yBase + 456
                    text: host.homeDiskInfo
                    font.family: abelFont.name
                    font.pixelSize: 12
                    color: host.fg
                }

                // ============================================
                // Music Player / MPD (right side)
                // ============================================
                Text {
                    visible: host.showMusic
                    x: host.rightX; y: host.yBase + 360
                    text: ""
                    font.family: materialFont.name
                    font.pixelSize: 20
                    color: host.accent2
                }
                Text {
                    visible: host.showMusic
                    x: host.rightX; y: host.yBase + 390
                    text: {
                        var p = MprisController.activePlayer
                        if (!p) return "No music played"
                        if (p.isPlaying) return "Playing :"
                        return "Paused :"
                    }
                    font.family: abelFont.name
                    font.pixelSize: 15
                    color: host.fg
                }
                Text {
                    visible: host.showMusic
                    x: host.rightX; y: host.yBase + 410
                    text: {
                        var p = MprisController.activePlayer
                        if (!p || !p.metadata) return ""
                        return p.metadata["xesam:artist"] ? p.metadata["xesam:artist"].join(", ") : ""
                    }
                    font.family: abelFont.name
                    font.weight: Font.Bold
                    font.pixelSize: 15
                    color: host.accent2
                    width: 110
                    elide: Text.ElideRight
                }
                Text {
                    visible: host.showMusic
                    x: host.rightX; y: host.yBase + 430
                    text: {
                        var p = MprisController.activePlayer
                        if (!p || !p.metadata) return ""
                        return p.metadata["xesam:title"] || ""
                    }
                    font.family: abelFont.name
                    font.italic: true
                    font.pixelSize: 15
                    color: host.fg
                    width: 110
                    elide: Text.ElideRight
                }
                Text {
                    visible: host.showMusic
                    x: host.rightX; y: host.yBase + 455
                    text: host.musicElapsed
                    font.family: abelFont.name
                    font.pixelSize: 15
                    color: host.fg
                }
            }
        }
    }
}

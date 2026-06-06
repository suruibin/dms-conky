import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins

DesktopPluginComponent {
    id: root

    // Accept keyboard focus for text input (search boxes)
    property bool acceptsKeyboardFocus: true

    minWidth: 280
    minHeight: 500
    widgetWidth: getData("widgetWidth", 330)
    widgetHeight: getData("widgetHeight", 620)

    readonly property string accentColor: getData("accentColor", "#5105DB")
    readonly property string accent2Color: getData("accent2Color", "#FF1493")
    readonly property real bgOpacity: getData("bgOpacity", 0.0)
    readonly property bool showClock: getData("showClock", true)
    readonly property bool showNetwork: getData("showNetwork", true)
    readonly property bool showWeather: getData("showWeather", true)
    readonly property bool showMusic: getData("showMusic", true)

    readonly property color bg: Theme.withAlpha("#0a0a0f", bgOpacity)
    readonly property color fg: "#f0f0f0"
    readonly property color dim: "#aaaaaa"
    readonly property color accent: accentColor
    readonly property color accent2: accent2Color

    // Ring gauge colors
    readonly property color cpuGaugeColor: getData("cpuGaugeColor", "#5105DB")
    readonly property color memGaugeColor: getData("memGaugeColor", "#8B0AC3")
    readonly property color batteryGaugeColor: getData("batteryGaugeColor", "#C20EAC")
    readonly property color batteryAcGaugeColor: getData("batteryAcGaugeColor", "#22C55E")
    readonly property color tempGaugeColor: getData("tempGaugeColor", "#FF1493")

    // Clock / Date per-part colors
    readonly property color clockHourColor: getData("clockHourColor", "#f0f0f0")
    readonly property color clockMinuteColor: getData("clockMinuteColor", "#f0f0f0")
    readonly property color clockSecondColor: getData("clockSecondColor", "#f0f0f0")
    readonly property color clockColonColor: getData("clockColonColor", "#f0f0f0")
    readonly property color dateWeekdayColor: getData("dateWeekdayColor", "#f0f0f0")
    readonly property color dateDayColor: getData("dateDayColor", "#f0f0f0")
    readonly property color dateMonthColor: getData("dateMonthColor", "#f0f0f0")

    readonly property int leftX: 14
    readonly property int rightX: 172
    readonly property int yBase: 0

    readonly property var activeModules: ["cpu", "memory", "network", "disk", "diskmounts", "system"]

    // Mouse hover detection — switches between Conky and AppLauncher views
    property bool mouseHovered: false
    property real hoverMouseX: 0
    property real hoverMouseY: 0
    property real _rawMouseX: 0
    property real _rawMouseY: 0

    // Exclusion zone: entire bottom strip from Storage/HardWare row to widget bottom
    readonly property rect bottomZone: Qt.rect(0, yBase + 363, root.width, root.height - (yBase + 363))

    function isInExclusionZone(x, y) {
        return x >= bottomZone.x && x <= bottomZone.x + bottomZone.width &&
               y >= bottomZone.y && y <= bottomZone.y + bottomZone.height
    }

    // Throttle hover position updates to 80ms (~12Hz instead of per-pixel)
    Timer {
        id: hoverThrottle
        interval: 80; running: root.mouseHovered; repeat: true
        onTriggered: { root.hoverMouseX = root._rawMouseX; root.hoverMouseY = root._rawMouseY }
    }

    // --- App Launcher properties ---
    property string appSearchQuery: ""
    property bool appEditMode: false
    readonly property real appSize: getData("appSize", 88)
    readonly property string appViewMode: pluginData.viewMode ?? "grid"
    readonly property bool appShowHeader: pluginData.showHeader ?? true
    readonly property real appLauncherBgOpacity: (pluginData.backgroundOpacity ?? 80) / 100
    readonly property real appIconSize: Math.max(28, Math.round(appSize * 0.58))
    property var addedApps: pluginData.addedApps !== undefined ? pluginData.addedApps : []

    readonly property bool hasActivePlayer: MprisController.activePlayer !== null && MprisController.activePlayer !== undefined
    property int musicTick: 0
    readonly property string musicElapsed: {
        var p = MprisController.activePlayer
        if (!p || !p.isPlaying || p.position < 0) return ""
        var s = Math.floor(p.position)
        return Math.floor(s/60) + ":" + String(s%60).padStart(2,'0')
    }

    property string cpuModel: ""
    property string gpuModel: ""
    property color cpuInfoColor: "#f0f0f0"
    property color gpuInfoColor: "#f0f0f0"

    function randomVibrantColor() {
        // HSL: random hue, high saturation, high lightness (visible on dark bg, never black)
        var h = Math.random()
        var s = 0.7 + Math.random() * 0.3   // 0.7–1.0
        var l = 0.60 + Math.random() * 0.2  // 0.60–0.80
        return Qt.hsla(h, s, l, 1.0)
    }

    property var diskCache: ({ sysPct: 0, sysInfo: "-- / --", homePct: 0, homeInfo: "-- / --" })
    readonly property real sysDiskPct: diskCache.sysPct
    readonly property string sysDiskInfo: diskCache.sysInfo
    readonly property real homeDiskPct: diskCache.homePct
    readonly property string homeDiskInfo: diskCache.homeInfo

    function refreshDiskCache() {
        var m = DgopService.diskMounts
        var c = { sysPct: 0, sysInfo: "-- / --", homePct: 0, homeInfo: "-- / --" }
        for (var i = 0; i < m.length; i++) {
            if (m[i].mount === "/") { c.sysPct = parseFloat(m[i].percent) / 100; c.sysInfo = m[i].used + " / " + m[i].size }
            else if (m[i].mount === "/home") { c.homePct = parseFloat(m[i].percent) / 100; c.homeInfo = m[i].used + " / " + m[i].size }
            if (c.sysPct > 0 && c.homePct > 0) break
        }
        root.diskCache = c
    }

    property bool _wasPlaying: false

    Timer {
        id: updateTimer
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            var playing = hasActivePlayer && MprisController.activePlayer && MprisController.activePlayer.isPlaying
            if (showMusic && playing && !mouseHovered) {
                musicTick++
            }
            // Regenerate CPU/GPU colors when transitioning from playing → paused/stopped
            if (_wasPlaying && !playing) {
                root.cpuInfoColor = randomVibrantColor()
                root.gpuInfoColor = randomVibrantColor()
            }
            _wasPlaying = playing
        }
    }

    Timer { id: diskTimer; interval: 60000; running: true; repeat: true; onTriggered: root.refreshDiskCache() }
    Timer { interval: 1500; running: true; repeat: false; onTriggered: root.refreshDiskCache() }

    Component.onCompleted: {
        DgopService.addRef(activeModules)
        WeatherService.addRef()

        // Random colors for CPU / GPU info
        root.cpuInfoColor = randomVibrantColor()
        root.gpuInfoColor = randomVibrantColor()

        // Detect CPU model
        let cpuProc = Qt.createQmlObject(`
            import Quickshell.Io
            Process {
                command: ["sh", "-c", "/usr/bin/grep -m1 'model name' /proc/cpuinfo | sed 's/.*: //; s/(R)//g; s/(TM)//g; s/ CPU//g; s/[0-9]*th Gen //; s/Core //; s/  */ /g'"]
                running: true
                stdout: StdioCollector {
                    onStreamFinished: root.cpuModel = text.trim()
                }
            }`, root)

        // Detect GPU model
        let gpuProc = Qt.createQmlObject(`
            import Quickshell.Io
            Process {
                command: ["/usr/bin/lspci"]
                running: true
                stdout: StdioCollector {
                    onStreamFinished: {
                        var lines = text.split("\\n")
                        for (var i = 0; i < lines.length; i++) {
                            var line = lines[i]
                            if (line.indexOf("VGA") >= 0 || line.indexOf("3D") >= 0 || line.indexOf("Display") >= 0) {
                                var vendor = ""
                                if (line.indexOf("NVIDIA") >= 0) vendor = "NVIDIA "
                                else if (line.indexOf("AMD") >= 0) vendor = "AMD "
                                else if (line.indexOf("Intel") >= 0) vendor = "Intel "
                                var match = line.match(/\\[(.*?)\\]/)
                                if (match) {
                                    root.gpuModel = vendor + match[1].replace("GeForce ", "").replace("Radeon ", "")
                                }
                                break
                            }
                        }
                    }
                }
            }`, root)
    }
    Component.onDestruction: {
        DgopService.removeRef(activeModules)
        WeatherService.removeRef()
    }

    // Format bytes to human-readable
    function fmtBytes(b) {
        if (b < 1024)       return Math.round(b) + " B"
        if (b < 1048576)    return Math.round(b / 1024) + " KB"
        if (b < 1073741824) return Math.round(b / 1048576) + " MB"
        return Math.round(b / 1073741824) + " GB"
    }

    // Strip Freedesktop Exec field codes (%u, %U, %f, %F) that
    // don't apply to a simple launcher with no file/URL argument.
    function cleanExec(execStr) {
        if (!execStr) return ""
        return execStr.replace(/\s*%[uUfF]/g, "").replace(/\s+/g, " ").trim()
    }

    function weatherIcon(code, isDay) {
        if (code === 0 || code === 1) return isDay ? "☀" : "☾"
        if (code === 2) return "⛅"
        if (code === 3) return "☁"
        if (code === 45 || code === 48) return "🌫"
        // drizzle (51-57), rain (61-67), showers (80-86) → all rain
        if ((code >= 51 && code <= 57) || (code >= 61 && code <= 67) || (code >= 80 && code <= 86)) return "🌧"
        if (code >= 71 && code <= 77) return "🌨"
        if (code >= 95 && code <= 99) return "⛈"
        return "☁"
    }

    function saveAddedApps(newList) {
        if (pluginService) pluginService.savePluginData(pluginId, "addedApps", newList)
        root.addedApps = newList
    }

    function addApp(app) {
        var list = root.addedApps.slice()
        if (!list.some(function(a) { return a.name === app.name })) {
            list.push(app)
            saveAddedApps(list)
        }
    }

    function removeApp(appName) {
        var list = root.addedApps.slice()
        list = list.filter(function(a) { return a.name !== appName })
        saveAddedApps(list)
    }

    function moveAppToIndex(from, to) {
        if (from === to || from < 0 || to < 0) return
        if (from >= root.addedApps.length || to >= root.addedApps.length) return
        var list = root.addedApps.slice()
        var item = list.splice(from, 1)[0]
        list.splice(to, 0, item)
        saveAddedApps(list)
    }

    // ============================================
    // CONKY VIEW (visible when mouse is outside)
    // ============================================
    ConkyContent {
        visible: !root.mouseHovered
        anchors.fill: parent
        host: root
    }

    // ============================================
    // APP LAUNCHER VIEW (visible when mouse hovers)
    // ============================================
    AppLauncherContent {
        id: launcherContent
        visible: root.mouseHovered || launcherContent._keepVisible
        anchors.fill: parent
        host: root
    }

    // --- Global hover (widget switching + position for delegate effects) ---
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        onContainsMouseChanged: {
            if (!containsMouse) root.mouseHovered = false
        }
        onPositionChanged: function(mouse) {
            root._rawMouseX = mouse.x
            root._rawMouseY = mouse.y
            root.mouseHovered = containsMouse && !isInExclusionZone(mouse.x, mouse.y)
        }
    }
}

import QtQuick
import QtQuick.Controls
import Quickshell
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins
import "./dms-common"

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

    readonly property int leftX: 14
    readonly property int rightX: 172
    readonly property int yBase: 0

    // Mouse hover detection — switches between Conky and AppLauncher views
    property bool mouseHovered: false
    property real hoverMouseX: 0
    property real hoverMouseY: 0
    property real _rawMouseX: 0
    property real _rawMouseY: 0

    // Throttle hover position updates to 80ms (~12Hz instead of per-pixel)
    Timer {
        id: hoverThrottle
        interval: 80; running: root.mouseHovered; repeat: true
        onTriggered: { root.hoverMouseX = root._rawMouseX; root.hoverMouseY = root._rawMouseY }
    }

    // --- App Launcher properties ---
    property string appSearchQuery: ""
    property bool appEditMode: false
    readonly property real appSize: pluginData.appSize ?? 88
    readonly property string appViewMode: pluginData.viewMode ?? "grid"
    readonly property bool appShowHeader: pluginData.showHeader ?? true
    readonly property real appLauncherBgOpacity: (pluginData.backgroundOpacity ?? 80) / 100
    readonly property real appIconSize: Math.max(28, Math.round(appSize * 0.58))
    property var addedApps: pluginData.addedApps !== undefined ? pluginData.addedApps : []

    property bool hasActivePlayer: MprisController.activePlayer !== null && MprisController.activePlayer !== undefined
    property int musicTick: 0
    readonly property string musicElapsed: {
        var _t = musicTick
        var p = MprisController.activePlayer
        if (!p || !p.isPlaying || p.position < 0) return ""
        var s = Math.floor(p.position)
        return Math.floor(s/60) + ":" + String(s%60).padStart(2,'0')
    }
    Timer {
        interval: 1000; running: !root.mouseHovered && root.showMusic && root.hasActivePlayer; repeat: true
        onTriggered: root.musicTick++
    }

    // Disk cache — single traversal, refreshed every 60s
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

    Timer { interval: 60000; running: true; repeat: true; onTriggered: root.refreshDiskCache() }
    Timer { interval: 1500; running: true; repeat: false; onTriggered: root.refreshDiskCache() }

    property var activeModules: ["cpu", "memory", "network", "disk", "diskmounts", "system"]

    Component.onCompleted: {
        DgopService.addRef(activeModules)
        WeatherService.addRef()
    }
    Component.onDestruction: {
        DgopService.removeRef(activeModules)
        WeatherService.removeRef()
    }

    function fmtBytes(b) {
        if (b < 1024) return Math.round(b) + "B"
        if (b < 1048576) return Math.round(b/1024) + "KiB"
        if (b < 1073741824) return Math.round(b/1048576) + "MiB"
        return Math.round(b/1073741824) + "GiB"
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
        if (code >= 51 && code <= 57) return "🌧"
        if (code >= 61 && code <= 67) return "🌧"
        if (code >= 71 && code <= 77) return "🌨"
        if (code >= 80 && code <= 86) return "🌧"
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
        visible: root.mouseHovered
        anchors.fill: parent
        host: root
    }

    // --- Global hover (widget switching + position for delegate effects) ---
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        onContainsMouseChanged: root.mouseHovered = containsMouse
        onPositionChanged: function(mouse) {
            root._rawMouseX = mouse.x
            root._rawMouseY = mouse.y
        }
    }
}

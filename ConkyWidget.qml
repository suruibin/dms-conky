import QtQuick
import QtQuick.Controls
import Quickshell.Wayland
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins
import "conky"
import "launcher"
DesktopPluginComponent {
    id: root

    // Accept keyboard focus for text input (search boxes)
    property bool acceptsKeyboardFocus: true

    // DMS File Manager — loads from ~/.config/DankMaterialShell/plugins/dmsfilemanager if present
    readonly property string dmsFileManagerPath: "/home/suruibin/.config/DankMaterialShell/plugins/dmsfilemanager/DmsFileManager.qml"
    property bool dmsFileManagerExists: false

    // Runtime check: does DmsFileManager.qml exist?
    Process {
        id: dmsFmCheck
        command: ["sh", "-c", "test -f '" + root.dmsFileManagerPath + "' && echo 1 || echo 0"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                root.dmsFileManagerExists = text.trim() === "1"
            }
        }
    }

    function toggleDmsFileManager() {
        if (!root.dmsFileManagerExists) return
        if (!root._dfmId) {
            var instances = SettingsData.desktopWidgetInstances || []
            for (var i = 0; i < instances.length; i++) {
                if (instances[i].widgetType === "dmsfilemanager") {
                    root._dfmId = instances[i].id
                    break
                }
            }
        }
        if (root._dfmId) {
            var insts = SettingsData.desktopWidgetInstances || []
            for (var i = 0; i < insts.length; i++) {
                if (insts[i].id === root._dfmId) {
                    SettingsData.updateDesktopWidgetInstance(root._dfmId, { enabled: !insts[i].enabled })
                    break
                }
            }
        }
    }

    // dmsfilemanager instance ID cache
    property string _dfmId: ""

    minWidth: 280
    minHeight: 500
    widgetWidth: getData("widgetWidth", 298)
    widgetHeight: getData("widgetHeight", 522)

    readonly property color accentColor: getData("accentColor", "#7C3AED")
    readonly property color accent2Color: getData("accent2Color", "#EC4899")
    readonly property real bgOpacity: getData("bgOpacity", 0.0)
    readonly property bool showClock: getData("showClock", true)
    readonly property bool showNetwork: getData("showNetwork", true)
    readonly property bool showWeather: getData("showWeather", true)
    readonly property bool showMusic: getData("showMusic", true)
    readonly property bool showStorage: getData("showStorage", true)
    readonly property string defaultView: getData("defaultView", "conky")
    readonly property real particleOpacity: getData("particleOpacity", 1.0)
    readonly property string particleStyle: getData("particleStyle", "stars")
    readonly property int particleCount: getData("particleCount", 150)
    readonly property real particleSize: getData("particleSize", 8.0)

    readonly property color bg: Theme.withAlpha("#0a0a0f", bgOpacity)
    readonly property color fg: "#f0f0f0"
    readonly property color dim: "#aaaaaa"

    // Ring gauge colors
    readonly property color ringBgColor: getData("ringBgColor", "#94A3B8")
    readonly property color cpuGaugeColor: getData("cpuGaugeColor", "#EA580C")
    readonly property color memGaugeColor: getData("memGaugeColor", "#EAB308")
    readonly property color batteryGaugeColor: getData("batteryGaugeColor", "#22C55E")
    readonly property color batteryAcGaugeColor: getData("batteryAcGaugeColor", "#22C55E")
    readonly property color tempGaugeColor: getData("tempGaugeColor", "#EF4444")
    readonly property color storageLabelColor: getData("storageLabelColor", "#f0f0f0")
    readonly property color storageRootColor: getData("storageRootColor", "#f0f0f0")
    readonly property color storageHomeColor: getData("storageHomeColor", "#f0f0f0")

    // HardWare / CPU / GPU label colors
    readonly property color hardwareLabelColor: getData("hardwareLabelColor", "#f0f0f0")
    readonly property color hardwareCpuLabelColor: getData("hardwareCpuLabelColor", "#f0f0f0")
    readonly property color hardwareGpuLabelColor: getData("hardwareGpuLabelColor", "#f0f0f0")

    // Clock / Date per-part colors
    readonly property color clockHourColor: getData("clockHourColor", "#8B5CF6")
    readonly property color clockMinuteColor: getData("clockMinuteColor", "#F97316")
    readonly property color clockSecondColor: getData("clockSecondColor", "#EC4899")
    readonly property color clockColonColor: getData("clockColonColor", "#3B82F6")
    readonly property color dateWeekdayColor: getData("dateWeekdayColor", "#EAB308")
    readonly property color dateDayColor: getData("dateDayColor", "#06B6D4")
    readonly property color dateMonthColor: getData("dateMonthColor", "#EC4899")

    readonly property int leftX: 14
    readonly property int rightX: 172
    readonly property int yBase: 0

    readonly property var activeModules: ["cpu", "memory", "network", "disk", "diskmounts", "system"]

    // ── Plugin I18n ──────────────────────────────────────────────────────────
    // Translation data embedded in QML (reliable, no FileView/JSON loading issues)
    property var _i18nData: ({
        "zh_CN": {
            "Wind": "风速", "Humidity": "湿度", "Network": "网络",
            "Down": "下载", "Up": "上传", "Storage": "存储",
            "Root": "系统", "Home": "家目录", "HardWare": "硬件",
            "CPU": "CPU", "GPU": "GPU",
            "Detecting": "检测中", "Offline": "离线", "Playing": "播放中"
        },
        "en": {
            "Wind": "Wind", "Humidity": "Humidity", "Network": "Network",
            "Down": "Down", "Up": "Up", "Storage": "Storage",
            "Root": "Root", "Home": "Home", "HardWare": "HardWare",
            "CPU": "CPU", "GPU": "GPU",
            "Detecting": "Detecting", "Offline": "Offline", "Playing": "Playing"
        },
        "de": {
            "Wind": "Wind", "Humidity": "Luftfeuchtigkeit", "Network": "Netzwerk",
            "Down": "Download", "Up": "Upload", "Storage": "Speicher",
            "Root": "Root", "Home": "Home", "HardWare": "Hardware",
            "CPU": "CPU", "GPU": "GPU",
            "Detecting": "Erkennung", "Offline": "Offline", "Playing": "Wiedergabe"
        },
        "es": {
            "Wind": "Viento", "Humidity": "Humedad", "Network": "Red",
            "Down": "Descarga", "Up": "Subida", "Storage": "Almacenamiento",
            "Root": "Raíz", "Home": "Inicio", "HardWare": "HardWare",
            "CPU": "CPU", "GPU": "GPU",
            "Detecting": "Detectando", "Offline": "Desconectado", "Playing": "Reproduciendo"
        },
        "fr": {
            "Wind": "Vent", "Humidity": "Humidité", "Network": "Réseau",
            "Down": "Réception", "Up": "Envoi", "Storage": "Stockage",
            "Root": "Racine", "Home": "Accueil", "HardWare": "Matériel",
            "CPU": "CPU", "GPU": "GPU",
            "Detecting": "Détection", "Offline": "Hors ligne", "Playing": "En lecture"
        },
        "ja": {
            "Wind": "風", "Humidity": "湿度", "Network": "ネットワーク",
            "Down": "ダウンロード", "Up": "アップロード", "Storage": "ストレージ",
            "Root": "ルート", "Home": "ホーム", "HardWare": "ハードウェア",
            "CPU": "CPU", "GPU": "GPU",
            "Detecting": "検出中", "Offline": "オフライン", "Playing": "再生中"
        },
        "ko": {
            "Wind": "바람", "Humidity": "습도", "Network": "네트워크",
            "Down": "다운", "Up": "업", "Storage": "저장 공간",
            "Root": "루트", "Home": "홈", "HardWare": "하드웨어",
            "CPU": "CPU", "GPU": "GPU",
            "Detecting": "감지 중", "Offline": "오프라인", "Playing": "재생 중"
        },
        "ru": {
            "Wind": "Ветер", "Humidity": "Влажность", "Network": "Сеть",
            "Down": "Вход", "Up": "Выход", "Storage": "Диски",
            "Root": "Корень", "Home": "Дом", "HardWare": "Оборудование",
            "CPU": "CPU", "GPU": "GPU",
            "Detecting": "Обнаружение", "Offline": "Офлайн", "Playing": "Играет"
        },
        "vi": {
            "Wind": "Gió", "Humidity": "Độ ẩm", "Network": "Mạng",
            "Down": "Tải xuống", "Up": "Tải lên", "Storage": "Lưu trữ",
            "Root": "Gốc", "Home": "Trang chủ", "HardWare": "Phần cứng",
            "CPU": "CPU", "GPU": "GPU",
            "Detecting": "Đang phát hiện", "Offline": "Ngoại tuyến", "Playing": "Đang phát"
        }
    })

    property string pluginLanguage: getData("pluginLanguage", "en")
    onPluginLanguageChanged: _applyPluginLanguage(pluginLanguage)
    readonly property var dateLocale: pluginLanguage === "zh_CN" ? Qt.locale("zh_CN")
        : pluginLanguage === "en" ? Qt.locale("en_US")
        : Qt.locale()
    property var _pluginFlatTranslations: ({})
    property bool _pluginI18nReady: false
    // Toggled to force re-evaluation of all i18n bindings on ConkyContent
    property int _i18nToken: 0

    // Poll pluginData for language changes (settings panel writes via savePluginData)
    Timer {
        id: languageSyncTimer
        interval: 800
        repeat: true
        running: true
        onTriggered: {
            var lang = root.getData("pluginLanguage", "system")
            // Also check the SettingsData store (where ConkySettings.saveAndPersist writes)
            if (typeof SettingsData !== "undefined") {
                try {
                    var sl = typeof pluginService !== "undefined" && pluginService
                        ? pluginService.loadPluginData(root.pluginId, "pluginLanguage", "system")
                        : SettingsData.getPluginSetting ? SettingsData.getPluginSetting(root.pluginId, "pluginLanguage", "system") : null
                    if (sl != null && sl !== "system") lang = sl
                } catch(e) {}
            }
            if (lang !== root.pluginLanguage)
                root.pluginLanguage = lang
        }
    }

    // Apply translations immediately (synchronous, no async FileView loading)
    function _applyPluginLanguage(locale) {
        if (locale === "System Default" || locale === "") locale = "system"
        if (!locale) return
        var map = locale === "system" ? _i18nData["en"] : _i18nData[locale]
        if (!map) map = _i18nData["en"]
        root._pluginFlatTranslations = map
        root._pluginI18nReady = true
        root._i18nToken++
        // Publish to plugin data so ConkySettings can read it
        if (typeof pluginService !== "undefined" && pluginService) {
            try {
                pluginService.savePluginData(root.pluginId, "i18nMap", map)
                pluginService.savePluginData(root.pluginId, "i18nToken", Date.now())
            } catch(e) {}
        }
    }

    // i18n lookup — call from ConkyContent via host.i18n("key")
    function i18n(term, context) {
        if (_i18nToken < 0) {}
        if (_pluginI18nReady && _pluginFlatTranslations[term] !== undefined)
            return _pluginFlatTranslations[term]
        return I18n.tr(term, context)
    }

    // ── Exposed translated properties (for reliable binding re-evaluation) ──
    readonly property string _i18nWind:    { _i18nToken; return _pluginFlatTranslations["Wind"]    || I18n.tr("Wind") }
    readonly property string _i18nHumidity:{ _i18nToken; return _pluginFlatTranslations["Humidity"]|| I18n.tr("Humidity") }
    readonly property string _i18nNetwork: { _i18nToken; return _pluginFlatTranslations["Network"] || I18n.tr("Network") }
    readonly property string _i18nDown:    { _i18nToken; return _pluginFlatTranslations["Down"]    || I18n.tr("Down") }
    readonly property string _i18nUp:      { _i18nToken; return _pluginFlatTranslations["Up"]      || I18n.tr("Up") }
    readonly property string _i18nStorage: { _i18nToken; return _pluginFlatTranslations["Storage"] || I18n.tr("Storage") }
    readonly property string _i18nRoot:    { _i18nToken; return _pluginFlatTranslations["Root"]    || I18n.tr("Root") }
    readonly property string _i18nHome:    { _i18nToken; return _pluginFlatTranslations["Home"]    || I18n.tr("Home") }
    readonly property string _i18nHardWare:{ _i18nToken; return _pluginFlatTranslations["HardWare"]|| I18n.tr("HardWare") }
    readonly property string _i18nCPU:     { _i18nToken; return _pluginFlatTranslations["CPU"]     || I18n.tr("CPU") }
    readonly property string _i18nGPU:     { _i18nToken; return _pluginFlatTranslations["GPU"]     || I18n.tr("GPU") }
    readonly property string _i18nDetecting:{_i18nToken; return _pluginFlatTranslations["Detecting"]|| I18n.tr("Detecting") }
    readonly property string _i18nOffline: { _i18nToken; return _pluginFlatTranslations["Offline"] || I18n.tr("Offline") }
    readonly property string _i18nPlaying: { _i18nToken; return _pluginFlatTranslations["Playing"] || I18n.tr("Playing") }

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
    property bool _mouseInWidget: false
    Timer {
        id: hoverThrottle
        interval: 80; running: root._mouseInWidget; repeat: true
        onTriggered: { root.hoverMouseX = root._rawMouseX; root.hoverMouseY = root._rawMouseY }
    }

    // --- App Launcher properties ---
    property string appSearchQuery: ""
    property bool appEditMode: false
    readonly property real appSize: getData("appSize", 76)
    readonly property string appViewMode: getData("viewMode", "grid")
    readonly property bool appShowHeader: getData("showHeader", false)
    readonly property bool showLauncherParticles: getData("showLauncherParticles", true)
    readonly property real appLauncherBgOpacity: (getData("backgroundOpacity", 0)) / 100
    readonly property real appIconSize: Math.max(28, Math.round(appSize * 0.58))
    property var addedApps: getData("addedApps", [])

    readonly property bool hasActivePlayer: MprisController.activePlayer !== null && MprisController.activePlayer !== undefined
    property int musicTick: 0

    readonly property string musicElapsed: {
        var p = MprisController.activePlayer
        musicTick // force re-evaluation every second
        if (!p || !p.isPlaying || p.position < 0) return ""
        var s = Math.floor(p.position)
        return Math.floor(s/60) + ":" + String(s%60).padStart(2,'0')
    }

    property string cpuModel: ""
    property string gpuModel: ""
    property color cpuInfoColor: "#f0f0f0"
    property color gpuInfoColor: "#f0f0f0"
    property color hoverHighlightColor: "#7C3AED"
    property color blobColor: "#7C3AED"
    property string _lastTrackId: ""

    function refreshBlobColor() {
        // Generate color from track title hash (same song = same color)
        var ap = MprisController.activePlayer
        var seed = ""
        if (ap && ap.metadata) {
            seed = ap.metadata["xesam:album"] || ap.metadata["xesam:title"] || ""
        }
        if (!seed) { root.blobColor = randomVibrantColor(); return }
        var hash = 0
        for (var i = 0; i < seed.length; i++) { hash = ((hash << 5) - hash) + seed.charCodeAt(i); hash |= 0 }
        var h = Math.abs(hash % 360) / 360
        var s = 0.65 + Math.abs(hash % 30) / 100
        var l = 0.55 + Math.abs(hash % 20) / 100
        root.blobColor = Qt.hsla(h, s, l, 1.0)
    }

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
            if (m[i].mount === "/") { c.sysPct = parseFloat(m[i].percent) / 100; c.sysInfo = m[i].percent + "(" + m[i].size + ")" }
            else if (m[i].mount === "/home") { c.homePct = parseFloat(m[i].percent) / 100; c.homeInfo = m[i].percent + "(" + m[i].size + ")" }
            if (c.sysPct > 0 && c.homePct > 0) break
        }
        // Fallback: no separate /home mount → reuse root data
        if (c.homePct === 0 && c.sysPct > 0) { c.homePct = c.sysPct; c.homeInfo = c.sysInfo }
        root.diskCache = c
    }

    property bool _wasPlaying: false
    property int musicResetTick: 0

    Timer {
        id: updateTimer
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            if (!root.showMusic) return
            var playing = hasActivePlayer && MprisController.activePlayer && MprisController.activePlayer.isPlaying
            var conkyVisible = (root.defaultView === "apps") ? root.mouseHovered : !root.mouseHovered

            // Detect track change and refresh blob color
            var ap = MprisController.activePlayer
            var trackTitle = ""
            if (ap && ap.metadata) {
                trackTitle = (ap.metadata["xesam:title"] || "")
            }
            if (_lastTrackId !== trackTitle) {
                _lastTrackId = trackTitle
                if (playing && trackTitle !== "") refreshBlobColor()
            }

            if (showMusic && playing && conkyVisible) {
                musicTick++
            }
            // Regenerate CPU/GPU colors when transitioning from playing → paused/stopped
            if (_wasPlaying && !playing) {
                root.cpuInfoColor = randomVibrantColor()
                root.gpuInfoColor = randomVibrantColor()
                root.blobColor = randomVibrantColor()
                musicResetTick++
            }
            _wasPlaying = playing
        }
    }

    Timer { id: diskTimer; interval: 60000; running: true; repeat: true; onTriggered: root.refreshDiskCache() }
    Timer { interval: 1500; running: true; repeat: false; onTriggered: root.refreshDiskCache() }


    Component.onCompleted: {
        DgopService.addRef(activeModules)
        WeatherService.addRef()

        // Initial i18n load — pull language from correct store
        var initialLang = "system"
        if (typeof pluginService !== "undefined" && pluginService)
            initialLang = pluginService.loadPluginData(root.pluginId, "pluginLanguage", "system")
        else if (typeof SettingsData !== "undefined" && SettingsData.getPluginSetting)
            initialLang = SettingsData.getPluginSetting(root.pluginId, "pluginLanguage", "system")
        root.pluginLanguage = initialLang
        root._applyPluginLanguage(initialLang)

        // Random colors for CPU / GPU info + hover highlight
        root.cpuInfoColor = randomVibrantColor()
        root.gpuInfoColor = randomVibrantColor()
        root.hoverHighlightColor = randomVibrantColor()
        root.blobColor = randomVibrantColor()

        // Detect CPU model
        root._cpuProc = Qt.createQmlObject(`
            import Quickshell.Io
            Process {
                command: ["sh", "-c", "/usr/bin/grep -m1 'model name' /proc/cpuinfo | sed 's/.*: //; s/(R)//g; s/(TM)//g; s/ CPU//g; s/[0-9]*th Gen //; s/Core //; s/  */ /g'"]
                running: true
                stdout: StdioCollector {
                    onStreamFinished: { root.cpuModel = text.trim(); root._cpuProc.destroy() }
                }
            }`, root)

        // GPU detection handled by gpuDetect Process below
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
        root.setData("addedApps", newList)
        SettingsData.setPluginSetting(pluginId, "addedApps", newList)
        SettingsData.savePluginSettings()
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
    // CONKY VIEW
    // ============================================
    ConkyContent {
        visible: !launcherContent._keepVisible && (root.defaultView === "apps" ? root.mouseHovered : !root.mouseHovered)
        anchors.fill: parent
        host: root
    }

    // ============================================
    // APP LAUNCHER VIEW
    // ============================================
    AppLauncherContent {
        id: launcherContent
        visible: (root.defaultView === "apps" ? !root.mouseHovered : root.mouseHovered) || launcherContent._keepVisible
        anchors.fill: parent
        host: root
    }

    // --- Global hover (widget switching + position for delegate effects) ---
    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        onContainsMouseChanged: {
            root._mouseInWidget = containsMouse
            if (!containsMouse && !launcherContent._keepVisible) root.mouseHovered = false
        }
        onPositionChanged: function(mouse) {
            root._rawMouseX = mouse.x
            root._rawMouseY = mouse.y
            if (launcherContent._keepVisible) {
                // Dialog is open — keep AppLauncher active
                root.mouseHovered = (root.defaultView !== "apps")
            } else if (root.defaultView === "apps") {
                // Apps is default — Conky only shows in the exclusion zone (bottom area)
                root.mouseHovered = containsMouse && isInExclusionZone(mouse.x, mouse.y)
            } else if (root.mouseHovered) {
                // Already in AppLauncher (conky default) — stay there even in exclusion zone
                root.mouseHovered = containsMouse
            } else {
                // In Conky (conky default) — switch to AppLauncher outside exclusion zone
                root.mouseHovered = containsMouse && !isInExclusionZone(mouse.x, mouse.y)
            }
        }
    }

    // GPU detection — declarative Process with 3s timeout
    Process {
        id: gpuProc
        command: ["sh", "-c", "lspci 2>/dev/null | grep -i vga | head -1"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                gpuTimeout.stop()
                var t = text.trim()
                if (t) {
                    var m = t.match(/\[([^\]]+)\]/)
                    if (m) {
                        var v = ""
                        if (t.indexOf("NVIDIA") >= 0) v = "NVIDIA "
                        else if (t.indexOf("AMD") >= 0) v = "AMD "
                        else if (t.indexOf("Intel") >= 0) v = "Intel "
                        root.gpuModel = v + m[1].replace("GeForce ", "").replace("Radeon ", "")
                    }
                }
                if (root.gpuModel === "") root.gpuModel = "Unknown"
                gpuProc.destroy()
            }
        }
    }

    Timer {
        id: gpuTimeout
        interval: 3000
        running: true
        repeat: false
        onTriggered: {
            if (root.gpuModel === "" && gpuProc) {
                root.gpuModel = "Unknown"
                gpuProc.destroy()
            }
        }
    }

    readonly property string musicPlayerPath: getData("musicPlayerPath", "/usr/local/bin/splayer")
    readonly property bool showRotatingAlbum: getData("showRotatingAlbum", true)

    function triggerSplayerOrResume() {
        var p = MprisController.activePlayer
        if (p) {
            p.togglePlaying()
        } else {
            Quickshell.execDetached(["sh", "-c", musicPlayerPath])
        }
    }

}

import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins
import "../common"

Item {
    id: content
    property Item host

    // ── Plugin I18n (language switching, following dmsfilemanager pattern) ──
    property string _launcherLang: host && host.pluginLanguage ? host.pluginLanguage : "system"
    property var _launcherI18nMap: ({})
    property bool _launcherI18nReady: false

    function _tr(key) {
        if (_launcherI18nMap && _launcherI18nMap[key] !== undefined)
            return _launcherI18nMap[key];
        return I18n.tr(key);
    }

    function _applyLauncherLanguage(locale) {
        if (locale === "System Default" || locale === "") locale = "system";
        if (!locale) { _launcherI18nMap = {}; return; }
        if (locale === "system") {
            var sys = Qt.locale().name;
            var parts = sys.split("_");
            sys = parts.length > 0 ? parts[0] : "en";
            launcherI18nLoader.path = Qt.resolvedUrl("../translations/i18n/" + sys + ".json");
        } else {
            launcherI18nLoader.path = Qt.resolvedUrl("../translations/i18n/" + locale + ".json");
        }
    }

    // Language sync timer — polls pluginLanguage from settings
    Timer {
        id: launcherLangSyncTimer
        interval: 800
        repeat: true
        running: true
        onTriggered: {
            if (!content.host || !content.host.pluginService) return;
            var lang = content.host.pluginService.loadPluginData(content.host.pluginId, "pluginLanguage", "system");
            if (lang !== content._launcherLang) {
                content._launcherLang = lang;
                content._applyLauncherLanguage(lang);
            }
        }
    }

    Component.onCompleted: {
        _applyLauncherLanguage(_launcherLang);
        cleanupMissingApps();
    }

    // ── Stale app detection: AppImage file deleted, or command no longer resolvable ──
    // Returns a shell check that succeeds when the app exists; "" = unverifiable → treat as existing
    function buildExistsCheck(exec) {
        var m = (exec || "").match(/'(.+\.appimage)'/i);
        if (m && m[1]) return "[ -e '" + m[1].replace(/'/g, "'\\''") + "' ]";
        var token = (exec || "").trim().split(/\s+/)[0] || "";
        if (token === "") return "";
        if (token.charAt(0) === "/") return "[ -e '" + token.replace(/'/g, "'\\''") + "' ]";
        if (!/^[A-Za-z0-9_.+-]+$/.test(token)) return "";
        return "command -v '" + token + "' >/dev/null 2>&1";
    }

    // Batch check all added apps; removes entries whose target no longer exists
    function cleanupMissingApps() {
        if (!host || !host.addedApps || host.addedApps.length === 0) return;
        var cmds = [];
        for (var i = 0; i < host.addedApps.length; i++) {
            var chk = buildExistsCheck(host.addedApps[i].exec);
            if (chk !== "") cmds.push(chk + " || echo " + i);
        }
        if (cmds.length === 0) return;
        appExistsProc.command = ["sh", "-c", cmds.join("; ")];
        appExistsProc.running = true;
    }

    function handleMissingApps(outText) {
        var lines = String(outText).trim().split("\n");
        var missing = {};
        for (var i = 0; i < lines.length; i++) {
            var idx = parseInt(lines[i].trim(), 10);
            if (!isNaN(idx)) missing[idx] = true;
        }
        var count = 0;
        for (var k in missing) count++;
        if (count === 0) return;
        var kept = [];
        var removed = false;
        var apps = host.addedApps;
        for (var j = 0; j < apps.length; j++) {
            if (missing[j]) { removed = true; continue; }
            kept.push(apps[j]);
        }
        if (removed) {
            host.saveAddedApps(kept);
            addAppDialog.rebuildAddedSet();
        }
    }

    // Launch with existence check: target gone → auto-remove instead of launching
    property var _launchQueue: []
    function launchAppChecked(name, exec) {
        var chk = buildExistsCheck(exec);
        if (chk === "") {
            Quickshell.execDetached(["sh", "-c", host.cleanExec(exec)]);
            return;
        }
        // Single verify process: queue rapid clicks so each check pairs with its own target
        if (appLaunchVerifyProc.running) { _launchQueue.push({ name: name, exec: exec }); return }
        _startLaunchVerify(name, exec);
    }

    function _startLaunchVerify(name, exec) {
        appLaunchVerifyProc.pendingName = name;
        appLaunchVerifyProc.pendingExec = exec;
        appLaunchVerifyProc.command = ["sh", "-c", buildExistsCheck(exec) + " || echo __GONE__"];
        appLaunchVerifyProc.running = true;
    }

    function handleLaunchVerify(outText) {
        if (String(outText).trim() === "__GONE__") {
            host.removeApp(appLaunchVerifyProc.pendingName);
            toastRect.msg = "✖ " + appLaunchVerifyProc.pendingName;
            toastTimer.restart();
        } else {
            Quickshell.execDetached(["sh", "-c", host.cleanExec(appLaunchVerifyProc.pendingExec)]);
        }
        if (_launchQueue.length > 0) {
            var nx = _launchQueue.shift()
            _startLaunchVerify(nx.name, nx.exec)
        }
    }

    Process {
        id: appExistsProc
        command: []
        stdout: StdioCollector {
            onStreamFinished: content.handleMissingApps(text)
        }
    }

    Process {
        id: appLaunchVerifyProc
        property string pendingName: ""
        property string pendingExec: ""
        command: []
        stdout: StdioCollector {
            onStreamFinished: content.handleLaunchVerify(text)
        }
    }

    // Async FileView to load JSON translation files from translations/i18n/
    FileView {
        id: launcherI18nLoader
        onLoaded: {
            try {
                content._launcherI18nMap = JSON.parse(text());
                content._launcherI18nReady = true;
                console.info("Launcher I18n: loaded translations for", content._launcherLang);
            } catch (e) {
                console.warn("Launcher I18n: error parsing:", e);
            }
        }
        onLoadFailed: error => {
            console.warn("Launcher I18n: failed to load:", error);
            if (content._launcherLang !== "en") {
                launcherI18nLoader.path = Qt.resolvedUrl("../translations/i18n/en.json");
            }
        }
    }

    // Language model for the language selector
    readonly property var _launcherLangModel: [
        { label: "System Default", code: "system" },
        { label: "中文", code: "zh_CN" },
        { label: "English", code: "en" },
        { label: "Deutsch", code: "de" },
        { label: "Español", code: "es" },
        { label: "Français", code: "fr" },
        { label: "日本語", code: "ja" },
        { label: "한국어", code: "ko" },
        { label: "Русский", code: "ru" },
        { label: "Tiếng Việt", code: "vi" }
    ]

    // Reusable header tool button
    component ToolButton: MouseArea {
        id: btn
        width: 24; height: 24; hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        anchors.verticalCenter: parent.verticalCenter
        property string iconName: ""
        property alias hovered: btn.containsMouse

        Rectangle {
            anchors.fill: parent
            radius: Math.round(Theme.cornerRadius / 2)
            color: btn.containsMouse ? Theme.withAlpha(host.fgColor, 0.08) : Theme.withAlpha(host.fgColor, 0.03)
            border.color: Theme.withAlpha(Theme.outline, 0.15); border.width: 1
            DankIcon {
                anchors.centerIn: parent
                name: btn.iconName; size: 14; color: host.fgColor
                opacity: btn.containsMouse ? 1.0 : 0.7
            }
        }
    }

    // Reusable drag grip handle
    component DragGrip: Item {
        z: 10; width: 22; height: parent.height
        property alias dragMouseArea: gripMA
        property real leftMargin: 0
        anchors { left: parent.left; leftMargin: leftMargin; verticalCenter: parent.verticalCenter }
        visible: host.appSearchQuery === ""
        DankIcon {
            anchors.centerIn: parent
            name: "drag_indicator"; size: 14; color: host.fgColor
            opacity: gripMA.containsMouse || gripMA.drag.active ? 0.6 : 0.1
        }
        MouseArea {
            id: gripMA
            anchors.fill: parent; hoverEnabled: true; preventStealing: true
            cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor
        }
    }

    // Reusable "+" add button overlay
    component AddOverlay: MouseArea {
        anchors.fill: parent; z: 3; visible: appName === "__add__"
        cursorShape: Qt.PointingHandCursor
        onClicked: { clearSearch(); addAppDialog.openDialog("add") }
    }

    ListModel { id: filteredModel }

    function clearSearch() {
        searchField.text = ""
        host.appSearchQuery = ""
        searchContainer.expanded = false
    }

    function updateFilteredModel() {
        var search = host.appSearchQuery.toLowerCase().trim()
        if (search === "") {
            // Fast path: incremental sync with addedApps (no search filter)
            var target = host.addedApps
            var needCount = target.length + 1  // +1 for "+" button
            while (filteredModel.count > needCount) {
                filteredModel.remove(filteredModel.count - 1)
            }
            for (var i = 0; i < target.length; i++) {
                var app = target[i]
                if (i < filteredModel.count) {
                    var cur = filteredModel.get(i)
                    if (cur.appName !== app.name || cur.appIcon !== app.icon || cur.appExec !== app.exec) {
                        filteredModel.set(i, { appName: app.name, appIcon: app.icon, appExec: app.exec, appCategories: app.categories })
                    }
                } else {
                    filteredModel.append({ appName: app.name, appIcon: app.icon, appExec: app.exec, appCategories: app.categories })
                }
            }
            // Ensure "+" button at the end
            var addIdx = target.length
            if (addIdx < filteredModel.count) {
                filteredModel.set(addIdx, { appName: "__add__", appIcon: "", appExec: "", appCategories: "" })
            } else {
                filteredModel.append({ appName: "__add__", appIcon: "", appExec: "", appCategories: "" })
            }
        } else {
            // Slow path: full rebuild for search filtering
            filteredModel.clear()
            for (var i = 0; i < host.addedApps.length; i++) {
                var app = host.addedApps[i]
                if (app.name.toLowerCase().indexOf(search) !== -1 ||
                    (app.exec && app.exec.toLowerCase().indexOf(search) !== -1)) {
                    filteredModel.append({
                        appName: app.name,
                        appIcon: app.icon,
                        appExec: app.exec,
                        appCategories: app.categories
                    })
                }
            }
            // "+" button (only when no search filter active)
            if (host.addedApps.length > 0) {
                filteredModel.append({ appName: "__add__", appIcon: "", appExec: "", appCategories: "" })
            }
        }
    }

    property string _sw: host.appSearchQuery
    on_SwChanged: searchDebounce.restart()

    Timer {
        id: searchDebounce
        interval: 150
        onTriggered: updateFilteredModel()
    }

    readonly property bool _keepVisible: addAppDialog.opened || appSettingsDialog.opened
    // True while a native folder/color picker window is open (blocks hover-leave auto close)
    property bool _fileDialogOpen: false

    function closeOpenDialogs() {
        // Skip while a file/folder picker window is open — interacting with it moves the
        // mouse out of the widget, which would otherwise close the Manage dialog behind it
        if (_fileDialogOpen) return
        if (appSettingsDialog.opened) appSettingsDialog.close()
        if (addAppDialog.opened) addAppDialog.close()
    }

    property bool _hw: host.mouseHovered
    on_HwChanged: {
        if (!host.mouseHovered) {
            if (!addAppDialog.opened && !appSettingsDialog.opened) {
                clearSearch()
            }
        } else {
            content.forceActiveFocus()
        }
    }

    property var _aw: host.addedApps
    on_AwChanged: {
        updateFilteredModel()
        addAppDialog.rebuildAddedSet()
    }

    // Calculate which app is hovered (JS-based, works with Qt 5 global hover)
    function gridHoveredIndex() {
        if (!launcherContainer.visible || !appsGrid.visible || filteredModel.count === 0) return -1
        var pos = appsGrid.mapFromItem(host, host.hoverMouseX, host.hoverMouseY)
        if (pos.x < 0 || pos.y < 0 || pos.x >= appsGrid.width || pos.y >= appsGrid.height) return -1
        var cols = Math.max(2, Math.floor(appsGrid.width / host.appSize))
        var cellW = Math.floor(appsGrid.width / cols)
        var col = Math.floor(pos.x / cellW)
        var row = Math.floor((pos.y + appsGrid.contentY) / cellW)
        var idx = row * cols + col
        return (idx >= 0 && idx < filteredModel.count) ? idx : -1
    }
    function listHoveredIndex() {
        if (!launcherContainer.visible || !appsList.visible || filteredModel.count === 0) return -1
        var pos = appsList.mapFromItem(host, host.hoverMouseX, host.hoverMouseY)
        if (pos.y < 0 || pos.y >= appsList.height) return -1
        var itemH = Math.round(36 * (host.appSize / 88.0)) + appsList.spacing
        var idx = Math.floor((pos.y + appsList.contentY) / itemH)
        return (idx >= 0 && idx < filteredModel.count) ? idx : -1
    }
    function compactHoveredIndex() {
        if (!launcherContainer.visible || !appsCompact.visible || filteredModel.count === 0) return -1
        var pos = appsCompact.mapFromItem(host, host.hoverMouseX, host.hoverMouseY)
        if (pos.x < 0 || pos.y < 0 || pos.x >= appsCompact.width || pos.y >= appsCompact.height) return -1
        var cols = Math.max(2, Math.floor(appsCompact.width / 130))
        var cellW = Math.floor(appsCompact.width / cols)
        var cellH = Math.round(30 * (host.appSize / 88.0))
        var col = Math.floor(pos.x / cellW)
        var row = Math.floor((pos.y + appsCompact.contentY) / cellH)
        var idx = row * cols + col
        return (idx >= 0 && idx < filteredModel.count) ? idx : -1
    }

    readonly property int hoveredIndex: {
        if (!launcherContainer.visible) return -1
        switch (host.appViewMode) {
            case "grid": return gridHoveredIndex()
            case "list": return listHoveredIndex()
            case "compact": return compactHoveredIndex()
            default: return -1
        }
    }

    property color hoverColor: host.accentColor
    property int _hi: hoveredIndex
    on_HiChanged: {
        if (hoveredIndex >= 0) {
            var h = Math.random()
            var s = 0.7 + Math.random() * 0.3
            var l = 0.55 + Math.random() * 0.25
            hoverColor = Qt.hsla(h, s, l, 1.0)
            host.hoverHighlightColor = hoverColor
        }
    }

    // ============================================
    // APP LAUNCHER VIEW (visible when mouse hovers)
    // ============================================
    Rectangle {
        id: launcherContainer
        visible: (host.defaultView === "apps" ? !host.mouseHovered : host.mouseHovered) || content._keepVisible
        anchors.fill: parent
        color: Theme.withAlpha(host.bgColor !== "" ? Qt.color(host.bgColor) : Theme.surfaceContainer, host.appLauncherBgOpacity)
        radius: Theme.cornerRadius
        border.color: host.appEditMode ? Theme.primary : Theme.withAlpha(Theme.outline, 0.15)
        border.width: host.appEditMode ? 2 : 1
        clip: true

        // Ambient particles
        ParticleBackground {
            running: launcherContainer.visible && host.showLauncherParticles
            particleOpacity: host.showLauncherParticles ? host.particleOpacity : 0
            particleCount: host.particleCount
            particleSize: host.particleSize
            particleStyle: host.particleStyle
        }

        Column {
            anchors.fill: parent
            anchors.margins: Theme.spacingM
            spacing: Theme.spacingS

            // Header
            Item {
                id: headerBar
                width: parent.width
                height: 24

                StyledText {
                    text: content._tr("Applications")
                    font.bold: true
                    font.pixelSize: Theme.fontSizeMedium
                    color: host.fgColor
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    visible: host.appShowHeader && !searchContainer.expanded
                }

                // Centered search bar when header is off
                Rectangle {
                    id: headerOffSearch
                    width: parent.width - 20; height: 28; radius: 14
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    visible: !host.appShowHeader
                    color: Theme.withAlpha(host.fgColor, 0.04)
                    border.color: searchField.activeFocus ? Theme.primary : Theme.withAlpha(Theme.outline, 0.1)
                    border.width: 1

                    DankIcon {
                        id: headerOffSearchIcon
                        name: "search"; size: 14; color: host.fgColor; opacity: 0.4
                        anchors.left: parent.left; anchors.leftMargin: 10; anchors.verticalCenter: parent.verticalCenter
                    }
                    TextInput {
                        id: headerOffSearchField
                        anchors.left: headerOffSearchIcon.right; anchors.leftMargin: 6
                        anchors.right: parent.right; anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        font.pixelSize: Theme.fontSizeSmall - 1; color: host.fgColor; selectByMouse: true
                        onTextChanged: host.appSearchQuery = text
                        Text {
                            text: content._tr("Search...")
                            font.pixelSize: Theme.fontSizeSmall - 1; color: host.fgColor; opacity: 0.35
                            visible: headerOffSearchField.text === "" && !headerOffSearchField.activeFocus
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }

                // Shared hover timer for header-off buttons
                Timer {
                    interval: 100; running: !host.appShowHeader && launcherContainer.visible; repeat: true
                    onTriggered: {
                        var p1 = addAppBtn.mapFromItem(host, host.hoverMouseX, host.hoverMouseY)
                        addAppBtn.hovered = p1.x >= 0 && p1.x <= 24 && p1.y >= 0 && p1.y <= 24
                        var p2 = settingsBtn.mapFromItem(host, host.hoverMouseX, host.hoverMouseY)
                        settingsBtn.hovered = p2.x >= 0 && p2.x <= 24 && p2.y >= 0 && p2.y <= 24
                    }
                }

                // Add app button (always visible when header is off)
                Item {
                    id: addAppBtn
                    width: 24; height: 24
                    anchors.right: settingsBtn.left; anchors.rightMargin: 4
                    anchors.verticalCenter: parent.verticalCenter
                    property bool hovered: false

                    Rectangle {
                        anchors.fill: parent
                        radius: Math.round(Theme.cornerRadius / 2)
                        color: addAppBtn.hovered ? Theme.withAlpha(Theme.primary, 0.15) : Theme.withAlpha(Theme.primary, 0.05)
                        border.color: Theme.withAlpha(host.accentColor, addAppBtn.hovered ? 0.4 : 0.15); border.width: 1
                        opacity: host.appShowHeader ? 0.0 : (addAppBtn.hovered ? 0.9 : 0.4)
                        Behavior on opacity { NumberAnimation { duration: 200 } }

                        DankIcon {
                            anchors.centerIn: parent
                            name: "add"; size: 14
                            color: addAppBtn.hovered ? Theme.primary : host.fgColor
                            opacity: addAppBtn.hovered ? 1.0 : 0.7
                        }
                    }

                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: { clearSearch(); addAppDialog.openDialog("add") }
                    }
                }

                // Settings icon – always visible, detached from the toolbar Row
                Item {
                    id: settingsBtn
                    width: 24; height: 24
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    property bool hovered: false

                    Rectangle {
                        id: settingsBg
                        anchors.fill: parent
                        radius: Math.round(Theme.cornerRadius / 2)
                        color: settingsBtn.hovered ? Theme.withAlpha(host.fgColor, 0.08) : Theme.withAlpha(host.fgColor, 0.03)
                        border.color: Theme.withAlpha(Theme.outline, 0.15); border.width: 1
                        opacity: host.appShowHeader ? 1.0 : (settingsBtn.hovered ? 0.8 : 0.0)
                        Behavior on opacity { NumberAnimation { duration: 200 } }

                        DankIcon {
                            anchors.centerIn: parent
                            name: "settings"; size: 14; color: host.fgColor
                            opacity: settingsBtn.hovered ? 1.0 : 0.7
                        }
                    }

                    MouseArea {
                        id: settingsHitArea
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            clearSearch()
                            appSettingsDialog.open()
                        }
                    }
                }

                Row {
                    anchors.right: settingsBtn.left
                    anchors.rightMargin: settingsBtn.visible ? Theme.spacingS : 0
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.spacingS
                    height: parent.height

                    Rectangle {
                        id: searchContainer
                        visible: host.appShowHeader
                        property bool expanded: false
                        width: expanded ? Math.min(160, parent.parent.width - 110) : 24
                        height: 24
                        radius: 12
                        color: expanded ? Theme.withAlpha(host.fgColor, 0.04) : "transparent"
                        border.color: expanded ? Theme.withAlpha(Theme.outline, 0.15) : "transparent"
                        border.width: expanded ? 1 : 0
                        clip: true
                        anchors.verticalCenter: parent.verticalCenter

                        Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }

                        MouseArea {
                            anchors.fill: parent
                            visible: !searchContainer.expanded
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { searchContainer.expanded = true; searchField.forceActiveFocus() }
                        }

                        DankIcon {
                            id: searchIcon
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: searchContainer.expanded ? 4 : (searchContainer.width - size) / 2
                            name: "search"; size: 14; color: host.fgColor
                            opacity: searchField.activeFocus ? 1.0 : (searchContainer.expanded ? 0.6 : 0.7)
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                        }

                        TextInput {
                            id: searchField
                            anchors.left: searchIcon.right; anchors.leftMargin: 4
                            anchors.right: clearBtn.visible ? clearBtn.left : parent.right; anchors.rightMargin: 4
                            anchors.verticalCenter: parent.verticalCenter
                            font.pixelSize: Theme.fontSizeSmall - 1; color: host.fgColor; selectByMouse: true
                            visible: searchContainer.expanded
                            opacity: searchContainer.expanded ? 1.0 : 0.0
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                            onTextChanged: host.appSearchQuery = text
                            Text {
                                text: content._tr("Search...")
                                font.pixelSize: Theme.fontSizeSmall - 1; color: host.fgColor; opacity: 0.35
                                visible: searchField.text === "" && !searchField.activeFocus
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            id: clearBtn
                            width: 12; height: 12
                            anchors.right: parent.right; anchors.rightMargin: 4
                            anchors.verticalCenter: parent.verticalCenter
                            visible: searchContainer.expanded
                            cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                            onClicked: {
                                clearSearch()
                                searchField.focus = false
                            }
                            DankIcon {
                                anchors.centerIn: parent
                                name: "close"; size: 10; color: host.fgColor
                                opacity: clearBtn.containsMouse ? 0.9 : 0.5
                            }
                        }
                    }

                    ToolButton {
                        visible: host.appShowHeader
                        iconName: "add"
                        onClicked: {
                            clearSearch()
                            addAppDialog.openDialog("add")
                        }
                    }
                }

            }

            // Grid View
            GridView {
                id: appsGrid
                width: parent.width
                height: parent.height - 24 - Theme.spacingS * 2
                clip: true; boundsBehavior: Flickable.StopAtBounds
                visible: host.appViewMode === "grid"
                cellWidth: Math.floor(width / Math.max(2, Math.floor(width / host.appSize)))
                cellHeight: cellWidth
                model: filteredModel
                add: Transition { NumberAnimation { properties: "opacity,scale"; from: 0; to: 1.0; duration: 250; easing.type: Easing.OutBack } }
                remove: Transition { NumberAnimation { properties: "opacity,scale"; to: 0; duration: 150; easing.type: Easing.InQuad } }
                displaced: Transition {
                    NumberAnimation { property: "x"; duration: 200; easing.type: Easing.OutQuad }
                    NumberAnimation { property: "y"; duration: 200; easing.type: Easing.OutQuad }
                }
                delegate: Item {
                    id: gridDelegateItem
                    width: appsGrid.cellWidth; height: appsGrid.cellHeight

                    property int _dragIdx: -1

                    Drag.active: appCard.drag.active
                    Drag.source: gridDelegateItem
                    Drag.hotSpot.x: width / 2
                    Drag.hotSpot.y: height / 2

                    states: State {
                        when: appCard.drag.active
                        ParentChange { target: gridDelegateItem; parent: appsGrid.contentItem }
                    }

                    MouseArea {
                        id: appCard
                        anchors.fill: parent; anchors.margins: 4
                        hoverEnabled: true; cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.PointingHandCursor
                        drag.target: (host.appSearchQuery === "" && appName !== "__add__") ? gridDelegateItem : null
                        drag.axis: Drag.XAndYAxis
                        onPressed: _dragIdx = index
                        onPressAndHold: {
                            if (appName !== "__add__") {
                                host._deleteRevealedApp = appName
                                iconJumpAnim.start()
                            }
                        }
                        onClicked: {
                            if (drag.active) return
                            if (host._deleteRevealedApp !== "") {
                                host._deleteRevealedApp = ""
                                return
                            }
                            if (appName === "__add__") {
                                clearSearch(); addAppDialog.openDialog("add")
                            } else {
                                clickLaunchAnimation.start()
                                content.launchAppChecked(appName, appExec)
                            }
                        }
                        onReleased: {
                            if (drag.active) {
                                var cols = Math.max(2, Math.floor(appsGrid.width / host.appSize))
                                var toCol = Math.round(gridDelegateItem.x / appsGrid.cellWidth)
                                var toRow = Math.round(gridDelegateItem.y / appsGrid.cellHeight)
                                var toIdx = Math.max(0, Math.min(toRow * cols + toCol, filteredModel.count - 1))
                                if (toIdx !== _dragIdx) host.moveAppToIndex(_dragIdx, toIdx)
                            }
                        }

                        // Glow ring on hover
                        Rectangle {
                            width: Math.round(host.appIconSize * 1.85); height: width
                            anchors.centerIn: parent
                            radius: Math.round(Theme.cornerRadius)
                            color: appCard.containsMouse ? Theme.withAlpha(host.accentColor, 0.08) : "transparent"
                            scale: appCard.containsMouse ? 1.08 : 1.0
                            Behavior on color { ColorAnimation { duration: 200 } }
                            Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }
                        }

                        // Highlight card on hover
                        Rectangle {
                            anchors.fill: parent
                            radius: Math.round(Theme.cornerRadius / 2)
                            color: Theme.withAlpha(content.hoverColor, 0.18)
                            border.color: Theme.withAlpha(content.hoverColor, 0.4)
                            border.width: 1
                            opacity: (index === hoveredIndex) ? 1.0 : 0.0
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                        }

                        Rectangle {
                            id: containerRect
                            width: Math.round(host.appIconSize * 1.45); height: width
                            anchors.centerIn: parent
                            radius: Math.round(Theme.cornerRadius / 2)
                            color: appCard.containsMouse ? Theme.withAlpha(Theme.primary, 0.25) : Theme.withAlpha(Theme.primary, 0.12)
                            border.color: appCard.containsMouse ? Theme.primary : Theme.withAlpha(Theme.primary, 0.45)
                            border.width: appCard.containsMouse ? 2 : 1
                            Behavior on color { enabled: !clickLaunchAnimation.running; ColorAnimation { duration: 150 } }
                            Behavior on border.color { enabled: !clickLaunchAnimation.running; ColorAnimation { duration: 150 } }
                            Behavior on border.width { enabled: !clickLaunchAnimation.running; NumberAnimation { duration: 150 } }
                            SequentialAnimation {
                                id: clickLaunchAnimation
                                NumberAnimation { target: containerRect; property: "scale"; to: 0.88; duration: 60; easing.type: Easing.OutQuad }
                                ParallelAnimation {
                                    NumberAnimation { target: containerRect; property: "scale"; to: 1.15; duration: 180; easing.type: Easing.OutBack }
                                    ColorAnimation { target: containerRect; property: "color"; to: Theme.withAlpha(Theme.primary, 0.45); duration: 180 }
                                    ColorAnimation { target: containerRect; property: "border.color"; to: Theme.primary; duration: 180 }
                                }
                                ParallelAnimation {
                                    NumberAnimation { target: containerRect; property: "scale"; to: 1.0; duration: 200; easing.type: Easing.OutQuad }
                                    ColorAnimation { target: containerRect; property: "color"; to: appCard.containsMouse ? Theme.withAlpha(Theme.primary, 0.25) : Theme.withAlpha(Theme.primary, 0.12); duration: 200 }
                                    ColorAnimation { target: containerRect; property: "border.color"; to: appCard.containsMouse ? Theme.primary : Theme.withAlpha(Theme.primary, 0.45); duration: 200 }
                                }
                            }
                            Rectangle {
                                width: host.iconSize; height: width; radius: width / 2
                                anchors.centerIn: parent
                                color: appCard.containsMouse ? Theme.withAlpha(host.accentColor, 0.2) : Theme.withAlpha(host.accentColor, 0.1)
                                border.color: appCard.containsMouse ? Theme.withAlpha(host.accentColor, 0.5) : Theme.withAlpha(host.accentColor, 0.25)
                                border.width: 1.5
                                visible: appName === "__add__"
                                scale: appCard.containsMouse ? 1.15 : 1.0
                                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
                                DankIcon { anchors.centerIn: parent; name: "add"; size: host.iconSize * 0.45; color: host.accentColor }
                            }
                            AppIcon {
                                id: gridAppIcon
                                iconSize: host.appIconSize
                                iconSource: appIcon
                                fallbackColor: host.fgColor
                                showAppImageBadge: appName !== "__add__" && /\.appimage/i.test(appExec)
                                anchors.centerIn: parent
                                visible: appName !== "__add__"
                                scale: appCard.containsMouse ? 1.15 : 1.0
                                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
                                // Bounce jump when long-press reveals the delete button
                                transform: Translate { id: gridIconJump; y: 0 }
                                SequentialAnimation {
                                    id: iconJumpAnim
                                    NumberAnimation { target: gridIconJump; property: "y"; to: -8; duration: 110; easing.type: Easing.OutQuad }
                                    NumberAnimation { target: gridIconJump; property: "y"; to: 0; duration: 230; easing.type: Easing.OutBounce }
                                    NumberAnimation { target: gridIconJump; property: "y"; to: -4; duration: 90; easing.type: Easing.OutQuad }
                                    NumberAnimation { target: gridIconJump; property: "y"; to: 0; duration: 180; easing.type: Easing.OutBounce }
                                }
                            }
                            // Delete overlay on long-press (top-right corner)
                            Rectangle {
                                anchors.top: parent.top; anchors.topMargin: -4
                                anchors.right: parent.right; anchors.rightMargin: -4
                                width: 26; height: 26; radius: 13
                                color: Theme.withAlpha(Theme.error, 0.92)
                                visible: appName !== "__add__" && host._deleteRevealedApp === appName
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        host.removeApp(appName)
                                        host._deleteRevealedApp = ""
                                    }
                                }
                                DankIcon {
                                    anchors.centerIn: parent
                                    name: "delete"; size: 14; color: "#ffffff"
                                }
                            }
                        }
                    }

                    // App name tooltip - visible on hover (Grid View only)
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: -10
                        width: Math.min(tooltipText.implicitWidth + 10, parent.width - 4)
                        height: tooltipText.implicitHeight + 4
                        radius: 4
                        color: "transparent"
                        border.color: "transparent"
                        border.width: 0
                        visible: index === content.hoveredIndex && appName !== "__add__"
                        opacity: visible ? 1.0 : 0.0
                        Behavior on opacity { NumberAnimation { duration: 120 } }
                        z: 10

                        StyledText {
                            id: tooltipText
                            anchors.centerIn: parent
                            text: appName
                            font.pixelSize: 12
                            font.bold: true
color: host.fgColor
                            elide: Text.ElideRight
                            width: parent.width - 8
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                }
            }

            // List View
            ListView {
                id: appsList
                width: parent.width
                height: parent.height - 24 - Theme.spacingS * 2
                clip: true; boundsBehavior: Flickable.StopAtBounds
                visible: host.appViewMode === "list"
                spacing: 2; model: filteredModel
                add: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1.0; duration: 200 } }
                remove: Transition { NumberAnimation { property: "opacity"; to: 0; duration: 150 } }
                delegate: Item {
                    id: listWrapper
                    width: appsList.width
                    height: Math.round(36 * (host.appSize / 88.0))

                    property int _dragIdx: -1

                    Drag.active: listGrip.dragMouseArea.drag.active
                    Drag.source: listWrapper
                    Drag.hotSpot.x: width / 2
                    Drag.hotSpot.y: height / 2

                    states: State {
                        when: listGrip.dragMouseArea.drag.active
                        ParentChange { target: listWrapper; parent: appsList.contentItem }
                    }

                    AppRowDelegate {
                        anchors.fill: parent
                        widget: host
                        iconFactor: 20
                        fontSize: Theme.fontSizeSmall
                        hoveredIdx: hoveredIndex
                        deleteRevealApp: host._deleteRevealedApp
                    }

                    AddOverlay {}
                    DragGrip {
                        id: listGrip; leftMargin: 2
                        dragMouseArea.drag.target: listWrapper
                        dragMouseArea.drag.axis: Drag.YAxis
                        dragMouseArea.onPressed: _dragIdx = index
                        dragMouseArea.onReleased: {
                            if (dragMouseArea.drag.active) {
                                var toIdx = Math.round(listWrapper.y / (listWrapper.height + appsList.spacing))
                                toIdx = Math.max(0, Math.min(toIdx, filteredModel.count - 1))
                                if (toIdx !== _dragIdx) host.moveAppToIndex(_dragIdx, toIdx)
                            }
                        }
                    }
                }
            }

            // Compact View
            GridView {
                id: appsCompact
                width: parent.width
                height: parent.height - 24 - Theme.spacingS * 2
                clip: true; boundsBehavior: Flickable.StopAtBounds
                visible: host.appViewMode === "compact"
                cellWidth: Math.floor(width / Math.max(2, Math.floor(width / 130)))
                cellHeight: Math.round(30 * (host.appSize / 88.0)); model: filteredModel
                add: Transition { NumberAnimation { properties: "opacity,scale"; from: 0; to: 1.0; duration: 200 } }
                remove: Transition { NumberAnimation { properties: "opacity,scale"; to: 0; duration: 150 } }
                displaced: Transition {
                    NumberAnimation { properties: "x,y"; duration: 200; easing.type: Easing.OutQuad }
                }
                delegate: Item {
                    id: compactDelegateItem
                    width: appsCompact.cellWidth; height: appsCompact.cellHeight

                    property int _dragIdx: -1

                    Drag.active: compactGrip.dragMouseArea.drag.active
                    Drag.source: compactDelegateItem
                    Drag.hotSpot.x: width / 2
                    Drag.hotSpot.y: height / 2

                    states: State {
                        when: compactGrip.dragMouseArea.drag.active
                        ParentChange { target: compactDelegateItem; parent: appsCompact.contentItem }
                    }

                    AppRowDelegate {
                        anchors.fill: parent
                        widget: host
                        iconFactor: 16
                        fontSize: Theme.fontSizeSmall - 1
                        hoveredIdx: hoveredIndex
                        deleteRevealApp: host._deleteRevealedApp
                    }

                    AddOverlay {}
                    DragGrip {
                        id: compactGrip; leftMargin: 0
                        dragMouseArea.drag.target: compactDelegateItem
                        dragMouseArea.drag.axis: Drag.XAndYAxis
                        dragMouseArea.onPressed: _dragIdx = index
                        dragMouseArea.onReleased: {
                            if (dragMouseArea.drag.active) {
                                var cols = Math.max(2, Math.floor(appsCompact.width / appsCompact.cellWidth))
                                var toCol = Math.round(compactDelegateItem.x / appsCompact.cellWidth)
                                var toRow = Math.round(compactDelegateItem.y / appsCompact.cellHeight)
                                var toIdx = Math.max(0, Math.min(toRow * cols + toCol, filteredModel.count - 1))
                                if (toIdx !== _dragIdx) host.moveAppToIndex(_dragIdx, toIdx)
                            }
                        }
                    }
                }
            }
        }

        // Empty placeholder
        StyledText {
            text: content._tr("Click + to add applications")
            font.pixelSize: Theme.fontSizeSmall; color: host.fgColor; opacity: 0.4
            anchors.centerIn: parent
            visible: filteredModel.count === 0 && host.appSearchQuery === ""
        }

        // Toast notification (briefly shows on add/remove)
        Rectangle {
            id: toastRect
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom; anchors.bottomMargin: 16
            width: toastLabel.implicitWidth + 20; height: 30; radius: 15
            color: Theme.withAlpha(Theme.inverseSurface, 0.85)
            opacity: toastLabel.text !== "" ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
            property string msg: ""
            StyledText {
                id: toastLabel
                anchors.centerIn: parent
                text: toastRect.msg
                font.pixelSize: Theme.fontSizeSmall; color: Theme.inverseOnSurface
            }
            Timer {
                id: toastTimer
                interval: 1800; repeat: false
                onTriggered: toastRect.msg = ""
            }
        }

        // --- Add/Manage Dialog ---
        Rectangle {
            id: addAppDialog
            anchors.fill: parent
            color: "transparent"
            radius: Theme.cornerRadius; z: 100
            visible: opened || opacity > 0
            opacity: opened ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 150 } }
            property bool opened: false
            property var systemAppsList: []
            property string systemAppsSearch: ""
            property string activeTab: "add"
            property var filteredSystemApps: []

            // AppImage tab state
            property string appimageDirInput: ""
            property var appimageList: []
            property var appimageIconMap: ({})
            property bool appimageDirError: false
            readonly property string appIconsDir: (Quickshell.env("HOME") || "") + "/.config/DankMaterialShell/appicons"

            // Precomputed hash set for O(1) isAdded lookup (avoids O(N) some() per delegate)
            property var addedAppNameSet: ({})

            function rebuildAddedSet() {
                var set = {}
                var apps = host.addedApps
                for (var i = 0; i < apps.length; i++) {
                    set[apps[i].name] = true
                }
                addedAppNameSet = set  // new reference → triggers delegate rebindings
            }

            // ── AppImage tab helpers ──
            function expandPath(p) {
                if (!p) return ""
                var home = Quickshell.env("HOME") || ""
                if (p === "~") return home
                if (p.indexOf("~/") === 0) return home + p.substring(1)
                return p
            }
            function safeShell(p) { return p.replace(/'/g, "'\\''") }

            function cleanAppImageName(base) {
                var c = base
                    .replace(/[-_]\d+([-_.]\d+)*[-_](x86_64|amd64|aarch64|arm64|i686)$/i, "")
                    .replace(/[-_](x86_64|amd64|aarch64|arm64|i686)$/i, "")
                    .replace(/[-_]linux[-_](amd64|x86_64)$/i, "")
                    .replace(/[-_](fixed|stable|beta|alpha|rc|patch|debug|release|final|portable|setup|linux)$/i, "")
                return c || base
            }

            function matchAppImageIcon(fileName) {
                var base = fileName.replace(/\.appimage$/i, "").toLowerCase()
                for (var stem in appimageIconMap) {
                    if (base.indexOf(stem) !== -1) return appimageIconMap[stem]
                }
                return ""
            }

            function openAppImageTab() {
                activeTab = "appimage"
                if (appImagePathField.text === "") {
                    var saved = host.getData("appimageDir", "~")
                    appimageDirInput = saved
                    appImagePathField.text = saved
                }
                scanAppImages()
            }

            function scanAppImages() {
                var raw = appImagePathField.text.trim()
                if (raw === "") return
                _iconExtracting = false
                _iconExtractTotal = 0
                _iconExtractDone = 0
                appimageDirInput = raw
                host.setData("appimageDir", raw)
                var dir = expandPath(raw)
                appimageDirError = false
                var safeDir = safeShell(dir)
                appImageDirProc.command = ["sh", "-c",
                    "if [ -d '" + safeDir + "' ]; then echo __DIR__ " + safeDir + "; ls -1 '" + safeDir + "' 2>/dev/null | grep -iE '\\.appimage$' | head -100; else echo __DIR_ERR__; fi"]
                appImageDirProc.running = true
                var safeIcons = safeShell(appIconsDir)
                appIconsProc.command = ["sh", "-c", "ls -1 '" + safeIcons + "' 2>/dev/null | head -100"]
                appIconsProc.running = true
            }

            function handleDirList(text) {
                var out = String(text).trim()
                var lines = out.split("\n")
                var first = lines.shift() || ""
                // Directory echoed in the output first line → pairs result with its own run (no race)
                if (first.indexOf("__DIR__ ") !== 0) { appimageDirError = true; appimageList = []; return }
                var dir = first.substring(8)
                var files = lines
                var seen = {}
                var list = []
                for (var i = 0; i < files.length; i++) {
                    var fn = files[i].trim()
                    if (!fn) continue
                    var base = fn.replace(/\.appimage$/i, "")
                    var nm = cleanAppImageName(base)
                    if (seen[nm]) nm = base
                    if (seen[nm]) continue
                    seen[nm] = true
                    list.push({ name: nm, exec: "'" + dir + "/" + fn + "'", icon: matchAppImageIcon(fn), fileName: fn })
                }
                appimageList = list
            }

            function handleIconList(text) {
                var out = String(text).trim()
                var files = out === "" ? [] : out.split("\n")
                var map = {}
                for (var i = 0; i < files.length; i++) {
                    var f = files[i].trim()
                    if (!f) continue
                    var lower = f.toLowerCase()
                    if (!/\.(png|jpg|jpeg|svg|webp)$/.test(lower)) continue
                    var dot = f.lastIndexOf(".")
                    if (dot > 0) map[f.substring(0, dot).toLowerCase()] = encodeURI("file://" + appIconsDir + "/" + f)
                }
                appimageIconMap = map
                // Reapply icons to the already-built list
                if (appimageList.length > 0) {
                    var updated = []
                    for (var j = 0; j < appimageList.length; j++) {
                        var it = appimageList[j]
                        updated.push({ name: it.name, exec: it.exec, icon: matchAppImageIcon(it.fileName), fileName: it.fileName })
                    }
                    appimageList = updated
                }
                extractMissingAppIcons()
            }

            // ── AppImage embedded icon extraction (same cache dir & naming as DMS DankDash) ──
            property bool _iconExtractBusy: false
            property bool _iconExtracting: false
            property int _iconExtractTotal: 0
            property int _iconExtractDone: 0
            property string _iconExtractName: ""
            property string _iconExtractFileName: ""
            property var _iconExtractFailed: ({})

            Process {
                id: appIconExtractProc
                command: []
                stdout: StdioCollector {
                    id: appIconExtractCollector
                    onStreamFinished: addAppDialog.handleAppIconExtracted(appIconExtractCollector.text)
                }
            }

            function extractMissingAppIcons() {
                if (_iconExtractBusy) return
                var next = null
                for (var i = 0; i < appimageList.length; i++) {
                    var e = appimageList[i]
                    if (e.icon === "" && e.name !== "" && !_iconExtractFailed[e.fileName]) { next = e; break }
                }
                if (!next) { _iconExtracting = false; return }
                if (!_iconExtracting) {
                    var total = 0
                    for (var t = 0; t < appimageList.length; t++) {
                        var te = appimageList[t]
                        if (te.icon === "" && te.name !== "" && !_iconExtractFailed[te.fileName]) total++
                    }
                    _iconExtractTotal = total
                    _iconExtractDone = 0
                }
                _iconExtracting = true
                var appPath = next.exec
                if (appPath.charAt(0) === "'") appPath = appPath.substring(1, appPath.length - 1)
                _iconExtractBusy = true
                _iconExtractName = next.name
                _iconExtractFileName = next.fileName
                var cacheDir = safeShell(appIconsDir)
                var tmp = safeShell(appIconsDir + "/tmp-" + next.name)
                var app = safeShell(appPath)
                var name = safeShell(next.name)
                var resolve = "REAL_FILE=$(readlink -f \"$icon\" 2>/dev/null || echo \"$icon\"); if [ -f \"$REAL_FILE\" ]; then "
                var cpBodyPng = "cp \"$REAL_FILE\" '" + cacheDir + "/" + name + ".png' 2>/dev/null && FOUND_ICON=1 && break; fi; "
                var cpBodySvg = "cp \"$REAL_FILE\" '" + cacheDir + "/" + name + ".svg' 2>/dev/null && FOUND_ICON=1 && break; fi; "
                var cpBodyExt = "EXT=\"${REAL_FILE##*.}\"; case \"$EXT\" in png|svg|jpg|jpeg|ico|xpm) ;; *) EXT=png ;; esac; cp \"$REAL_FILE\" \"" + cacheDir + "/" + name + ".$EXT\" 2>/dev/null && FOUND_ICON=1 && break; fi; "
                // Largest icon first (better than DMS's first-match)
                // -xtype f: root-level icons are often symlinks; follow them
                var findPng = "find squashfs-root -xtype f -name '*.png' -printf '%s\\t%p\\n' 2>/dev/null | sort -rn | head -3 | cut -f2-"
                var findSvg = "find squashfs-root -xtype f -name '*.svg' -printf '%s\\t%p\\n' 2>/dev/null | sort -rn | head -3 | cut -f2-"
                var findAny = "find squashfs-root -maxdepth 7 -xtype f \\( -name '.DirIcon' -o -name '*.png' -o -name '*.svg' -o -name '*.jpg' -o -name '*.jpeg' -o -name '*.ico' -o -name '*.xpm' \\) -printf '%s\\t%p\\n' 2>/dev/null | sort -rn | head -3 | cut -f2-"
                // Stage 1/2: pattern extract (KBs only) — png, then svg, largest first
                // Stage 3: .DirIcon (few KB) + standard icon dirs — avoids full unpack
                // Stage 4: full extract — exotic layouts / broken pattern runtimes (last resort)
                var cmd =
                    "mkdir -p '" + cacheDir + "' && rm -rf '" + tmp + "' && mkdir -p '" + tmp + "' && cd '" + tmp + "' && " +
                    "FOUND_ICON=0; IFS='\n'; " +
                    "timeout 45 '" + app + "' --appimage-extract '*.png' >/dev/null 2>&1; " +
                    "for icon in $(" + findPng + "); do " +
                    resolve + cpBodyPng + "done; " +
                    "if [ \"$FOUND_ICON\" = 0 ]; then rm -rf squashfs-root; " +
                    "timeout 45 '" + app + "' --appimage-extract '*.svg' >/dev/null 2>&1; " +
                    "for icon in $(" + findSvg + "); do " +
                    resolve + cpBodySvg + "done; fi; " +
                    "if [ \"$FOUND_ICON\" = 0 ]; then rm -rf squashfs-root; " +
                    "timeout 45 '" + app + "' --appimage-extract '.DirIcon' >/dev/null 2>&1; " +
                    "if [ -e squashfs-root/.DirIcon ]; then " +
                    "REAL_FILE=$(readlink -f squashfs-root/.DirIcon 2>/dev/null || echo squashfs-root/.DirIcon); " +
                    "if case \"$REAL_FILE\" in squashfs-root/*) [ -f \"$REAL_FILE\" ] ;; *) false ;; esac; then " +
                    "EXT=\"${REAL_FILE##*.}\"; case \"$EXT\" in png|svg|jpg|jpeg|ico|xpm) ;; *) EXT=png ;; esac; cp \"$REAL_FILE\" \"" + cacheDir + "/" + name + ".$EXT\" 2>/dev/null && FOUND_ICON=1; fi; fi; " +
                    "if [ \"$FOUND_ICON\" = 0 ]; then " +
                    "timeout 45 '" + app + "' --appimage-extract 'usr/share/icons/*' >/dev/null 2>&1; " +
                    "timeout 45 '" + app + "' --appimage-extract 'usr/share/pixmaps/*' >/dev/null 2>&1; " +
                    // png/svg must be searched here too: newer runtimes' '*.png'
                    // pattern only matches root-level (symlinked) icons, so
                    // stage 1/2 yield nothing while usr/share/icons/* extracts fine
                    "for icon in $(find squashfs-root -xtype f \\( -name '*.png' -o -name '*.svg' -o -name '*.jpg' -o -name '*.jpeg' -o -name '*.ico' -o -name '*.xpm' \\) -printf '%s\\t%p\\n' 2>/dev/null | sort -rn | head -3 | cut -f2-); do " +
                    resolve + cpBodyExt + "done; fi; fi; " +
                    "if [ \"$FOUND_ICON\" = 0 ]; then rm -rf squashfs-root; " +
                    "timeout 45 '" + app + "' --appimage-extract >/dev/null 2>&1; " +
                    "for icon in $(" + findAny + "); do " +
                    resolve + cpBodyExt + "done; fi; " +
                    "rm -rf '" + tmp + "'; " +
                    "ls -1 '" + cacheDir + "'/" + name + ".* 2>/dev/null | head -1 || echo failed"
                appIconExtractProc.command = ["sh", "-c", cmd]
                appIconExtractProc.running = true
            }

            function handleAppIconExtracted(outText) {
                _iconExtractBusy = false
                var out = String(outText).trim()
                var fileName = _iconExtractFileName
                var name = _iconExtractName
                var ok = out !== "" && out !== "failed" && out.indexOf(appIconsDir) === 0
                if (!ok) {
                    if (fileName !== "") _iconExtractFailed[fileName] = true
                } else {
                    var url = encodeURI("file://" + out)
                    appimageIconMap[name.toLowerCase()] = url
                    // Refresh the browser-list entry
                    var rebuilt = []
                    for (var i = 0; i < appimageList.length; i++) {
                        var it = appimageList[i]
                        if (it.fileName === fileName && (it.icon === "" || it.icon.indexOf(".$EXT") !== -1))
                            rebuilt.push({ name: it.name, exec: it.exec, icon: url, fileName: it.fileName })
                        else rebuilt.push(it)
                    }
                    appimageList = rebuilt
                    // Refresh persisted launcher entries of the same AppImage
                    var added = host.addedApps
                    var marker = "/" + fileName + "'"
                    var aNew = []
                    var aChanged = false
                    for (var j = 0; j < added.length; j++) {
                        var a = added[j]
                        if ((a.icon === "" || a.icon.indexOf(".$EXT") !== -1) && a.exec && a.exec.indexOf(marker) !== -1) {
                            aNew.push({ name: a.name, exec: a.exec, icon: url })
                            aChanged = true
                        } else aNew.push(a)
                    }
                    if (aChanged) host.saveAddedApps(aNew)
                }
                _iconExtractDone++
                extractMissingAppIcons()
            }

            onSystemAppsSearchChanged: {
                var s = systemAppsSearch.toLowerCase().trim()
                if (s === "") {
                    filteredSystemApps = systemAppsList
                } else {
                    filteredSystemApps = systemAppsList.filter(function(app) {
                        return app.name.toLowerCase().indexOf(s) !== -1 || (app.exec && app.exec.toLowerCase().indexOf(s) !== -1)
                    })
                }
            }

            MouseArea { anchors.fill: parent; onClicked: {} }

            Process {
                id: appImageDirProc
                command: []
                stdout: StdioCollector {
                    id: appImageDirCollector
                    onStreamFinished: addAppDialog.handleDirList(appImageDirCollector.text)
                }
            }

            Process {
                id: appIconsProc
                command: []
                stdout: StdioCollector {
                    id: appIconsCollector
                    onStreamFinished: addAppDialog.handleIconList(appIconsCollector.text)
                }
            }

            // ── Pure-QML directory browser ──
            // Replaces the native FolderDialog: the GTK/gvfs backend can abort the
            // whole shell (g_variant assertion, SIGABRT), so we list dirs ourselves.
            property bool dirBrowserVisible: false
            property string dirBrowserDir: ""
            property var dirBrowserEntries: []
            property var dirBrowserAllDirs: []
            property bool dirBrowserShowHidden: false
            property bool dirBrowserError: false

            Process {
                id: dirBrowserProc
                command: []
                stdout: StdioCollector {
                    id: dirBrowserCollector
                    onStreamFinished: addAppDialog.handleDirBrowserList(dirBrowserCollector.text)
                }
            }

            function openDirBrowser(startDir) {
                dirBrowserVisible = true
                browseTo(startDir && String(startDir).trim() !== "" ? startDir : "~")
            }
            function closeDirBrowser() {
                dirBrowserVisible = false
                dirBrowserEntries = []
                dirBrowserDir = ""
                dirBrowserError = false
            }
            function browseTo(p) {
                var dir = expandPath(String(p).trim())
                if (dir === "") dir = Quickshell.env("HOME") || "/"
                while (dir.length > 1 && dir.charAt(dir.length - 1) === "/") dir = dir.substring(0, dir.length - 1)
                if (dir === "") dir = "/"
                var safe = safeShell(dir)
                dirBrowserProc.command = ["sh", "-c", "if [ -d '" + safe + "' ] && [ -x '" + safe + "' ]; then echo __DIR__ " + safe + "; ls -1Ap '" + safe + "' | head -200; else echo __DIR_ERR__; fi"]
                dirBrowserProc.running = true
            }
            function parentDir(p) {
                var i = p.lastIndexOf("/")
                return i <= 0 ? "/" : p.substring(0, i)
            }
            function handleDirBrowserList(outText) {
                var out = String(outText).trim()
                var lines = out.split("\n")
                var first = lines.shift() || ""
                // Directory echoed in the output first line → pairs result with its own run (no race)
                if (first.indexOf("__DIR__ ") !== 0) {
                    addAppDialog.dirBrowserError = true
                    addAppDialog.dirBrowserAllDirs = []
                    applyDirBrowserFilter()
                    return
                }
                addAppDialog.dirBrowserDir = first.substring(8)
                addAppDialog.dirBrowserError = false
                var lsLines = lines
                var dirs = []
                for (var i = 0; i < lsLines.length; i++) {
                    var n = lsLines[i].trim()
                    if (!n) continue
                    // Folder picker: list directories only (trailing "/" from ls -p)
                    if (n.charAt(n.length - 1) === "/") dirs.push({ name: n.substring(0, n.length - 1) })
                }
                addAppDialog.dirBrowserAllDirs = dirs
                applyDirBrowserFilter()
            }
            function applyDirBrowserFilter() {
                var dirs = addAppDialog.dirBrowserAllDirs
                var showHidden = addAppDialog.dirBrowserShowHidden
                var visible = []
                for (var i = 0; i < dirs.length; i++) {
                    if (!showHidden && dirs[i].name.charAt(0) === ".") continue
                    visible.push(dirs[i])
                }
                visible.sort(function(a, b) { return a.name.localeCompare(b.name) })
                addAppDialog.dirBrowserEntries = visible
            }
            function confirmDirBrowser() {
                if (dirBrowserDir === "" || dirBrowserError) return
                appImagePathField.text = dirBrowserDir
                closeDirBrowser()
                scanAppImages()
            }

            // Directory browser overlay card
            Rectangle {
                id: dirBrowserCard
                z: 12
                visible: addAppDialog.dirBrowserVisible
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 8
                width: Math.min(320, parent.width - 20)
                height: parent.height - 16
                color: host.bgColor !== "" ? host.bgColor : Theme.surfaceContainer
                radius: Theme.cornerRadius
                border.color: Theme.withAlpha(Theme.outline, 0.2)
                border.width: 1
                clip: true

                // Block clicks from falling through to the dialog beneath
                MouseArea { anchors.fill: parent; onClicked: {} }

                Column {
                    anchors.fill: parent
                    anchors.margins: Theme.spacingM
                    spacing: Theme.spacingS

                    // Title row
                    Item {
                        width: parent.width
                        height: 20
                        DankIcon { name: "folder_open"; size: 14; color: Theme.primary; anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter }
                        StyledText { text: content._tr("Select Folder"); font.pixelSize: Theme.fontSizeSmall; font.bold: true; color: host.fgColor; anchors.centerIn: parent }
                        Rectangle {
                            width: 20; height: 20; radius: 10
                            anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                            color: dirBrowserCloseArea.containsMouse ? Theme.withAlpha(Theme.error, 0.2) : Theme.withAlpha(host.fgColor, 0.06)
                            DankIcon { anchors.centerIn: parent; name: "close"; size: 12; color: host.fgColor }
                            MouseArea { id: dirBrowserCloseArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: addAppDialog.closeDirBrowser() }
                        }
                    }

                    // Current path + navigation
                    Rectangle {
                        width: parent.width
                        height: 30
                        radius: Math.round(Theme.cornerRadius / 2)
                        color: Theme.withAlpha(host.fgColor, 0.04)
                        border.color: Theme.withAlpha(Theme.outline, 0.1)
                        border.width: 1
                        Rectangle {
                            id: dirUpBtn
                            width: 24; height: 24; radius: 12
                            anchors.left: parent.left; anchors.leftMargin: 3; anchors.verticalCenter: parent.verticalCenter
                            color: dirUpArea.containsMouse ? Theme.withAlpha(Theme.primary, 0.15) : "transparent"
                            DankIcon { anchors.centerIn: parent; name: "arrow_upward"; size: 13; color: host.fgColor }
                            MouseArea { id: dirUpArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: { if (addAppDialog.dirBrowserDir !== "" && addAppDialog.dirBrowserDir !== "/") addAppDialog.browseTo(addAppDialog.parentDir(addAppDialog.dirBrowserDir)) } }
                        }
                        Rectangle {
                            id: dirHomeBtn
                            width: 24; height: 24; radius: 12
                            anchors.left: dirUpBtn.right; anchors.leftMargin: 2; anchors.verticalCenter: parent.verticalCenter
                            color: dirHomeArea.containsMouse ? Theme.withAlpha(Theme.primary, 0.15) : "transparent"
                            DankIcon { anchors.centerIn: parent; name: "home"; size: 13; color: host.fgColor }
                            MouseArea { id: dirHomeArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: addAppDialog.browseTo(Quickshell.env("HOME") || "/") }
                        }
                        Rectangle {
                            id: dirHiddenBtn
                            width: 24; height: 24; radius: 12
                            anchors.right: parent.right; anchors.rightMargin: 3; anchors.verticalCenter: parent.verticalCenter
                            color: dirHiddenArea.containsMouse ? Theme.withAlpha(Theme.primary, 0.25) : (addAppDialog.dirBrowserShowHidden ? Theme.withAlpha(Theme.primary, 0.2) : Theme.withAlpha(host.fgColor, 0.08))
                            border.color: addAppDialog.dirBrowserShowHidden ? Theme.withAlpha(Theme.primary, 0.4) : "transparent"
                            border.width: 1
                            StyledText { anchors.centerIn: parent; text: "👁"; font.pixelSize: 12; color: host.fgColor; opacity: addAppDialog.dirBrowserShowHidden ? 1.0 : 0.5 }
                            MouseArea { id: dirHiddenArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: { addAppDialog.dirBrowserShowHidden = !addAppDialog.dirBrowserShowHidden; addAppDialog.applyDirBrowserFilter() } }
                        }
                        StyledText {
                            text: addAppDialog.dirBrowserDir
                            anchors.left: dirHomeBtn.right; anchors.leftMargin: Theme.spacingS
                            anchors.right: dirHiddenBtn.left; anchors.rightMargin: Theme.spacingS
                            anchors.verticalCenter: parent.verticalCenter
                            font.pixelSize: 11
                            color: addAppDialog.dirBrowserError ? Theme.error : host.fgColor
                            opacity: addAppDialog.dirBrowserError ? 1.0 : 0.8
                            elide: Text.ElideMiddle
                        }
                    }

                    // Directory entries
                    Item {
                        width: parent.width
                        height: parent.height - 20 - 30 - 32 - Theme.spacingS * 3

                        ListView {
                            id: dirBrowserList
                            anchors.fill: parent
                            clip: true; spacing: 2; boundsBehavior: Flickable.StopAtBounds
                            model: addAppDialog.dirBrowserEntries
                            delegate: Rectangle {
                                width: dirBrowserList.width
                                height: 30
                                radius: Math.max(2, Math.round(Theme.cornerRadius / 2) - 2)
                                color: dirEntryArea.containsMouse ? Theme.withAlpha(host.fgColor, 0.06) : "transparent"
                                Row {
                                    anchors.fill: parent; anchors.leftMargin: Theme.spacingS
                                    spacing: Theme.spacingS
                                    Item { width: 15; height: 15; anchors.verticalCenter: parent.verticalCenter
                                        DankIcon { anchors.fill: parent; name: "folder"; size: 15; color: Theme.primary } }
                                    StyledText { text: modelData.name; font.pixelSize: Theme.fontSizeSmall; color: host.fgColor; elide: Text.ElideRight; width: parent.width - 15 - Theme.spacingS * 2 - 8; anchors.verticalCenter: parent.verticalCenter }
                                }
                                MouseArea {
                                    id: dirEntryArea
                                    anchors.fill: parent; hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: { addAppDialog.browseTo(addAppDialog.dirBrowserDir === "/" ? "/" + modelData.name : addAppDialog.dirBrowserDir + "/" + modelData.name) }
                                }
                            }
                        }

                        // Fast scroll overlay (default wheel step is too slow)
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: false
                            propagateComposedEvents: true
                            onWheel: function(wheel) {
                                wheel.accepted = true
                                if (dirBrowserList.contentHeight > dirBrowserList.height) {
                                    dirBrowserList.contentY = Math.max(0, Math.min(
                                        dirBrowserList.contentY - wheel.angleDelta.y * 1.0,
                                        dirBrowserList.contentHeight - dirBrowserList.height))
                                }
                            }
                            onPressed: function(mouse) { mouse.accepted = false }
                            onReleased: function(mouse) { mouse.accepted = false }
                            onClicked: function(mouse) { mouse.accepted = false }
                        }

                        StyledText {
                            anchors.centerIn: parent
                            width: parent.width - 24
                            horizontalAlignment: Text.AlignHCenter
                            visible: addAppDialog.dirBrowserEntries.length === 0
                            text: addAppDialog.dirBrowserError ? content._tr("Folder not found") : content._tr("Empty folder")
                            font.pixelSize: Theme.fontSizeSmall
                            color: host.fgColor
                            opacity: 0.5
                            wrapMode: Text.WordWrap
                        }
                    }

                    // Footer: confirm selection
                    Rectangle {
                        width: parent.width
                        height: 32
                        radius: Math.round(Theme.cornerRadius / 2)
                        color: dirUseArea.containsMouse ? Theme.withAlpha(Theme.primary, 0.3) : Theme.withAlpha(Theme.primary, 0.2)
                        StyledText { text: content._tr("Use This Folder"); font.pixelSize: Theme.fontSizeSmall; font.bold: true; color: Theme.primary; anchors.centerIn: parent }
                        MouseArea { id: dirUseArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: addAppDialog.confirmDirBrowser() }
                    }
                }
            }

            function openDialog(tab) {
                activeTab = tab !== undefined ? tab : "add"
                systemAppsSearch = ""; systemSearchField.text = ""; opened = true
                rebuildAddedSet()
                content.cleanupMissingApps()
                if (activeTab === "add") systemSearchField.forceActiveFocus()
                if (activeTab === "appimage") openAppImageTab()
                if (systemAppsList.length === 0) {
                    var allEntries = DesktopEntries.applications.values
                    var apps = []
                    var seen = {}
                    for (var i = 0; i < allEntries.length; i++) {
                        var app = allEntries[i]
                        if (app && !app.noDisplay) {
                            var nm = app.name || ""
                            if (seen[nm]) continue  // skip duplicates by name
                            seen[nm] = true
                            apps.push({ name: nm, exec: host.cleanExec(app.execString || (app.command ? app.command.join(" ") : "")), icon: app.icon || "" })
                        }
                    }
                    apps.sort(function(a, b) { return (a.name || "").localeCompare(b.name || "") })
                    systemAppsList = apps
                    filteredSystemApps = apps
                }
            }
            function close() {
                opened = false
                var pos = dialogCard.mapToItem(launcherContainer, 0, 0)
                dissolveParticles.burst(pos.x + dialogCard.width / 2, pos.y + dialogCard.height / 2, dialogCard.width, dialogCard.height)
            }

            Rectangle {
                id: dialogCard
                z: 10
                width: Math.min(320, parent.width - 20); height: parent.height - 16
                // Top aligns with the header settings icon, same as the settings card
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 8
                color: host.bgColor !== "" ? host.bgColor : Theme.surfaceContainer; radius: Theme.cornerRadius
                border.color: Qt.rgba(1, 1, 1, 0.06); border.width: 1; clip: true
                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true; shadowHorizontalOffset: 0; shadowVerticalOffset: 8
                    shadowBlur: 0.8; shadowColor: Qt.rgba(0, 0, 0, 0.6); shadowOpacity: 0.7
                }
                scale: addAppDialog.opened ? 1.0 : 0.95
                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }

                Column {
                    anchors.fill: parent; anchors.margins: Theme.spacingS; anchors.topMargin: Theme.spacingS; anchors.bottomMargin: Theme.spacingS + 30; spacing: 8

                    Item {
                        width: parent.width; height: 24
                        StyledText {
                            text: content._tr("Manage")
                            font.bold: true; font.pixelSize: Theme.fontSizeMedium; color: host.fgColor
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        Item {
                            width: 28; height: 28
                            anchors.right: parent.right; anchors.rightMargin: -2; anchors.verticalCenter: parent.verticalCenter

                            DankIcon {
                                anchors.centerIn: parent
                                name: "close"; size: 16; color: host.fgColor
                                opacity: closeBtn.containsMouse ? 1.0 : 0.6
                            }
                            MouseArea {
                                id: closeBtn
                                anchors.fill: parent
                                hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: addAppDialog.close()
                            }
                        }
                    }

                    // Tabs
                    Rectangle {
                        width: parent.width; height: 32; radius: 16
                        color: Theme.withAlpha(host.fgColor, 0.05)
                        border.color: Theme.withAlpha(Theme.outline, 0.1); border.width: 1
                        Row {
                            anchors.fill: parent; anchors.margins: 2
                            MouseArea {
                                id: tabAddBtn; width: parent.width / 3; height: parent.height; cursorShape: Qt.PointingHandCursor
                                onClicked: addAppDialog.activeTab = "add"
                                Rectangle {
                                    anchors.fill: parent; radius: 14
                                    color: addAppDialog.activeTab === "add" ? Theme.withAlpha(Theme.primary, 0.22) : "transparent"
                                    StyledText {
                                        anchors.centerIn: parent; text: content._tr("Applications")
                                        font.bold: addAppDialog.activeTab === "add"; font.pixelSize: Theme.fontSizeSmall
                                        color: addAppDialog.activeTab === "add" ? Theme.primary : host.fgColor
                                        opacity: addAppDialog.activeTab === "add" ? 1.0 : (tabAddBtn.containsMouse ? 0.9 : 0.6)
                                    }
                                }
                            }
                            MouseArea {
                                id: tabAppImageBtn; width: parent.width / 3; height: parent.height; cursorShape: Qt.PointingHandCursor
                                onClicked: addAppDialog.openAppImageTab()
                                Rectangle {
                                    anchors.fill: parent; radius: 14
                                    color: addAppDialog.activeTab === "appimage" ? Theme.withAlpha(Theme.primary, 0.22) : "transparent"
                                    StyledText {
                                        anchors.centerIn: parent; text: content._tr("AppImage")
                                        font.bold: addAppDialog.activeTab === "appimage"; font.pixelSize: Theme.fontSizeSmall
                                        color: addAppDialog.activeTab === "appimage" ? Theme.primary : host.fgColor
                                        opacity: addAppDialog.activeTab === "appimage" ? 1.0 : (tabAppImageBtn.containsMouse ? 0.9 : 0.6)
                                    }
                                }
                            }
                            MouseArea {
                                id: tabManageBtn; width: parent.width / 3; height: parent.height; cursorShape: Qt.PointingHandCursor
                                onClicked: addAppDialog.activeTab = "manage"
                                Rectangle {
                                    anchors.fill: parent; radius: 14
                                    color: addAppDialog.activeTab === "manage" ? Theme.withAlpha(Theme.primary, 0.22) : "transparent"
                                    StyledText {
                                        anchors.centerIn: parent; text: content._tr("Layout")
                                        font.bold: addAppDialog.activeTab === "manage"; font.pixelSize: Theme.fontSizeSmall
                                        color: addAppDialog.activeTab === "manage" ? Theme.primary : host.fgColor
                                        opacity: addAppDialog.activeTab === "manage" ? 1.0 : (tabManageBtn.containsMouse ? 0.9 : 0.6)
                                    }
                                }
                            }
                        }
                    }

                    // Search (Add tab)
                    Rectangle {
                        visible: addAppDialog.activeTab === "add"
                        width: parent.width; height: 32; radius: Math.round(Theme.cornerRadius / 2)
                        color: Theme.withAlpha(host.fgColor, 0.04)
                        border.color: systemSearchField.activeFocus ? Theme.primary : Theme.withAlpha(Theme.outline, 0.1); border.width: 1
                        DankIcon { id: sysSearchIcon; name: "search"; size: 14; color: host.fgColor; opacity: 0.5; anchors.left: parent.left; anchors.leftMargin: Theme.spacingS; anchors.verticalCenter: parent.verticalCenter }
                        TextInput {
                            id: systemSearchField
                            anchors.left: sysSearchIcon.right; anchors.leftMargin: Theme.spacingXS
                            anchors.right: parent.right; anchors.rightMargin: Theme.spacingS
                            anchors.verticalCenter: parent.verticalCenter
                            font.pixelSize: Theme.fontSizeSmall; color: host.fgColor; selectByMouse: true
                            onTextChanged: addAppDialog.systemAppsSearch = text
                            Text { text: content._tr("Search system apps..."); font.pixelSize: Theme.fontSizeSmall; color: host.fgColor; opacity: 0.35; visible: systemSearchField.text === "" && !systemSearchField.activeFocus; anchors.verticalCenter: parent.verticalCenter }
                        }
                    }

                    // System apps list
                    // System apps list wrapper
                    Item {
                        width: parent.width
                        height: dialogCard.height - Theme.spacingM * 2 - 24 - 32 - 32 - Theme.spacingS * 3
                        visible: addAppDialog.activeTab === "add"

                        ListView {
                            id: systemAppsListView
                            anchors.fill: parent
                            clip: true; spacing: 2; boundsBehavior: Flickable.StopAtBounds
                            model: addAppDialog.filteredSystemApps
                                                        delegate: Rectangle {
                                width: parent.width; height: 38
                                radius: Math.max(2, Math.round(Theme.cornerRadius / 2) - 2)
                                color: listMouseArea.containsMouse ? Theme.withAlpha(host.fgColor, 0.04) : "transparent"
                                property bool isAdded: addAppDialog.addedAppNameSet[modelData.name] === true
                                Row {
                                    anchors.fill: parent; anchors.leftMargin: Theme.spacingS; anchors.rightMargin: Theme.spacingS
                                    spacing: Theme.spacingS; anchors.verticalCenter: parent.verticalCenter
                                    AppIcon {
                                        width: 24; height: 24; iconSize: 24
                                        iconSource: modelData.icon
                                        fallbackColor: host.fgColor
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    StyledText { text: modelData.name; font.pixelSize: Theme.fontSizeSmall; color: host.fgColor; elide: Text.ElideRight; width: parent.width - 24 - 32 - Theme.spacingS * 2; anchors.verticalCenter: parent.verticalCenter }
                                }
                                Rectangle {
                                    width: 22; height: 22; radius: 11
                                    anchors.right: parent.right; anchors.rightMargin: Theme.spacingS + 8; anchors.verticalCenter: parent.verticalCenter
                                    color: parent.isAdded ? Theme.withAlpha(Theme.primary, 0.15) : "transparent"
                                    border.color: parent.isAdded ? Theme.primary : Theme.withAlpha(Theme.outline, 0.3); border.width: 1
                                    DankIcon { anchors.centerIn: parent; name: parent.parent.isAdded ? "done" : "add"; size: 12; color: parent.parent.isAdded ? Theme.primary : host.fgColor }
                                }
                                MouseArea {
                                    id: listMouseArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (parent.isAdded) { host.removeApp(modelData.name); toastRect.msg = "✖ " + modelData.name }
                                        else { host.addApp(modelData); toastRect.msg = "✔ " + modelData.name }
                                        toastTimer.restart()
                                    }
                                }
                            }
                        }

                        Item { width: 16; anchors.right: parent.right; anchors.top: parent.top; anchors.bottom: parent.bottom; z: 10; visible: systemAppsListView.contentHeight > systemAppsListView.height
                            Rectangle { id: sysSB; width: 6; radius: 3; anchors.right: parent.right; anchors.rightMargin: 2; height: Math.max(20, parent.height * systemAppsListView.visibleArea.heightRatio); color: Theme.withAlpha(Theme.primary, 0.2); y: systemAppsListView.contentY / systemAppsListView.contentHeight * parent.height }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; property real _py: 0
                                onPressed: function(mouse) { _py = mouse.y - sysSB.y }
                                onPositionChanged: function(mouse) { var lv = systemAppsListView; if (lv.contentHeight > lv.height) { var ny = Math.max(0, Math.min(parent.height - sysSB.height, mouse.y - _py)); sysSB.y = ny; lv.contentY = ny / parent.height * lv.contentHeight } } } }
                        // Fast scroll overlay
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: false
                            propagateComposedEvents: true
                            onWheel: function(wheel) {
                                wheel.accepted = true
                                if (systemAppsListView.contentHeight > systemAppsListView.height) {
                                    systemAppsListView.contentY = Math.max(0, Math.min(
                                        systemAppsListView.contentY - wheel.angleDelta.y * 1.0,
                                        systemAppsListView.contentHeight - systemAppsListView.height))
                                }
                            }
                            onPressed: function(mouse) { mouse.accepted = false }
                            onReleased: function(mouse) { mouse.accepted = false }
                            onClicked: function(mouse) { mouse.accepted = false }
                        }
                    }

                    // AppImage tab: folder path
                    Rectangle {
                        visible: addAppDialog.activeTab === "appimage"
                        width: parent.width; height: 32; radius: Math.round(Theme.cornerRadius / 2)
                        color: Theme.withAlpha(host.fgColor, 0.04)
                        border.color: appImagePathField.activeFocus ? Theme.primary : Theme.withAlpha(Theme.outline, 0.1); border.width: 1
                        DankIcon { id: appImagePathIcon; name: "folder"; size: 14; color: host.fgColor; opacity: 0.5; anchors.left: parent.left; anchors.leftMargin: Theme.spacingS; anchors.verticalCenter: parent.verticalCenter }
                        MouseArea {
                            id: appImageBrowseArea
                            width: 28; height: parent.height
                            anchors.left: parent.left; anchors.leftMargin: Theme.spacingS - 7; anchors.verticalCenter: parent.verticalCenter
                            hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: addAppDialog.openDirBrowser(appImagePathField.text)
                        }
                        TextInput {
                            id: appImagePathField
                            anchors.left: appImagePathIcon.right; anchors.leftMargin: Theme.spacingXS
                            anchors.right: appImageRefreshBtn.left; anchors.rightMargin: Theme.spacingXS
                            anchors.verticalCenter: parent.verticalCenter
                            font.pixelSize: Theme.fontSizeSmall; color: host.fgColor; selectByMouse: true
                            onAccepted: addAppDialog.scanAppImages()
                            Text { text: content._tr("AppImage folder path..."); font.pixelSize: Theme.fontSizeSmall; color: host.fgColor; opacity: 0.35; visible: appImagePathField.text === "" && !appImagePathField.activeFocus; anchors.verticalCenter: parent.verticalCenter }
                        }
                        Item {
                            id: appImageRefreshBtn
                            width: 22; height: 22
                            anchors.right: parent.right; anchors.rightMargin: Theme.spacingS; anchors.verticalCenter: parent.verticalCenter
                            DankIcon { anchors.centerIn: parent; name: "refresh"; size: 13; color: host.fgColor; opacity: appImageRefreshArea.containsMouse ? 1.0 : 0.6 }
                            MouseArea {
                                id: appImageRefreshArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: addAppDialog.scanAppImages()
                            }
                        }
                    }

                    // AppImage list
                    Item {
                        width: parent.width
                        height: dialogCard.height - Theme.spacingM * 2 - 24 - 32 - 32 - Theme.spacingS * 4
                        visible: addAppDialog.activeTab === "appimage"

                        ListView {
                            id: appImageListView
                            anchors.fill: parent
                            clip: true; spacing: 2; boundsBehavior: Flickable.StopAtBounds
                            model: addAppDialog.appimageList
                            delegate: Rectangle {
                                width: parent.width; height: 38
                                radius: Math.max(2, Math.round(Theme.cornerRadius / 2) - 2)
                                color: appImgListMouseArea.containsMouse ? Theme.withAlpha(host.fgColor, 0.04) : "transparent"
                                property bool isAdded: addAppDialog.addedAppNameSet[modelData.name] === true
                                Row {
                                    anchors.fill: parent; anchors.leftMargin: Theme.spacingS; anchors.rightMargin: Theme.spacingS
                                    spacing: Theme.spacingS; anchors.verticalCenter: parent.verticalCenter
                                    AppIcon {
                                        width: 24; height: 24; iconSize: 24
                                        iconSource: modelData.icon
                                        fallbackColor: host.fgColor
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    StyledText { text: modelData.name; font.pixelSize: Theme.fontSizeSmall; color: host.fgColor; elide: Text.ElideRight; width: parent.width - 24 - 32 - Theme.spacingS * 2; anchors.verticalCenter: parent.verticalCenter }
                                }
                                Rectangle {
                                    width: 22; height: 22; radius: 11
                                    anchors.right: parent.right; anchors.rightMargin: Theme.spacingS + 8; anchors.verticalCenter: parent.verticalCenter
                                    color: parent.isAdded ? Theme.withAlpha(Theme.primary, 0.15) : "transparent"
                                    border.color: parent.isAdded ? Theme.primary : Theme.withAlpha(Theme.outline, 0.3); border.width: 1
                                    DankIcon { anchors.centerIn: parent; name: parent.parent.isAdded ? "done" : "add"; size: 12; color: parent.parent.isAdded ? Theme.primary : host.fgColor }
                                }
                                MouseArea {
                                    id: appImgListMouseArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (parent.isAdded) { host.removeApp(modelData.name); toastRect.msg = "✖ " + modelData.name }
                                        else { host.addApp({ name: modelData.name, exec: modelData.exec, icon: modelData.icon }); toastRect.msg = "✔ " + modelData.name }
                                        toastTimer.restart()
                                    }
                                }
                            }
                        }

                        // Empty / error hint
                        StyledText {
                            anchors.centerIn: parent
                            width: parent.width - 32
                            horizontalAlignment: Text.AlignHCenter
                            visible: appImageListView.count === 0
                            text: addAppDialog.appimageDirError ? content._tr("Folder not found") : content._tr("No AppImage files found")
                            font.pixelSize: Theme.fontSizeSmall; color: host.fgColor; opacity: 0.5
                            wrapMode: Text.WordWrap
                        }

                        // Scrollbar
                        Item { width: 16; anchors.right: parent.right; anchors.top: parent.top; anchors.bottom: parent.bottom; z: 10; visible: appImageListView.contentHeight > appImageListView.height
                            Rectangle { id: appImgSB; width: 6; radius: 3; anchors.right: parent.right; anchors.rightMargin: 2; height: Math.max(20, parent.height * appImageListView.visibleArea.heightRatio); color: Theme.withAlpha(Theme.primary, 0.2); y: appImageListView.contentY / appImageListView.contentHeight * parent.height }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; property real _py: 0
                                onPressed: function(mouse) { _py = mouse.y - appImgSB.y }
                                onPositionChanged: function(mouse) { var lv = appImageListView; if (lv.contentHeight > lv.height) { var ny = Math.max(0, Math.min(parent.height - appImgSB.height, mouse.y - _py)); appImgSB.y = ny; lv.contentY = ny / parent.height * lv.contentHeight } } } }
                        // Fast scroll overlay
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: false
                            propagateComposedEvents: true
                            onWheel: function(wheel) {
                                wheel.accepted = true
                                if (appImageListView.contentHeight > appImageListView.height) {
                                    appImageListView.contentY = Math.max(0, Math.min(
                                        appImageListView.contentY - wheel.angleDelta.y * 1.0,
                                        appImageListView.contentHeight - appImageListView.height))
                                }
                            }
                            onPressed: function(mouse) { mouse.accepted = false }
                            onReleased: function(mouse) { mouse.accepted = false }
                            onClicked: function(mouse) { mouse.accepted = false }
                        }
                    }

                    // Manage list wrapper (with drag reorder)
                    Item {
                        width: parent.width
                        height: dialogCard.height - Theme.spacingM * 2 - 24 - 32 - Theme.spacingS * 2
                        visible: addAppDialog.activeTab === "manage"

                        ListView {
                            id: manageListView
                            anchors.fill: parent
                            clip: true; spacing: 4; boundsBehavior: Flickable.StopAtBounds
                            model: host.addedApps
                                                        displaced: Transition {
                            NumberAnimation { properties: "x,y"; duration: 200; easing.type: Easing.OutQuad }
                        }

                        delegate: Item {
                            id: delegateItem
                            width: manageListView.width
                            height: 38

                            Rectangle {
                                id: delegateContent
                                width: parent.width; height: 38
                                radius: Math.max(2, Math.round(Theme.cornerRadius / 2) - 2)
                                color: manageItemMouseArea.containsMouse ? Theme.withAlpha(host.fgColor, 0.04) : "transparent"

                                Drag.active: gripMouse.drag.active
                                Drag.source: delegateItem
                                Drag.hotSpot.x: width / 2
                                Drag.hotSpot.y: height / 2

                                states: State {
                                    when: gripMouse.drag.active
                                    ParentChange { target: delegateContent; parent: manageListView.contentItem }
                                    AnchorChanges { target: delegateContent; anchors.verticalCenter: undefined }
                                }

                                MouseArea { id: manageItemMouseArea; anchors.fill: parent; hoverEnabled: true }

                                Row {
                                    anchors.fill: parent
                                    anchors.leftMargin: 4; anchors.rightMargin: Theme.spacingS
                                    spacing: 4

                                    // Drag grip handle
                                    DankIcon {
                                        id: gripIcon
                                        name: "drag_indicator"
                                        size: 18; color: host.fgColor
                                        opacity: gripMouse.containsMouse || gripMouse.drag.active ? 0.7 : 0.25
                                        anchors.verticalCenter: parent.verticalCenter

                                        MouseArea {
                                            id: gripMouse
                                            anchors.fill: parent
                                            anchors.margins: -4
                                            drag.target: delegateContent
                                            drag.axis: Drag.YAxis
                                            cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                                            hoverEnabled: true
                                            property int dragFromIdx: index
                                            onPressed: dragFromIdx = index
                                            onReleased: {
                                                var itemH = delegateItem.height + manageListView.spacing
                                                var toIdx = Math.round(delegateContent.y / itemH)
                                                toIdx = Math.max(0, Math.min(toIdx, host.addedApps.length - 1))
                                                if (toIdx !== dragFromIdx) host.moveAppToIndex(dragFromIdx, toIdx)
                                            }
                                        }
                                    }

                                    // App icon
                                    AppIcon {
                                        width: 24; height: 24; iconSize: 24
                                        iconSource: modelData.icon
                                        fallbackColor: host.fgColor
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    // App name
                                    StyledText {
                                        text: modelData.name
                                        font.pixelSize: Theme.fontSizeSmall; color: host.fgColor
                                        elide: Text.ElideRight
                                        width: parent.width - 24 - 24 - 32 - 4 * 4
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    // Delete button
                                    MouseArea {
                                        id: delBtn; width: 22; height: 22
                                        hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        anchors.verticalCenter: parent.verticalCenter
                                        onClicked: { host.removeApp(modelData.name); toastRect.msg = "✖ " + modelData.name; toastTimer.restart() }
                                        DankIcon {
                                            anchors.centerIn: parent
                                            name: "delete"; size: 14
                                            color: delBtn.containsMouse ? Theme.error : host.fgColor
                                            opacity: delBtn.containsMouse ? 1.0 : 0.6
                                        }
                                    }
                                }
                            }
                        }
                    }

                        Item { width: 16; anchors.right: parent.right; anchors.top: parent.top; anchors.bottom: parent.bottom; z: 10; visible: manageListView.contentHeight > manageListView.height
                            Rectangle { id: mgrSB; width: 6; radius: 3; anchors.right: parent.right; anchors.rightMargin: 2; height: Math.max(20, parent.height * manageListView.visibleArea.heightRatio); color: Theme.withAlpha(Theme.primary, 0.2); y: manageListView.contentY / manageListView.contentHeight * parent.height }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; property real _off: 0
                                onPressed: function(mouse) { _off = mouse.y - mgrSB.y }
                                onPositionChanged: function(mouse) { var lv = manageListView; if (lv.contentHeight > lv.height) { var ny = Math.max(0, Math.min(parent.height - mgrSB.height, mouse.y - _off)); mgrSB.y = ny; lv.contentY = ny / parent.height * lv.contentHeight } } } }
                        // Fast scroll overlay
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: false
                            propagateComposedEvents: true
                            onWheel: function(wheel) {
                                wheel.accepted = true
                                if (manageListView.contentHeight > manageListView.height) {
                                    manageListView.contentY = Math.max(0, Math.min(
                                        manageListView.contentY - wheel.angleDelta.y * 1.0,
                                        manageListView.contentHeight - manageListView.height))
                                }
                            }
                            onPressed: function(mouse) { mouse.accepted = false }
                            onReleased: function(mouse) { mouse.accepted = false }
                            onClicked: function(mouse) { mouse.accepted = false }
                        }
                    }

                }

                // Icon extraction progress pill (direct child of dialogCard — Column ignores anchors)
                Rectangle {
                    visible: addAppDialog._iconExtracting
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: Theme.spacingS
                    width: progressRow.width + Theme.spacingM * 2
                    height: 24; radius: 12
                    color: Theme.withAlpha(Theme.primary, 0.15)
                    border.color: Theme.withAlpha(Theme.primary, 0.3); border.width: 1
                    z: 5
                    Row {
                        id: progressRow
                        anchors.centerIn: parent
                        spacing: 6
                        DankIcon { anchors.verticalCenter: parent.verticalCenter; name: "refresh"; size: 12; color: Theme.primary }
                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: content._tr("Extracting icons") + " " + addAppDialog._iconExtractDone + "/" + addAppDialog._iconExtractTotal
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.primary
                        }
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 48; height: 4; radius: 2
                            color: Theme.withAlpha(Theme.primary, 0.2)
                            Rectangle {
                                anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                                width: Math.max(parent.height, parent.width * (addAppDialog._iconExtractTotal > 0 ? addAppDialog._iconExtractDone / addAppDialog._iconExtractTotal : 0))
                                height: parent.height; radius: 2
                                color: Theme.primary
                                Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutQuad } }
                            }
                        }
                    }
                }
            }
        }

        // --- In-widget Settings Dialog ---
        Rectangle {
            id: appSettingsDialog
            anchors.fill: parent
            color: "transparent"
            radius: Theme.cornerRadius; z: 100
            visible: opened || opacity > 0
            opacity: opened ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 150 } }
            property bool opened: false

            function open() { opened = true }
            function close() {
                opened = false
                var pos = settingsCard.mapToItem(launcherContainer, 0, 0)
                dissolveParticles.burst(pos.x + settingsCard.width / 2, pos.y + settingsCard.height / 2, settingsCard.width, settingsCard.height)
            }

            MouseArea { anchors.fill: parent; onClicked: appSettingsDialog.close() }

            Rectangle {
                id: settingsCard
                z: 10
                width: Math.min(300, parent.width - 20)
                height: parent.height - 16
                // Top aligns with the header settings icon instead of vertical center
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 8
                color: host.bgColor !== "" ? host.bgColor : Theme.surfaceContainer; radius: Theme.cornerRadius
                border.color: Qt.rgba(1, 1, 1, 0.06); border.width: 1; clip: true
                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true; shadowHorizontalOffset: 0; shadowVerticalOffset: 8
                    shadowBlur: 0.8; shadowColor: Qt.rgba(0, 0, 0, 0.6); shadowOpacity: 0.7
                }
                scale: appSettingsDialog.opened ? 1.0 : 0.95
                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }

                // Swallow clicks on card padding/gaps so they don't reach the dismiss overlay
                MouseArea { anchors.fill: parent }

                Column {
                    id: contentCol
                    anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
                    anchors.margins: 14; spacing: 16

                    // ── Title ──
                    Item {
                        width: parent.width; height: 26
                        // Desktop widgets entry (small icon, top-left)
                        Item {
                            width: 18; height: 18
                            anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                            DankIcon {
                                anchors.centerIn: parent
                                name: "widgets"; size: 13; color: host.fgColor
                                opacity: dmsWidgetsBtn.containsMouse ? 1.0 : 0.6
                            }
                            MouseArea {
                                id: dmsWidgetsBtn
                                anchors.fill: parent
                                hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    PopoutService.openSettingsWithTab("desktop_widgets")
                                    appSettingsDialog.close()
                                }
                            }
                        }
                        StyledText {
                            text: content._tr("Settings")
                            font.bold: true; font.pixelSize: Theme.fontSizeMedium; color: host.fgColor
                            anchors.centerIn: parent
                        }
                        Item {
                            width: 22; height: 22
                            anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                            DankIcon {
                                anchors.centerIn: parent
                                name: "close"; size: 16; color: host.fgColor
                                opacity: closeSettingsBtn.containsMouse ? 1.0 : 0.5
                            }
                            MouseArea {
                                id: closeSettingsBtn
                                anchors.fill: parent
                                hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: appSettingsDialog.close()
                            }
                        }
                    }

                    // ── Default View ──
                    Item { width: parent.width; height: 28
                        StyledText { text: content._tr("Default View"); font.pixelSize: Theme.fontSizeSmall; color: host.fgColor; anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter }
                        Row { spacing: 8; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                            Repeater {
                                model: [{ label: content._tr("Conky"), value: "conky" }, { label: content._tr("Apps"), value: "apps" }]
                                Rectangle {
                                    required property var modelData; width: 68; height: 26; radius: 7
                                    color: host.defaultView === modelData.value ? Theme.withAlpha(Theme.primary, 0.22) : Theme.withAlpha(host.fgColor, 0.08)
                                    StyledText { anchors.centerIn: parent; text: modelData.label; font.pixelSize: 11; color: host.defaultView === modelData.value ? Theme.primary : host.fgColor }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { if (host.pluginService) host.pluginService.savePluginData(host.pluginId, "defaultView", modelData.value) } }
                                }
                            }
                        }
                    }

                    // ── Background Color ──
                    Column {
                        width: parent.width
                        spacing: 6
                        StyledText { text: content._tr("Background Color"); font.pixelSize: Theme.fontSizeSmall; color: host.fgColor }
                        Flow {
                            width: parent.width
                            spacing: 6
                            Repeater {
                                // Same palette as dmsfilemanager popupColor: "" = follow theme, "custom" = color picker
                                model: ["", "#455A64", "#5D4037", "#37474F", "#2E3A4D", "#3E2A4D", "#263238", "#1E1E2E", "#14141B", "#000000"]
                                Rectangle {
                                    required property var modelData
                                    width: 22; height: 22
                                    radius: modelData === "" ? 11 : 5
                                    color: modelData === "" ? Theme.surfaceContainer : modelData
                                    border.width: host.bgColor === modelData ? 2 : 1
                                    border.color: host.bgColor === modelData ? host.fgColor : Theme.withAlpha(Theme.outline, 0.3)
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: { if (host.pluginService) host.pluginService.savePluginData(host.pluginId, "bgColor", modelData) }
                                    }
                                }
                            }
                            // Custom color picker
                            Rectangle {
                                width: 22; height: 22; radius: 5
                                color: "white"
                                border.width: 1
                                border.color: Theme.withAlpha(Theme.outline, 0.3)
                                StyledText {
                                    anchors.centerIn: parent
                                    text: "+"
                                    font.pixelSize: 15
                                    color: "red"
                                    font.bold: true
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: { content._fileDialogOpen = true; bgColorDialog.open() }
                                }
                            }
                        }
                        ColorDialog {
                            id: bgColorDialog
                            title: content._tr("Background Color")
                            selectedColor: host.bgColor !== "" ? host.bgColor : "#0a0a0f"
                            onAccepted: {
                                content._fileDialogOpen = false
                                if (host.pluginService) host.pluginService.savePluginData(host.pluginId, "bgColor", selectedColor.toString())
                            }
                            onRejected: content._fileDialogOpen = false
                        }
                    }

                    // ── Transparency ──
                    Item { width: parent.width; height: 28
                        StyledText { text: content._tr("Transparency"); font.pixelSize: Theme.fontSizeSmall; color: host.fgColor; anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter }
                        Row { spacing: 4; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                            Slider { width: 150; from: 0; to: 100; stepSize: 1; anchors.verticalCenter: parent.verticalCenter; value: Math.round(host.appLauncherBgOpacity * 100); onValueChanged: { if (host.pluginService) host.pluginService.savePluginData(host.pluginId, "backgroundOpacity", value) } }
                            StyledText { text: Math.round(host.appLauncherBgOpacity * 100) + "%"; font.pixelSize: Theme.fontSizeSmall - 1; color: host.fgColor; anchors.verticalCenter: parent.verticalCenter; width: 34; horizontalAlignment: Text.AlignRight }
                        }
                    }

                    // ── Icon Size ──
                    Item { width: parent.width; height: 28
                        StyledText { text: content._tr("Icon Size"); font.pixelSize: Theme.fontSizeSmall; color: host.fgColor; anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter }
                        Row { spacing: 4; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                            Slider { width: 150; from: 48; to: 128; stepSize: 4; anchors.verticalCenter: parent.verticalCenter; value: host.appSize; onValueChanged: { if (host.pluginService) host.pluginService.savePluginData(host.pluginId, "appSize", value) } }
                            StyledText { text: host.appSize + "px"; font.pixelSize: Theme.fontSizeSmall - 1; color: host.fgColor; anchors.verticalCenter: parent.verticalCenter; width: 34; horizontalAlignment: Text.AlignRight }
                        }
                    }

                    // ── View Mode ──
                    StyledText { text: content._tr("View Mode"); font.pixelSize: Theme.fontSizeSmall; color: host.fgColor }
                    Row { spacing: 8
                        Repeater {
                            model: [{ label: content._tr("Grid"), value: "grid" }, { label: content._tr("List"), value: "list" }, { label: content._tr("Compact"), value: "compact" }]
                            Rectangle {
                                required property var modelData; width: 64; height: 26; radius: 7
                                color: host.appViewMode === modelData.value ? Theme.withAlpha(Theme.primary, 0.22) : Theme.withAlpha(host.fgColor, 0.08)
                                StyledText { anchors.centerIn: parent; text: modelData.label; font.pixelSize: 11; color: host.appViewMode === modelData.value ? Theme.primary : host.fgColor }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { if (host.pluginService) host.pluginService.savePluginData(host.pluginId, "viewMode", modelData.value) } }
                            }
                        }
                    }

                    // ── Show Header ──
                    Item { width: parent.width; height: 28
                        StyledText { text: content._tr("Show Header"); font.pixelSize: Theme.fontSizeSmall; color: host.fgColor; anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter }
                        Row { spacing: 8; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                            Rectangle { width: 34; height: 26; radius: 6
                                color: host.appShowHeader ? Theme.withAlpha(Theme.primary, 0.22) : Theme.withAlpha(host.fgColor, 0.08)
                                StyledText { anchors.centerIn: parent; text: content._tr("On"); font.pixelSize: 11; color: host.appShowHeader ? Theme.primary : host.fgColor }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { if (host.pluginService) host.pluginService.savePluginData(host.pluginId, "showHeader", true) } }
                            }
                            Rectangle { width: 34; height: 26; radius: 6
                                color: !host.appShowHeader ? Theme.withAlpha(Theme.primary, 0.22) : Theme.withAlpha(host.fgColor, 0.08)
                                StyledText { anchors.centerIn: parent; text: content._tr("Off"); font.pixelSize: 11; color: !host.appShowHeader ? Theme.primary : host.fgColor }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { if (host.pluginService) host.pluginService.savePluginData(host.pluginId, "showHeader", false) } }
                            }
                        }
                    }

                    // ── Particles ──
                    Item { width: parent.width; height: 28
                        StyledText { text: content._tr("Particles"); font.pixelSize: Theme.fontSizeSmall; color: host.fgColor; anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter }
                        Row { spacing: 8; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                            Rectangle { width: 34; height: 26; radius: 6
                                color: host.showLauncherParticles ? Theme.withAlpha(Theme.primary, 0.22) : Theme.withAlpha(host.fgColor, 0.08)
                                StyledText { anchors.centerIn: parent; text: content._tr("On"); font.pixelSize: 11; color: host.showLauncherParticles ? Theme.primary : host.fgColor }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { if (host.pluginService) host.pluginService.savePluginData(host.pluginId, "showLauncherParticles", true) } }
                            }
                            Rectangle { width: 34; height: 26; radius: 6
                                color: !host.showLauncherParticles ? Theme.withAlpha(Theme.primary, 0.22) : Theme.withAlpha(host.fgColor, 0.08)
                                StyledText { anchors.centerIn: parent; text: content._tr("Off"); font.pixelSize: 11; color: !host.showLauncherParticles ? Theme.primary : host.fgColor }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { if (host.pluginService) host.pluginService.savePluginData(host.pluginId, "showLauncherParticles", false) } }
                            }
                        }
                    }

                    // ── Language selector ──
                    Item {
                        id: langSelector
                        width: parent.width
                        height: langDropBtn.height + 2
                        z: 10

                        property bool _langListOpen: false
                        readonly property string _currentLangLabel: {
                            for (var i = 0; i < content._launcherLangModel.length; i++) {
                                if (content._launcherLangModel[i].code === content._launcherLang)
                                    return content._launcherLangModel[i].label;
                            }
                            return content._launcherLang;
                        }

                        Rectangle {
                            id: langDropBtn
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: 28; radius: 7
                            color: langDropArea.containsMouse ? Theme.withAlpha(Theme.primary, 0.1) : Theme.withAlpha(Theme.outline, 0.08)
                            border.color: Theme.withAlpha(Theme.outline, 0.2); border.width: 1
                            Row {
                                anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 8; spacing: 4
                                StyledText {
                                    text: langSelector._currentLangLabel
                                    font.pixelSize: Theme.fontSizeSmall; color: host.fgColor
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - 24; elide: Text.ElideRight
                                }
                                DankIcon {
                                    name: langSelector._langListOpen ? "expand_less" : "expand_more"
                                    size: 16; color: Theme.surfaceVariantText; anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                            MouseArea {
                                id: langDropArea
                                anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: langSelector._langListOpen = !langSelector._langListOpen
                            }
                        }

                        Rectangle {
                            visible: langSelector._langListOpen
                            height: Math.min(176, langListView.implicitHeight + 4)
                            anchors.bottom: langDropBtn.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            radius: 6; clip: true
                            color: Theme.withAlpha(Theme.surfaceContainer, 0.98)
                            border.color: Theme.withAlpha(Theme.outline, 0.15); border.width: 1
                            Flickable {
                                anchors.fill: parent; anchors.margins: 2
                                contentHeight: langListView.implicitHeight
                                boundsBehavior: Flickable.StopAtBounds
                                interactive: contentHeight > height
                                clip: false
                                Column {
                                    id: langListView
                                    width: parent.width
                                    Repeater {
                                        model: content._launcherLangModel
                                        delegate: Rectangle {
                                            width: parent.width; height: 28; radius: 4
                                            color: content._launcherLang === modelData.code ? Theme.withAlpha(Theme.primary, 0.15) : langItemArea.containsMouse ? Theme.withAlpha(Theme.surfaceText, 0.06) : "transparent"
                                            StyledText {
                                                text: modelData.label
                                                font.pixelSize: Theme.fontSizeSmall; color: Theme.surfaceText
                                                anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: 8
                                            }
                                            MouseArea {
                                                id: langItemArea
                                                anchors.fill: parent; hoverEnabled: true;                                                     cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    if (content.host && content.host.pluginService) {
                                                        content.host.pluginService.savePluginData(content.host.pluginId, "pluginLanguage", modelData.code);
                                                        content._launcherLang = modelData.code;
                                                        content._applyLauncherLanguage(modelData.code);
                                                    }
                                                    langSelector._langListOpen = false;
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                }
            }
        }

        // Shared particle dissolve (above all dialogs)
        Canvas {
            id: dissolveParticles
            anchors.fill: parent; z: 5
            visible: true
            property var particles: []
            property real cx: 0; property real cy: 0
            property real pw: 0; property real ph: 0

            function burst(x, y, w, h) {
                cx = x; cy = y; pw = w; ph = h
                particles = []
                var count = Math.max(25, Math.floor(w * h / 1500))
                for (var i = 0; i < count; i++) {
                    var angle = Math.random() * Math.PI * 2
                    var speed = 10 + Math.random() * 50
                    var hue = Math.random()
                    particles.push({
                        x: cx + (Math.random() - 0.5) * pw * 0.9,
                        y: cy + (Math.random() - 0.5) * ph * 0.9,
                        vx: Math.cos(angle) * speed,
                        vy: Math.sin(angle) * speed - 15,
                        size: 1.5 + Math.random() * 4,
                        life: 1.0,
                        decay: 0.4 + Math.random() * 0.8,
                        hue: hue
                    })
                }
                dissolveTimer.start()
            }

            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                for (var i = 0; i < particles.length; i++) {
                    var p = particles[i]
                    if (p.life <= 0) continue
                    ctx.globalAlpha = Math.min(1, p.life) * 0.7
                    var sat = 0.3 + p.life * 0.5
                    var lit = 0.5 + p.life * 0.4
                    ctx.fillStyle = Qt.hsla(p.hue, sat, lit, 1.0)
                    ctx.beginPath()
                    ctx.arc(p.x, p.y, p.size * (0.2 + p.life * 0.8), 0, Math.PI * 2)
                    ctx.fill()
                }
            }
        }

        Timer {
            id: dissolveTimer
            interval: 16; repeat: true
            property real elapsed: 0
            onTriggered: {
                var dt = 0.016
                elapsed += dt
                var alive = 0
                for (var i = 0; i < dissolveParticles.particles.length; i++) {
                    var p = dissolveParticles.particles[i]
                    if (p.life <= 0) continue
                    p.x += p.vx * dt
                    p.y += p.vy * dt
                    p.vy += 3 * dt
                    p.life -= p.decay * dt
                    if (p.life > 0) alive++
                }
                dissolveParticles.requestPaint()
                if (alive === 0 || elapsed > 1.8) {
                    stop()
                    elapsed = 0
                    dissolveParticles.particles = []
                }
            }
        }

        // Wheel overlay for main views
        MouseArea {
            anchors.fill: parent
            hoverEnabled: false
            acceptedButtons: Qt.NoButton
            onWheel: function(wheel) {
                var target = appsGrid.visible ? appsGrid :
                             (appsList.visible ? appsList :
                             (appsCompact.visible ? appsCompact : null))
                if (target && target.contentHeight > target.height) {
                    wheel.accepted = true
                    target.contentY = Math.max(0, Math.min(
                        target.contentY - wheel.angleDelta.y,
                        target.contentHeight - target.height))
                }
            }
        }
    }

    focus: true
    Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Escape) {
            if (appSettingsDialog.opened) {
                appSettingsDialog.close()
            } else if (addAppDialog.opened) {
                addAppDialog.close()
            } else {
                host.mouseHovered = false
            }
            event.accepted = true
        }
    }
}

import QtQuick
import QtQuick.Controls
import Quickshell
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins
import "../common"

Item {
    id: content
    property Item host

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
            color: btn.containsMouse ? Theme.withAlpha(Theme.surfaceText, 0.08) : Theme.withAlpha(Theme.surfaceText, 0.03)
            border.color: Theme.withAlpha(Theme.outline, 0.15); border.width: 1
            DankIcon {
                anchors.centerIn: parent
                name: btn.iconName; size: 14; color: Theme.surfaceText
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
            name: "drag_indicator"; size: 14; color: Theme.surfaceText
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
        color: Theme.withAlpha(Theme.surfaceContainer, host.appLauncherBgOpacity)
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
                    text: I18n.tr("Applications")
                    font.bold: true
                    font.pixelSize: Theme.fontSizeMedium
                    color: Theme.surfaceText
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
                    color: Theme.withAlpha(Theme.surfaceText, 0.04)
                    border.color: searchField.activeFocus ? Theme.primary : Theme.withAlpha(Theme.outline, 0.1)
                    border.width: 1

                    DankIcon {
                        id: headerOffSearchIcon
                        name: "search"; size: 14; color: Theme.surfaceText; opacity: 0.4
                        anchors.left: parent.left; anchors.leftMargin: 10; anchors.verticalCenter: parent.verticalCenter
                    }
                    TextInput {
                        id: headerOffSearchField
                        anchors.left: headerOffSearchIcon.right; anchors.leftMargin: 6
                        anchors.right: parent.right; anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        font.pixelSize: Theme.fontSizeSmall - 1; color: Theme.surfaceText; selectByMouse: true
                        onTextChanged: host.appSearchQuery = text
                        Text {
                            text: I18n.tr("Search...")
                            font.pixelSize: Theme.fontSizeSmall - 1; color: Theme.surfaceText; opacity: 0.35
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
                            color: addAppBtn.hovered ? Theme.primary : Theme.surfaceText
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
                        color: settingsBtn.hovered ? Theme.withAlpha(Theme.surfaceText, 0.08) : Theme.withAlpha(Theme.surfaceText, 0.03)
                        border.color: Theme.withAlpha(Theme.outline, 0.15); border.width: 1
                        opacity: host.appShowHeader ? 1.0 : (settingsBtn.hovered ? 0.8 : 0.0)
                        Behavior on opacity { NumberAnimation { duration: 200 } }

                        DankIcon {
                            anchors.centerIn: parent
                            name: "settings"; size: 14; color: Theme.surfaceText
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
                        color: expanded ? Theme.withAlpha(Theme.surfaceText, 0.04) : "transparent"
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
                            name: "search"; size: 14; color: Theme.surfaceText
                            opacity: searchField.activeFocus ? 1.0 : (searchContainer.expanded ? 0.6 : 0.7)
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                        }

                        TextInput {
                            id: searchField
                            anchors.left: searchIcon.right; anchors.leftMargin: 4
                            anchors.right: clearBtn.visible ? clearBtn.left : parent.right; anchors.rightMargin: 4
                            anchors.verticalCenter: parent.verticalCenter
                            font.pixelSize: Theme.fontSizeSmall - 1; color: Theme.surfaceText; selectByMouse: true
                            visible: searchContainer.expanded
                            opacity: searchContainer.expanded ? 1.0 : 0.0
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                            onTextChanged: host.appSearchQuery = text
                            Text {
                                text: I18n.tr("Search...")
                                font.pixelSize: Theme.fontSizeSmall - 1; color: Theme.surfaceText; opacity: 0.35
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
                                name: "close"; size: 10; color: Theme.surfaceText
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
                        onClicked: {
                            if (!drag.active) {
                                if (appName === "__add__") {
                                    clearSearch(); addAppDialog.openDialog("add")
                                } else {
                                    clickLaunchAnimation.start()
                                    Quickshell.execDetached(["sh", "-c", host.cleanExec(appExec)])
                                }
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
                                iconSize: host.appIconSize
                                iconSource: appIcon
                                anchors.centerIn: parent
                                visible: appName !== "__add__"
                                scale: appCard.containsMouse ? 1.15 : 1.0
                                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
                            }
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
            text: I18n.tr("Click + to add applications")
            font.pixelSize: Theme.fontSizeSmall; color: Theme.surfaceText; opacity: 0.4
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

            function openDialog(tab) {
                activeTab = tab !== undefined ? tab : "add"
                systemAppsSearch = ""; systemSearchField.text = ""; opened = true
                rebuildAddedSet()
                if (activeTab === "add") systemSearchField.forceActiveFocus()
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
                width: Math.min(320, parent.width - 20); height: Math.min(505, parent.height - 5)
                anchors.centerIn: parent
                anchors.verticalCenterOffset: 0
                color: Theme.surfaceContainerHigh; radius: Theme.cornerRadius
                border.color: Theme.withAlpha(host.accentColor, 0.15); border.width: 1; clip: true
                scale: addAppDialog.opened ? 1.0 : 0.95
                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }

                Column {
                    anchors.fill: parent; anchors.margins: Theme.spacingS; anchors.topMargin: Theme.spacingS; anchors.bottomMargin: Theme.spacingS + 30; spacing: 8

                    Item {
                        width: parent.width; height: 24
                        StyledText {
                            text: I18n.tr("Manage")
                            font.bold: true; font.pixelSize: Theme.fontSizeMedium; color: Theme.surfaceText
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        Item {
                            width: 28; height: 28
                            anchors.right: parent.right; anchors.rightMargin: -2; anchors.verticalCenter: parent.verticalCenter

                            DankIcon {
                                anchors.centerIn: parent
                                name: "close"; size: 16; color: Theme.surfaceText
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
                        color: Theme.withAlpha(Theme.surfaceText, 0.05)
                        border.color: Theme.withAlpha(Theme.outline, 0.1); border.width: 1
                        Row {
                            anchors.fill: parent; anchors.margins: 2
                            MouseArea {
                                id: tabAddBtn; width: parent.width / 2; height: parent.height; cursorShape: Qt.PointingHandCursor
                                onClicked: addAppDialog.activeTab = "add"
                                Rectangle {
                                    anchors.fill: parent; radius: 14
                                    color: addAppDialog.activeTab === "add" ? Theme.primary : "transparent"
                                    StyledText {
                                        anchors.centerIn: parent; text: I18n.tr("Add")
                                        font.bold: addAppDialog.activeTab === "add"; font.pixelSize: Theme.fontSizeSmall
                                        color: addAppDialog.activeTab === "add" ? Theme.onPrimary : Theme.surfaceText
                                        opacity: addAppDialog.activeTab === "add" ? 1.0 : (tabAddBtn.containsMouse ? 0.9 : 0.6)
                                    }
                                }
                            }
                            MouseArea {
                                id: tabManageBtn; width: parent.width / 2; height: parent.height; cursorShape: Qt.PointingHandCursor
                                onClicked: addAppDialog.activeTab = "manage"
                                Rectangle {
                                    anchors.fill: parent; radius: 14
                                    color: addAppDialog.activeTab === "manage" ? Theme.primary : "transparent"
                                    StyledText {
                                        anchors.centerIn: parent; text: I18n.tr("Layout")
                                        font.bold: addAppDialog.activeTab === "manage"; font.pixelSize: Theme.fontSizeSmall
                                        color: addAppDialog.activeTab === "manage" ? Theme.onPrimary : Theme.surfaceText
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
                        color: Theme.withAlpha(Theme.surfaceText, 0.04)
                        border.color: systemSearchField.activeFocus ? Theme.primary : Theme.withAlpha(Theme.outline, 0.1); border.width: 1
                        DankIcon { id: sysSearchIcon; name: "search"; size: 14; color: Theme.surfaceText; opacity: 0.5; anchors.left: parent.left; anchors.leftMargin: Theme.spacingS; anchors.verticalCenter: parent.verticalCenter }
                        TextInput {
                            id: systemSearchField
                            anchors.left: sysSearchIcon.right; anchors.leftMargin: Theme.spacingXS
                            anchors.right: parent.right; anchors.rightMargin: Theme.spacingS
                            anchors.verticalCenter: parent.verticalCenter
                            font.pixelSize: Theme.fontSizeSmall; color: Theme.surfaceText; selectByMouse: true
                            onTextChanged: addAppDialog.systemAppsSearch = text
                            Text { text: I18n.tr("Search system apps..."); font.pixelSize: Theme.fontSizeSmall; color: Theme.surfaceText; opacity: 0.35; visible: systemSearchField.text === "" && !systemSearchField.activeFocus; anchors.verticalCenter: parent.verticalCenter }
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
                                color: listMouseArea.containsMouse ? Theme.withAlpha(Theme.surfaceText, 0.04) : "transparent"
                                property bool isAdded: addAppDialog.addedAppNameSet[modelData.name] === true
                                Row {
                                    anchors.fill: parent; anchors.leftMargin: Theme.spacingS; anchors.rightMargin: Theme.spacingS
                                    spacing: Theme.spacingS; anchors.verticalCenter: parent.verticalCenter
                                    AppIcon {
                                        width: 24; height: 24; iconSize: 24
                                        iconSource: modelData.icon
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    StyledText { text: modelData.name; font.pixelSize: Theme.fontSizeSmall; color: Theme.surfaceText; elide: Text.ElideRight; width: parent.width - 24 - 32 - Theme.spacingS * 2; anchors.verticalCenter: parent.verticalCenter }
                                }
                                Rectangle {
                                    width: 22; height: 22; radius: 11
                                    anchors.right: parent.right; anchors.rightMargin: Theme.spacingS + 8; anchors.verticalCenter: parent.verticalCenter
                                    color: parent.isAdded ? Theme.withAlpha(Theme.primary, 0.15) : "transparent"
                                    border.color: parent.isAdded ? Theme.primary : Theme.withAlpha(Theme.outline, 0.3); border.width: 1
                                    DankIcon { anchors.centerIn: parent; name: parent.parent.isAdded ? "done" : "add"; size: 12; color: parent.parent.isAdded ? Theme.primary : Theme.surfaceText }
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
                                color: manageItemMouseArea.containsMouse ? Theme.withAlpha(Theme.surfaceText, 0.04) : "transparent"

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
                                        size: 18; color: Theme.surfaceText
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
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    // App name
                                    StyledText {
                                        text: modelData.name
                                        font.pixelSize: Theme.fontSizeSmall; color: Theme.surfaceText
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
                                            color: delBtn.containsMouse ? Theme.error : Theme.surfaceText
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

            MouseArea { anchors.fill: parent; onClicked: {} }

            Rectangle {
                id: settingsCard
                z: 10
                width: Math.min(300, parent.width - 20)
                height: Math.min(505, parent.height - 5)
                anchors.centerIn: parent
                anchors.verticalCenterOffset: 0
                color: Theme.surfaceContainerHigh; radius: Theme.cornerRadius
                border.color: Theme.withAlpha(host.accentColor, 0.15); border.width: 1; clip: true
                scale: appSettingsDialog.opened ? 1.0 : 0.95
                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }

                Column {
                    anchors.fill: parent; anchors.margins: Theme.spacingS; anchors.topMargin: Theme.spacingS; anchors.bottomMargin: Theme.spacingS + 30; spacing: 8

                    Item {
                        width: parent.width; height: 20
                        StyledText {
                            text: I18n.tr("Settings")
                            font.bold: true; font.pixelSize: Theme.fontSizeMedium; color: Theme.surfaceText
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        Item {
                            width: 28; height: 28
                            anchors.right: parent.right; anchors.rightMargin: -2; anchors.verticalCenter: parent.verticalCenter
                            DankIcon {
                                anchors.centerIn: parent
                                name: "close"; size: 16; color: Theme.surfaceText
                                opacity: closeSettingsBtn.containsMouse ? 1.0 : 0.6
                            }
                            MouseArea {
                                id: closeSettingsBtn
                                anchors.fill: parent
                                hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: appSettingsDialog.close()
                            }
                        }
                    }

                    StyledText { text: I18n.tr("Default View"); font.pixelSize: Theme.fontSizeSmall; color: Theme.surfaceText }
                    Row {
                        spacing: 6
                        Repeater {
                            model: [{ label: I18n.tr("Conky"), value: "conky" }, { label: I18n.tr("Apps"), value: "apps" }]
                            Rectangle {
                                required property var modelData; width: 70; height: 28; radius: 6
                                color: host.defaultView === modelData.value ? Theme.primary : Theme.withAlpha(Theme.surfaceText, 0.08)
                                StyledText { anchors.centerIn: parent; text: modelData.label; font.pixelSize: 11; color: host.defaultView === modelData.value ? Theme.onPrimary : Theme.surfaceText }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { if (host.pluginService) host.pluginService.savePluginData(host.pluginId, "defaultView", modelData.value) } }
                            }
                        }
                    }

                    StyledText { text: I18n.tr("Transparency") + ": " + Math.round(host.appLauncherBgOpacity * 100) + "%"; font.pixelSize: Theme.fontSizeSmall; color: Theme.surfaceText }
                    Slider { width: parent.width; from: 0; to: 100; stepSize: 1; value: Math.round(host.appLauncherBgOpacity * 100); onValueChanged: { if (host.pluginService) host.pluginService.savePluginData(host.pluginId, "backgroundOpacity", value) } }

                    StyledText { text: I18n.tr("Icon Size") + ": " + host.appSize + "px"; font.pixelSize: Theme.fontSizeSmall; color: Theme.surfaceText }
                    Slider { width: parent.width; from: 48; to: 128; stepSize: 4; value: host.appSize; onValueChanged: { if (host.pluginService) host.pluginService.savePluginData(host.pluginId, "appSize", value) } }

                    StyledText { text: I18n.tr("View Mode"); font.pixelSize: Theme.fontSizeSmall; color: Theme.surfaceText }
                    Row {
                        spacing: 6
                        Repeater {
                            model: [{ label: I18n.tr("Grid"), value: "grid" }, { label: I18n.tr("List"), value: "list" }, { label: I18n.tr("Compact"), value: "compact" }]
                            Rectangle {
                                required property var modelData; width: 70; height: 28; radius: 6
                                color: host.appViewMode === modelData.value ? Theme.primary : Theme.withAlpha(Theme.surfaceText, 0.08)
                                StyledText { anchors.centerIn: parent; text: modelData.label; font.pixelSize: 11; color: host.appViewMode === modelData.value ? Theme.onPrimary : Theme.surfaceText }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { if (host.pluginService) host.pluginService.savePluginData(host.pluginId, "viewMode", modelData.value) } }
                            }
                        }
                    }

                    StyledText { text: I18n.tr("Show Header"); font.pixelSize: Theme.fontSizeSmall; color: Theme.surfaceText }
                    Row {
                        spacing: 6
                        Repeater {
                            model: [{ label: I18n.tr("On"), value: true }, { label: I18n.tr("Off"), value: false }]
                            Rectangle {
                                required property var modelData; width: 50; height: 28; radius: 6
                                color: host.appShowHeader === modelData.value ? Theme.primary : Theme.withAlpha(Theme.surfaceText, 0.08)
                                StyledText { anchors.centerIn: parent; text: modelData.label; font.pixelSize: 11; color: host.appShowHeader === modelData.value ? Theme.onPrimary : Theme.surfaceText }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { if (host.pluginService) host.pluginService.savePluginData(host.pluginId, "showHeader", modelData.value) } }
                            }
                        }
                    }

                    StyledText { text: I18n.tr("Particles"); font.pixelSize: Theme.fontSizeSmall; color: Theme.surfaceText }
                    Row {
                        spacing: 6
                        Repeater {
                            model: [{ label: I18n.tr("On"), value: true }, { label: I18n.tr("Off"), value: false }]
                            Rectangle {
                                required property var modelData; width: 50; height: 28; radius: 6
                                color: host.showLauncherParticles === modelData.value ? Theme.primary : Theme.withAlpha(Theme.surfaceText, 0.08)
                                StyledText { anchors.centerIn: parent; text: modelData.label; font.pixelSize: 11; color: host.showLauncherParticles === modelData.value ? Theme.onPrimary : Theme.surfaceText }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { if (host.pluginService) host.pluginService.savePluginData(host.pluginId, "showLauncherParticles", modelData.value) } }
                            }
                        }
                    }

                    Item { width: 1; height: 6 }

                    DankButton {
                        width: parent.width; height: 28
                        text: I18n.tr("Desktop Widgets")
                        iconName: "widgets"
                        iconSize: 14
                        backgroundColor: Theme.withAlpha(Theme.primary, 0.1)
                        textColor: Theme.primary
                        onClicked: {
                            PopoutService.openSettingsWithTab("desktop_widgets")
                            appSettingsDialog.close()
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

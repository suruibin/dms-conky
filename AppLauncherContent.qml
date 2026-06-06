import QtQuick
import QtQuick.Controls
import Quickshell
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

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

    ListModel { id: filteredModel }

    function clearSearch() {
        searchField.text = ""
        host.appSearchQuery = ""
        searchContainer.expanded = false
    }

    function updateFilteredModel() {
        filteredModel.clear()
        var search = host.appSearchQuery.toLowerCase().trim()
        for (var i = 0; i < host.addedApps.length; i++) {
            var app = host.addedApps[i]
            var matches = search === "" ||
                app.name.toLowerCase().indexOf(search) !== -1 ||
                (app.exec && app.exec.toLowerCase().indexOf(search) !== -1)
            if (matches) {
                filteredModel.append({
                    appName: app.name,
                    appIcon: app.icon,
                    appExec: app.exec,
                    appCategories: app.categories
                })
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

    property bool _keepVisible: false

    property bool _hw: host.mouseHovered
    on_HwChanged: {
        if (!host.mouseHovered) {
            var hasDialog = addAppDialog.opened || appSettingsDialog.opened
            clearSearch()
            addAppDialog.close()
            appSettingsDialog.close()
            if (hasDialog) {
                _keepVisible = true
                keepVisibleTimer.start()
            }
        } else {
            _keepVisible = false
            content.forceActiveFocus()
        }
    }

    Timer {
        id: keepVisibleTimer
        interval: 2200; repeat: false
        onTriggered: _keepVisible = false
    }

    property var _aw: host.addedApps
    on_AwChanged: updateFilteredModel()

    // Calculate which app is hovered (JS-based, works with Qt 5 global hover)
    function gridHoveredIndex() {
        if (!host.mouseHovered || !appsGrid.visible || filteredModel.count === 0) return -1
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
        if (!host.mouseHovered || !appsList.visible || filteredModel.count === 0) return -1
        var pos = appsList.mapFromItem(host, host.hoverMouseX, host.hoverMouseY)
        if (pos.y < 0 || pos.y >= appsList.height) return -1
        var itemH = Math.round(36 * (host.appSize / 88.0)) + appsList.spacing
        var idx = Math.floor((pos.y + appsList.contentY) / itemH)
        return (idx >= 0 && idx < filteredModel.count) ? idx : -1
    }
    function compactHoveredIndex() {
        if (!host.mouseHovered || !appsCompact.visible || filteredModel.count === 0) return -1
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

    readonly property int gridHoverIdx: host.appViewMode === "grid" ? gridHoveredIndex() : -1
    readonly property int listHoverIdx: host.appViewMode === "list" ? listHoveredIndex() : -1
    readonly property int compactHoverIdx: host.appViewMode === "compact" ? compactHoveredIndex() : -1

    // ============================================
    // APP LAUNCHER VIEW (visible when mouse hovers)
    // ============================================
    Rectangle {
        id: launcherContainer
        visible: host.mouseHovered
        anchors.fill: parent
        color: Theme.withAlpha(Theme.surfaceContainer, host.appLauncherBgOpacity)
        radius: Theme.cornerRadius
        border.color: host.appEditMode ? Theme.primary : Theme.withAlpha(Theme.outline, 0.15)
        border.width: host.appEditMode ? 2 : 1
        clip: true

        Column {
            anchors.fill: parent
            anchors.margins: Theme.spacingM
            spacing: host.appShowHeader ? Theme.spacingS : 0

            // Header
            Item {
                width: parent.width
                height: host.appShowHeader ? 24 : 0
                visible: host.appShowHeader

                StyledText {
                    text: I18n.tr("Applications")
                    font.bold: true
                    font.pixelSize: Theme.fontSizeMedium
                    color: Theme.surfaceText
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    visible: !searchContainer.expanded
                }

                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.spacingS
                    height: parent.height

                    Rectangle {
                        id: searchContainer
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
                        iconName: "add"
                        onClicked: {
                            clearSearch()
                            addAppDialog.openDialog("add")
                        }
                    }

                    ToolButton {
                        iconName: "edit"
                        onClicked: {
                            clearSearch()
                            addAppDialog.openDialog("manage")
                        }
                    }

                    ToolButton {
                        iconName: "settings"
                        onClicked: {
                            clearSearch()
                            appSettingsDialog.open()
                        }
                    }
                }
            }

            // Grid View
            GridView {
                id: appsGrid
                width: parent.width
                height: parent.height - (host.appShowHeader ? (24 + Theme.spacingS * 2) : 0)
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
                        drag.target: host.appSearchQuery === "" ? gridDelegateItem : null
                        drag.axis: Drag.XAndYAxis
                        onPressed: _dragIdx = index
                        onClicked: {
                            if (!drag.active) {
                                clickLaunchAnimation.start()
                                Quickshell.execDetached(["sh", "-c", host.cleanExec(appExec)])
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

                        // Frosted glass card on hover
                        Rectangle {
                            anchors.fill: parent
                            radius: Math.round(Theme.cornerRadius / 2)
                            color: "#30ffffff"
                            border.color: "#18ffffff"
                            border.width: 1
                            opacity: (index === gridHoverIdx) ? 1.0 : 0.0
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
                            AppIcon {
                                iconSize: host.appIconSize
                                iconSource: appIcon
                                anchors.centerIn: parent
                                scale: appCard.containsMouse ? 1.08 : 1.0
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
                height: parent.height - (host.appShowHeader ? (24 + Theme.spacingS * 2) : 0)
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

                    Drag.active: listDragHandle.drag.active
                    Drag.source: listWrapper
                    Drag.hotSpot.x: width / 2
                    Drag.hotSpot.y: height / 2

                    states: State {
                        when: listDragHandle.drag.active
                        ParentChange { target: listWrapper; parent: appsList.contentItem }
                    }

                    AppRowDelegate {
                        anchors.fill: parent
                        widget: host
                        iconFactor: 20
                        fontSize: Theme.fontSizeSmall
                        hoveredIdx: listHoverIdx
                    }

                    // Drag grip on top of AppRowDelegate (z:10 ensures event priority)
                    Item {
                        z: 10
                        width: 22; height: parent.height
                        anchors { left: parent.left; leftMargin: 2; verticalCenter: parent.verticalCenter }
                        visible: host.appSearchQuery === ""

                        DankIcon {
                            anchors.centerIn: parent
                            name: "drag_indicator"
                            size: 14; color: Theme.surfaceText
                            opacity: dragHandle.containsMouse || dragHandle.drag.active ? 0.6 : 0.1
                        }

                        MouseArea {
                            id: dragHandle
                            anchors.fill: parent
                            hoverEnabled: true
                            preventStealing: true
                            drag.target: listWrapper
                            drag.axis: Drag.YAxis
                            cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                            onPressed: _dragIdx = index
                            onReleased: {
                                if (drag.active) {
                                    var toIdx = Math.round(listWrapper.y / (listWrapper.height + appsList.spacing))
                                    toIdx = Math.max(0, Math.min(toIdx, host.addedApps.length - 1))
                                    if (toIdx !== _dragIdx) host.moveAppToIndex(_dragIdx, toIdx)
                                }
                            }
                        }
                    }
                }
            }

            // Compact View
            GridView {
                id: appsCompact
                width: parent.width
                height: parent.height - (host.appShowHeader ? (24 + Theme.spacingS * 2) : 0)
                clip: true; boundsBehavior: Flickable.StopAtBounds
                visible: host.appViewMode === "compact"
                cellWidth: Math.floor(width / Math.max(2, Math.floor(width / 130)))
                cellHeight: Math.round(30 * (host.appSize / 88.0)); model: filteredModel
                add: Transition { NumberAnimation { properties: "opacity,scale"; from: 0; to: 1.0; duration: 200 } }
                remove: Transition { NumberAnimation { properties: "opacity,scale"; to: 0; duration: 150 } }
                delegate: AppRowDelegate {
                    width: appsCompact.cellWidth
                    height: appsCompact.cellHeight
                    widget: host
                    iconFactor: 16
                    fontSize: Theme.fontSizeSmall - 1
                    hoveredIdx: compactHoverIdx
                }
            }
        }

        // Wheel speed overlay (hoverEnabled: false so delegates get hover)
        MouseArea {
            anchors.fill: parent
            hoverEnabled: false
            acceptedButtons: Qt.NoButton
            onWheel: function(wheel) {
                wheel.accepted = true
                var target = appsGrid.visible ? appsGrid :
                             (appsList.visible ? appsList :
                             (appsCompact.visible ? appsCompact : null))
                if (target && target.contentHeight > target.height) {
                    target.contentY = Math.max(0, Math.min(
                        target.contentY - wheel.angleDelta.y * 4,
                        target.contentHeight - target.height))
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
            color: Theme.withAlpha(Theme.surfaceContainerHigh, 0.35)
            radius: Theme.cornerRadius; z: 100
            visible: opened || opacity > 0
            opacity: opened ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 150 } }
            property bool opened: false
            property var systemAppsList: []
            property string systemAppsSearch: ""
            property string activeTab: "add"
            property var filteredSystemApps: []

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
                if (activeTab === "add") systemSearchField.forceActiveFocus()
                if (systemAppsList.length === 0) {
                    var allEntries = DesktopEntries.applications.values
                    var apps = []
                    for (var i = 0; i < allEntries.length; i++) {
                        var app = allEntries[i]
                        if (app && !app.noDisplay) {
                            apps.push({ name: app.name || "", exec: host.cleanExec(app.execString || (app.command ? app.command.join(" ") : "")), icon: app.icon || "" })
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
                width: Math.min(320, parent.width - 20); height: Math.min(400, parent.height - 20)
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -20
                color: Theme.surfaceContainer; radius: Theme.cornerRadius
                border.color: Theme.withAlpha(Theme.outline, 0.15); border.width: 1; clip: true
                scale: addAppDialog.opened ? 1.0 : 0.95
                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }

                Column {
                    anchors.fill: parent; anchors.margins: Theme.spacingM; spacing: Theme.spacingS

                    Item {
                        width: parent.width; height: 24
                        StyledText {
                            text: I18n.tr("Applications")
                            font.bold: true; font.pixelSize: Theme.fontSizeMedium; color: Theme.surfaceText
                            anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
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
                    ListView {
                        visible: addAppDialog.activeTab === "add"
                        width: parent.width
                        height: dialogCard.height - Theme.spacingM * 2 - 24 - 32 - 32 - Theme.spacingS * 3
                        clip: true; spacing: 2; boundsBehavior: Flickable.StopAtBounds
                        model: addAppDialog.filteredSystemApps
                        delegate: Rectangle {
                            width: parent.width; height: 38
                            radius: Math.max(2, Math.round(Theme.cornerRadius / 2) - 2)
                            color: listMouseArea.containsMouse ? Theme.withAlpha(Theme.surfaceText, 0.04) : "transparent"
                            property bool isAdded: host.addedApps.some(function(a) { return a.name === modelData.name })
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
                                anchors.right: parent.right; anchors.rightMargin: Theme.spacingS; anchors.verticalCenter: parent.verticalCenter
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

                    // Manage list (with drag reorder)
                    ListView {
                        id: manageListView
                        visible: addAppDialog.activeTab === "manage"
                        width: parent.width
                        height: dialogCard.height - Theme.spacingM * 2 - 24 - 32 - Theme.spacingS * 2
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
                }
            }
        }

        // --- In-widget Settings Dialog ---
        Rectangle {
            id: appSettingsDialog
            anchors.fill: parent
            color: Theme.withAlpha(Theme.surfaceContainerHigh, 0.35)
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
                height: Math.min(290, parent.height - 20)
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 40
                color: Theme.surfaceContainer; radius: Theme.cornerRadius
                border.color: Theme.withAlpha(Theme.outline, 0.15); border.width: 1; clip: true
                scale: appSettingsDialog.opened ? 1.0 : 0.95
                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }

                Column {
                    anchors.fill: parent; anchors.margins: Theme.spacingM; spacing: Theme.spacingS

                    Item {
                        width: parent.width; height: 24
                        StyledText {
                            text: I18n.tr("Settings")
                            font.bold: true; font.pixelSize: Theme.fontSizeMedium; color: Theme.surfaceText
                            anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
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

                    StyledText {
                        text: I18n.tr("Transparency") + ": " + Math.round(host.appLauncherBgOpacity * 100) + "%"
                        font.pixelSize: Theme.fontSizeSmall; color: Theme.surfaceText
                    }
                    Slider {
                        width: parent.width; from: 0; to: 100; stepSize: 1
                        value: Math.round(host.appLauncherBgOpacity * 100)
                        onValueChanged: { if (host.pluginService) host.pluginService.savePluginData(host.pluginId, "backgroundOpacity", value) }
                    }

                    Item { width: 1; height: Theme.spacingS }

                    StyledText {
                        text: I18n.tr("Icon Size") + ": " + host.appSize + "px"
                        font.pixelSize: Theme.fontSizeSmall; color: Theme.surfaceText
                    }
                    Slider {
                        width: parent.width; from: 48; to: 128; stepSize: 4
                        value: host.appSize
                        onValueChanged: host.setData("appSize", value)
                    }

                    Item { width: 1; height: Theme.spacingS }

                    StyledText {
                        text: I18n.tr("View Mode")
                        font.pixelSize: Theme.fontSizeSmall; color: Theme.surfaceText
                    }
                    Row {
                        spacing: 6
                        Repeater {
                            model: [
                                { label: I18n.tr("Grid"), value: "grid" },
                                { label: I18n.tr("List"), value: "list" },
                                { label: I18n.tr("Compact"), value: "compact" }
                            ]
                            Rectangle {
                                required property var modelData
                                width: 70; height: 28; radius: 6
                                color: host.appViewMode === modelData.value ? Theme.primary : Theme.withAlpha(Theme.surfaceText, 0.08)
                                StyledText {
                                    anchors.centerIn: parent; text: modelData.label; font.pixelSize: 11
                                    color: host.appViewMode === modelData.value ? Theme.onPrimary : Theme.surfaceText
                                }
                                MouseArea {
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    onClicked: { if (host.pluginService) host.pluginService.savePluginData(host.pluginId, "viewMode", modelData.value) }
                                }
                            }
                        }
                    }

                    Item { width: 1; height: Theme.spacingS }

                    StyledText {
                        text: I18n.tr("Show Header")
                        font.pixelSize: Theme.fontSizeSmall; color: Theme.surfaceText
                    }
                    Row {
                        spacing: 6
                        Repeater {
                            model: [
                                { label: I18n.tr("On"), value: true },
                                { label: I18n.tr("Off"), value: false }
                            ]
                            Rectangle {
                                required property var modelData
                                width: 50; height: 28; radius: 6
                                color: host.appShowHeader === modelData.value ? Theme.primary : Theme.withAlpha(Theme.surfaceText, 0.08)
                                StyledText {
                                    anchors.centerIn: parent; text: modelData.label; font.pixelSize: 11
                                    color: host.appShowHeader === modelData.value ? Theme.onPrimary : Theme.surfaceText
                                }
                                MouseArea {
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    onClicked: { if (host.pluginService) host.pluginService.savePluginData(host.pluginId, "showHeader", modelData.value) }
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

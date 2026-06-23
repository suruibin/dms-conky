import QtQuick
import QtQuick.Controls
import qs.Common
import qs.Widgets
import qs.Modules.Plugins
import Quickshell.Io

PluginSettings {
    id: root
    pluginId: "dmsconky"

    // ── Settings I18n (loaded from translations/i18n/*.json via FileView) ─────
    property string _settingsLang: root.loadValue("pluginLanguage", "system")
    on_SettingsLangChanged: _applySettingsI18n(_settingsLang)
    property var _settingsI18nMap: ({})
    property int _settingsI18nToken: 0

    FileView {
        id: settingsI18nLoader
        onLoaded: {
            try {
                root._settingsI18nMap = JSON.parse(text());
                root._settingsI18nToken++;
                console.info("DmsConky Settings: loaded translations for", root._settingsLang);
            } catch (e) {
                console.warn("DmsConky Settings: error parsing i18n:", e);
            }
        }
        onLoadFailed: error => {
            console.warn("DmsConky Settings: failed to load i18n:", error);
            if (root._settingsLang !== "en") {
                settingsI18nLoader.path = Qt.resolvedUrl("translations/i18n/en.json");
            }
        }
    }

    function _applySettingsI18n(locale) {
        if (locale === "System Default" || locale === "") locale = "system";
        if (!locale) { _settingsI18nMap = {}; return; }
        if (locale === "system") {
            var sys = Qt.locale().name;
            var parts = sys.split("_");
            sys = parts.length > 0 ? parts[0] : "en";
            settingsI18nLoader.path = Qt.resolvedUrl("translations/i18n/" + sys + ".json");
        } else {
            settingsI18nLoader.path = Qt.resolvedUrl("translations/i18n/" + locale + ".json");
        }
    }

    // Poll for language changes
    Timer {
        running: true
        repeat: true
        interval: 800
        onTriggered: {
            var lang = root.loadValue("pluginLanguage", "system")
            if (lang !== root._settingsLang)
                root._settingsLang = lang
        }
    }

    // ── Exposed translated properties (direct property bindings for reliable re-eval) ──
    readonly property string _trModule:    { _settingsI18nToken; return _settingsI18nMap["Module"]     || I18n.tr("Module") }
    readonly property string _trClock:     { _settingsI18nToken; return _settingsI18nMap["Clock"]      || I18n.tr("Clock") }
    readonly property string _trWeather:   { _settingsI18nToken; return _settingsI18nMap["Weather"]     || I18n.tr("Weather") }
    readonly property string _trNetwork:   { _settingsI18nToken; return _settingsI18nMap["Network"]     || I18n.tr("Network") }
    readonly property string _trMusic:     { _settingsI18nToken; return _settingsI18nMap["Music"]       || I18n.tr("Music") }
    readonly property string _trStorage:   { _settingsI18nToken; return _settingsI18nMap["Storage"]     || I18n.tr("Storage") }
    readonly property string _trRotatingAlbum: { _settingsI18nToken; return _settingsI18nMap["Rotating Album"] || I18n.tr("Rotating Album") }
    readonly property string _trDefaultView:   { _settingsI18nToken; return _settingsI18nMap["Default View"]   || I18n.tr("Default View") }
    readonly property string _trConky:    { _settingsI18nToken; return _settingsI18nMap["Conky"]        || I18n.tr("Conky") }
    readonly property string _trApps:     { _settingsI18nToken; return _settingsI18nMap["Apps"]         || I18n.tr("Apps") }
    readonly property string _trColors:   { _settingsI18nToken; return _settingsI18nMap["Colors"]       || I18n.tr("Colors") }
    readonly property string _trPrimaryColor:   { _settingsI18nToken; return _settingsI18nMap["Primary Color"]   || I18n.tr("Primary Color") }
    readonly property string _trSecondaryColor: { _settingsI18nToken; return _settingsI18nMap["Secondary Color"] || I18n.tr("Secondary Color") }
    readonly property string _trClockColors:    { _settingsI18nToken; return _settingsI18nMap["Clock Colors"]    || I18n.tr("Clock Colors") }
    readonly property string _trHour:    { _settingsI18nToken; return _settingsI18nMap["Hour"]   || I18n.tr("Hour") }
    readonly property string _trMinute:  { _settingsI18nToken; return _settingsI18nMap["Minute"] || I18n.tr("Minute") }
    readonly property string _trSecond:  { _settingsI18nToken; return _settingsI18nMap["Second"] || I18n.tr("Second") }
    readonly property string _trColon:   { _settingsI18nToken; return _settingsI18nMap["Colon"]  || I18n.tr("Colon") }
    readonly property string _trWeekday: { _settingsI18nToken; return _settingsI18nMap["Weekday"]|| I18n.tr("Weekday") }
    readonly property string _trDay:     { _settingsI18nToken; return _settingsI18nMap["Day"]    || I18n.tr("Day") }
    readonly property string _trMonth:   { _settingsI18nToken; return _settingsI18nMap["Month"]  || I18n.tr("Month") }
    readonly property string _trRingGaugeColors:{ _settingsI18nToken; return _settingsI18nMap["Ring Gauge Colors"] || I18n.tr("Ring Gauge Colors") }
    readonly property string _trCPU:     { _settingsI18nToken; return _settingsI18nMap["CPU"]     || I18n.tr("CPU") }
    readonly property string _trMemory:  { _settingsI18nToken; return _settingsI18nMap["Memory"]  || I18n.tr("Memory") }
    readonly property string _trBattery: { _settingsI18nToken; return _settingsI18nMap["Battery"] || I18n.tr("Battery") }
    readonly property string _trAC:      { _settingsI18nToken; return _settingsI18nMap["AC"]      || I18n.tr("AC") }
    readonly property string _trTemp:    { _settingsI18nToken; return _settingsI18nMap["Temp"]    || I18n.tr("Temp") }
    readonly property string _trBg:      { _settingsI18nToken; return _settingsI18nMap["Bg"]      || I18n.tr("Bg") }
    readonly property string _trDisplay: { _settingsI18nToken; return _settingsI18nMap["Display"] || I18n.tr("Display") }
    readonly property string _trTransparency: { _settingsI18nToken; return _settingsI18nMap["Transparency"] || I18n.tr("Transparency") }
    readonly property string _trWidgetSize:   { _settingsI18nToken; return _settingsI18nMap["Widget Size"]   || I18n.tr("Widget Size") }
    readonly property string _trIconSize:     { _settingsI18nToken; return _settingsI18nMap["Icon Size"]     || I18n.tr("Icon Size") }
    readonly property string _trMusicPlayer:  { _settingsI18nToken; return _settingsI18nMap["Music Player"]  || I18n.tr("Music Player") }
    readonly property string _trParticles:    { _settingsI18nToken; return _settingsI18nMap["Particles"]     || I18n.tr("Particles") }
    readonly property string _trEnable:       { _settingsI18nToken; return _settingsI18nMap["Enable"]        || I18n.tr("Enable") }
    readonly property string _trStyle:        { _settingsI18nToken; return _settingsI18nMap["Style"]         || I18n.tr("Style") }
    readonly property string _trOpacity:      { _settingsI18nToken; return _settingsI18nMap["Opacity"]       || I18n.tr("Opacity") }
    readonly property string _trCount:        { _settingsI18nToken; return _settingsI18nMap["Count"]         || I18n.tr("Count") }
    readonly property string _trSize:         { _settingsI18nToken; return _settingsI18nMap["Size"]          || I18n.tr("Size") }
    readonly property string _trLanguage:     { _settingsI18nToken; return _settingsI18nMap["Language"]      || I18n.tr("Language") }
    readonly property string _trSystemDefault:{ _settingsI18nToken; return _settingsI18nMap["System Default"]|| I18n.tr("System Default") }
    readonly property string _trAbout:        { _settingsI18nToken; return _settingsI18nMap["About"]         || I18n.tr("About") }
    readonly property string _trGitHub:       { _settingsI18nToken; return _settingsI18nMap["GitHub"]        || I18n.tr("GitHub") }
    readonly property string _trBugRequest:   { _settingsI18nToken; return _settingsI18nMap["Found a bug or have a feature request? Join us on GitHub."] || I18n.tr("Found a bug or have a feature request? Join us on GitHub.") }
    readonly property string _trGuiHint:      { _settingsI18nToken; return _settingsI18nMap["GUI: /path/to/app | Terminal: alacritty -e /path/to/app | Kitty: kitty /path/to/app | Konsole: konsole -e /path/to/app"] || I18n.tr("GUI: /path/to/app | Terminal: alacritty -e /path/to/app | Kitty: kitty /path/to/app | Konsole: konsole -e /path/to/app") }

    function saveAndPersist(key, value) {
        root.saveValue(key, value)
        SettingsData.setPluginSetting(root.pluginId, key, value)
        SettingsData.savePluginSettings()
    }

    Column {
        width: parent.width
        spacing: 0

        StyledText {
            text: root._trModule
            font.pixelSize: Theme.fontSizeMedium
            font.bold: true
            color: Theme.surfaceText
        }
        Item { width: 1; height: Theme.spacingS }

        StyledRect {
            width: parent.width
            radius: Theme.cornerRadius
            color: Theme.surfaceContainer
            height: moduleCol.implicitHeight + Theme.spacingL * 2

            Column {
                id: moduleCol
                width: parent.width - Theme.spacingL * 2
                anchors.centerIn: parent
                spacing: Theme.spacingS

                DankToggle {
                    width: parent.width
                    text: root._trClock
                    checked: root.loadValue("showClock", true)
                    onToggled: c => root.saveAndPersist("showClock", c)
                }
                DankToggle {
                    width: parent.width
                    text: root._trWeather
                    checked: root.loadValue("showWeather", true)
                    onToggled: c => root.saveAndPersist("showWeather", c)
                }
                DankToggle {
                    width: parent.width
                    text: root._trNetwork
                    checked: root.loadValue("showNetwork", true)
                    onToggled: c => root.saveAndPersist("showNetwork", c)
                }
                DankToggle {
                    width: parent.width
                    text: root._trMusic
                    checked: root.loadValue("showMusic", true)
                    onToggled: c => root.saveAndPersist("showMusic", c)
                }
                DankToggle {
                    width: parent.width
                    text: root._trStorage
                    checked: root.loadValue("showStorage", true)
                    onToggled: c => root.saveAndPersist("showStorage", c)
                }
                DankToggle {
                    width: parent.width
                    text: root._trRotatingAlbum
                    checked: root.loadValue("showRotatingAlbum", true)
                    onToggled: c => root.saveAndPersist("showRotatingAlbum", c)
                }
            }
        }

        Item { width: 1; height: Theme.spacingS }

        StyledText {
            text: root._trDefaultView
            font.pixelSize: Theme.fontSizeMedium
            font.bold: true
            color: Theme.surfaceText
        }
        Item { width: 1; height: Theme.spacingS }

        StyledRect {
            width: parent.width
            radius: Theme.cornerRadius
            color: Theme.surfaceContainer
            height: defaultViewRow.implicitHeight + Theme.spacingL * 2

            Row {
                id: defaultViewRow
                spacing: 6
                anchors.centerIn: parent
                Repeater {
                    model: [
                        { label: root._trConky, value: "conky" },
                        { label: root._trApps, value: "apps" }
                    ]
                    Rectangle {
                        required property var modelData
                        width: 70; height: 28; radius: 6
                        color: root.loadValue("defaultView", "conky") === modelData.value ? Theme.primary : Theme.withAlpha(Theme.surfaceText, 0.08)
                        StyledText {
                            anchors.centerIn: parent; text: modelData.label; font.pixelSize: 11
                            color: root.loadValue("defaultView", "conky") === modelData.value ? Theme.onPrimary : Theme.surfaceText
                        }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: root.saveAndPersist("defaultView", modelData.value)
                        }
                    }
                }
            }
        }

        Item { width: 1; height: Theme.spacingM }

        component ColorPicker: Column {
            width: parent.width
            property string title: ""
            property string settingKey: ""
            property string defaultColor: "#7C3AED"
            property bool compact: false

            StyledText {
                text: title
                font.pixelSize: compact ? Theme.fontSizeSmall : Theme.fontSizeMedium
                font.bold: !compact
                color: compact ? Theme.surfaceVariantText : Theme.surfaceText
            }
            Item { width: 1; height: compact ? 2 : Theme.spacingS }

            Flow {
                width: parent.width
                spacing: compact ? 4 : 6
                Repeater {
                    model: ["#5105DB", "#7C3AED", "#8B5CF6", "#A855F7", "#6366F1", "#2563EB", "#3B82F6", "#0891B2", "#06B6D4", "#14B8A6", "#059669", "#10B981", "#22C55E", "#EAB308", "#F59E0B", "#D97706", "#F97316", "#DC2626", "#EF4444", "#DB2777", "#EC4899", "#D946EF", "#ffffff", "#94A3B8", "#64748B", "#334155"]
                    Rectangle {
                        required property var modelData
                        property string c: modelData
                        width: compact ? 22 : 26; height: compact ? 22 : 26; radius: compact ? 11 : 13
                        color: c
                        border.width: root.loadValue(settingKey, defaultColor) === c ? (compact ? 2 : 3) : 0
                        border.color: Theme.surfaceText
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.saveAndPersist(settingKey, parent.c)
                        }
                    }
                }
            }
        }

        // ---- Colors ----
        StyledText {
            text: root._trColors
            font.pixelSize: Theme.fontSizeMedium
            font.bold: true
            color: Theme.surfaceText
        }
        Item { width: 1; height: Theme.spacingS }

        StyledRect {
            width: parent.width
            radius: Theme.cornerRadius
            color: Theme.surfaceContainer
            height: colorCol.implicitHeight + Theme.spacingL * 2

            Column {
                id: colorCol
                width: parent.width - Theme.spacingL * 2
                anchors.centerIn: parent
                spacing: Theme.spacingM

                ColorPicker { compact: true; title: root._trPrimaryColor; settingKey: "accentColor"; defaultColor: "#7C3AED" }
                ColorPicker { compact: true; title: root._trSecondaryColor; settingKey: "accent2Color"; defaultColor: "#D97706" }
            }
        }

        Item { width: 1; height: Theme.spacingM }

        // Generic color-row component: label + color picker (auto-wrap)
        component ColorRow: Flow {
            spacing: 2
            property string label: ""
            property string settingKey: ""
            property string defaultColor: "#f0f0f0"

            StyledText {
                text: label
                width: 48
                font.pixelSize: 11; color: Theme.surfaceVariantText
            }
            Repeater {
                model: ["#f0f0f0", "#F43F5E", "#EF4444", "#DC2626", "#F97316", "#EA580C", "#EAB308", "#84CC16", "#22C55E", "#10B981", "#14B8A6", "#06B6D4", "#0EA5E9", "#3B82F6", "#6366F1", "#8B5CF6", "#A855F7", "#D946EF", "#EC4899", "#94A3B8"]
                Rectangle {
                    required property var modelData
                    property string c: modelData
                    width: 18; height: 18; radius: 9; color: c
                    border.width: root.loadValue(settingKey, defaultColor) === c ? 2 : 0
                    border.color: Theme.surfaceText
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.saveAndPersist(settingKey, parent.c)
                    }
                }
            }
        }

        // ---- Clock / Date Colors ----
        StyledText {
            text: root._trClockColors
            font.pixelSize: Theme.fontSizeMedium
            font.bold: true
            color: Theme.surfaceText
        }
        Item { width: 1; height: Theme.spacingS }

        StyledRect {
            width: parent.width
            radius: Theme.cornerRadius
            color: Theme.surfaceContainer
            height: clockCol.implicitHeight + Theme.spacingL * 2

            Column {
                id: clockCol
                width: parent.width - Theme.spacingL * 2
                anchors.centerIn: parent
                spacing: 2

                ColorRow { label: root._trHour;    settingKey: "clockHourColor";    defaultColor: "#6366F1" }
                ColorRow { label: root._trMinute;  settingKey: "clockMinuteColor";  defaultColor: "#F97316" }
                ColorRow { label: root._trSecond;  settingKey: "clockSecondColor";  defaultColor: "#EC4899" }
                ColorRow { label: root._trColon;   settingKey: "clockColonColor";   defaultColor: "#3B82F6" }
                ColorRow { label: root._trWeekday; settingKey: "dateWeekdayColor";  defaultColor: "#EAB308" }
                ColorRow { label: root._trDay;     settingKey: "dateDayColor";      defaultColor: "#06B6D4" }
                ColorRow { label: root._trMonth;   settingKey: "dateMonthColor";    defaultColor: "#EC4899" }
            }
        }

        Item { width: 1; height: Theme.spacingM }

        // ---- Ring Gauge Colors ----
        StyledText {
            text: root._trRingGaugeColors
            font.pixelSize: Theme.fontSizeMedium
            font.bold: true
            color: Theme.surfaceText
        }
        Item { width: 1; height: Theme.spacingS }

        StyledRect {
            width: parent.width
            radius: Theme.cornerRadius
            color: Theme.surfaceContainer
            height: ringCol.implicitHeight + Theme.spacingL * 2

            Column {
                id: ringCol
                width: parent.width - Theme.spacingL * 2
                anchors.centerIn: parent
                spacing: 2

                ColorRow { label: root._trCPU;     settingKey: "cpuGaugeColor";     defaultColor: "#DC2626" }
                ColorRow { label: root._trMemory;  settingKey: "memGaugeColor";     defaultColor: "#EAB308" }
                ColorRow { label: root._trBattery; settingKey: "batteryGaugeColor"; defaultColor: "#22C55E" }
                ColorRow { label: root._trAC;      settingKey: "batteryAcGaugeColor"; defaultColor: "#22C55E" }
                ColorRow { label: root._trTemp;    settingKey: "tempGaugeColor";    defaultColor: "#EF4444" }
                ColorRow { label: root._trBg;      settingKey: "ringBgColor";       defaultColor: "#94A3B8" }
            }
        }

        Item { width: 1; height: Theme.spacingM }

        // ---- Display ----
        StyledText {
            text: root._trDisplay
            font.pixelSize: Theme.fontSizeMedium
            font.bold: true
            color: Theme.surfaceText
        }
        Item { width: 1; height: Theme.spacingS }

        StyledRect {
            width: parent.width
            radius: Theme.cornerRadius
            color: Theme.surfaceContainer
            height: displayCol.implicitHeight + Theme.spacingL * 2

            Column {
                id: displayCol
                width: parent.width - Theme.spacingL * 2
                anchors.centerIn: parent
                spacing: Theme.spacingS

                StyledText {
                    text: root._trTransparency + ": " + Math.round(root.loadValue("bgOpacity", 0.0) * 100) + "%"
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                }
                Slider {
                    width: parent.width
                    from: 0.0; to: 1.0; stepSize: 0.01
                    value: root.loadValue("bgOpacity", 0.0)
                    onValueChanged: root.saveAndPersist("bgOpacity", value)
                }

                StyledText {
                    text: root._trWidgetSize + ": " + root.loadValue("widgetWidth", 298) + " × " + root.loadValue("widgetHeight", 522)
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                }
                Slider {
                    width: parent.width
                    from: 280; to: 600; stepSize: 10
                    value: root.loadValue("widgetWidth", 298)
                    onValueChanged: root.saveAndPersist("widgetWidth", value)
                }
                Slider {
                    width: parent.width
                    from: 500; to: 1200; stepSize: 10
                    value: root.loadValue("widgetHeight", 522)
                    onValueChanged: root.saveAndPersist("widgetHeight", value)
                }

                StyledText {
                    text: root._trIconSize + ": " + root.loadValue("appSize", 80) + "px"
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                }
                Slider {
                    width: parent.width
                    from: 48; to: 128; stepSize: 4
                    value: root.loadValue("appSize", 80)
                    onValueChanged: root.saveAndPersist("appSize", value)
                }

                Item { width: 1; height: 4 }

                StyledText {
                    text: root._trMusicPlayer
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                }
                StyledRect {
                    width: parent.width; height: 28; radius: 6
                    color: Theme.withAlpha(Theme.surfaceText, 0.04)
                    border.color: musicPathField.activeFocus ? Theme.primary : Theme.withAlpha(Theme.outline, 0.1)
                    border.width: 1
                    TextInput {
                        id: musicPathField
                        anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        font.pixelSize: Theme.fontSizeSmall; color: Theme.surfaceText
                        text: root.loadValue("musicPlayerPath", "/usr/local/bin/splayer")
                        selectByMouse: true
                        onTextChanged: root.saveAndPersist("musicPlayerPath", text)
                    }
                }
                StyledText {
                    text: root._trGuiHint
                    font.pixelSize: Theme.fontSizeSmall; color: "#3B82F6"
                    wrapMode: Text.Wrap; width: parent.width
                }
            }
        }

        Item { width: 1; height: Theme.spacingM }

        // ---- Particles ----
        StyledText {
            text: root._trParticles
            font.pixelSize: Theme.fontSizeMedium
            font.bold: true
            color: Theme.surfaceText
        }
        Item { width: 1; height: Theme.spacingS }

        StyledRect {
            width: parent.width
            radius: Theme.cornerRadius
            color: Theme.surfaceContainer
            height: particleCol.implicitHeight + Theme.spacingL * 2

            Column {
                id: particleCol
                width: parent.width - Theme.spacingL * 2
                anchors.centerIn: parent
                spacing: Theme.spacingS

                DankToggle {
                    width: parent.width
                    text: root._trEnable
                    checked: root.loadValue("showLauncherParticles", true)
                    onToggled: c => root.saveAndPersist("showLauncherParticles", c)
                }

                StyledText {
                    text: root._trStyle
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                }

                Row {
                    spacing: 6
                    Repeater {
                        model: [
                            { label: "●", value: "circles" },
                            { label: "■", value: "squares" },
                            { label: "▲", value: "triangles" },
                            { label: "✦", value: "stars" },
                            { label: "━", value: "lines" }
                        ]
                        Rectangle {
                            required property var modelData
                            width: 36; height: 28; radius: 6
                            color: root.loadValue("particleStyle", "stars") === modelData.value ? Theme.primary : Theme.withAlpha(Theme.surfaceText, 0.08)
                            StyledText {
                                anchors.centerIn: parent; text: modelData.label; font.pixelSize: 14
                                color: root.loadValue("particleStyle", "stars") === modelData.value ? Theme.onPrimary : Theme.surfaceText
                            }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: root.saveAndPersist("particleStyle", modelData.value)
                            }
                        }
                    }
                }

                StyledText {
                    text: root._trOpacity + ": " + Math.round(root.loadValue("particleOpacity", 1.0) * 100) + "%"
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                }
                Slider {
                    width: parent.width
                    from: 0.0; to: 1.0; stepSize: 0.01
                    value: root.loadValue("particleOpacity", 1.0)
                    onValueChanged: root.saveAndPersist("particleOpacity", value)
                }

                StyledText {
                    text: root._trCount + ": " + root.loadValue("particleCount", 150)
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                }
                Slider {
                    width: parent.width
                    from: 10; to: 300; stepSize: 10
                    value: root.loadValue("particleCount", 150)
                    onValueChanged: root.saveAndPersist("particleCount", value)
                }

                StyledText {
                    text: root._trSize + ": " + root.loadValue("particleSize", 8.0).toFixed(1)
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                }
                Slider {
                    width: parent.width
                    from: 0.5; to: 8.0; stepSize: 0.5
                    value: root.loadValue("particleSize", 8.0)
                    onValueChanged: root.saveAndPersist("particleSize", value)
                }
            }
        }

        Item { width: 1; height: Theme.spacingM }

        // ── Language ──────────────────────────────────────────────────────────
        StyledText {
            text: root._trLanguage
            font.pixelSize: Theme.fontSizeMedium
            font.bold: true
            color: Theme.surfaceText
        }
        Item { width: 1; height: Theme.spacingS }

        StyledRect {
            width: parent.width
            radius: Theme.cornerRadius
            color: Theme.surfaceContainer
            height: langBtn.height + Theme.spacingL * 2 + 4

            Rectangle {
                id: langBtn
                width: parent.width - Theme.spacingL * 2
                height: 28; radius: 6
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Theme.spacingL
                color: langBtnArea.containsMouse ? Theme.withAlpha(Theme.primary, 0.15) : Theme.withAlpha(Theme.surfaceText, 0.06)
                border.color: langBtnArea.containsMouse ? Theme.primary : Theme.withAlpha(Theme.outline, 0.2); border.width: 1
                property bool langListOpen: false

                Row {
                    anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 8; spacing: 4
                    StyledText {
                        text: {
                            var cur = root._settingsLang;
                            var m = {"system": root._trSystemDefault, "zh_CN": "中文", "en": "English",
                                "de": "Deutsch", "es": "Español", "fr": "Français",
                                "ja": "日本語", "ko": "한국어", "ru": "Русский", "vi": "Tiếng Việt"};
                            return m[cur] || cur;
                        }
                        font.pixelSize: Theme.fontSizeSmall; color: Theme.surfaceText
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 24; elide: Text.ElideRight
                    }
                    DankIcon {
                        name: langBtn.langListOpen ? "expand_less" : "expand_more"
                        size: 16; color: Theme.surfaceVariantText; anchors.verticalCenter: parent.verticalCenter
                    }
                }
                MouseArea {
                    id: langBtnArea
                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: langBtn.langListOpen = !langBtn.langListOpen
                }
            }

            Rectangle {
                visible: langBtn.langListOpen
                height: Math.min(160, langListView.implicitHeight + 4)
                anchors.bottom: langBtn.top
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - Theme.spacingL * 2
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
                            model: [
                                { label: root._trSystemDefault, code: "system" },
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
                            delegate: Rectangle {
                                width: parent.width; height: 26; radius: 4
                                color: root.loadValue("pluginLanguage", "system") === modelData.code ? Theme.withAlpha(Theme.primary, 0.15) : langItemMouse.containsMouse ? Theme.withAlpha(Theme.surfaceText, 0.06) : "transparent"
                                StyledText {
                                    text: modelData.label
                                    font.pixelSize: Theme.fontSizeSmall; color: Theme.surfaceText
                                    anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: 8
                                }
                                MouseArea {
                                    id: langItemMouse
                                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.saveAndPersist("pluginLanguage", modelData.code);
                                        root._settingsLang = modelData.code;
                                        langBtn.langListOpen = false;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        Item { width: 1; height: Theme.spacingM }

        // ── About / GitHub ────────────────────────────────────────────────────
        StyledText {
            text: root._trAbout
            font.pixelSize: Theme.fontSizeMedium
            font.bold: true
            color: Theme.surfaceText
        }
        Item { width: 1; height: Theme.spacingS }

        StyledRect {
            width: parent.width
            height: githubRow.implicitHeight + Theme.spacingL * 2
            radius: Theme.cornerRadius
            color: Theme.surfaceContainer

            Row {
                id: githubRow
                width: parent.width - Theme.spacingL * 2
                anchors.centerIn: parent
                spacing: Theme.spacingM

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - githubBtn.width - parent.spacing
                    spacing: 2

                    StyledText {
                        text: "dms-conky"
                        font.bold: true
                        font.pixelSize: Theme.fontSizeSmall
                    }
                    StyledText {
                        width: parent.width
                        text: root._trBugRequest
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceVariantText
                        wrapMode: Text.Wrap
                    }
                }

                DankButton {
                    id: githubBtn
                    anchors.verticalCenter: parent.verticalCenter
                    text: root._trGitHub
                    iconName: "code"
                    backgroundColor: Theme.withAlpha(Theme.primary, 0.1)
                    textColor: Theme.primary
                    onClicked: Qt.openUrlExternally("https://github.com/suruibin/dms-conky")
                }
            }
        }

    }

    Component.onCompleted: {
        _applySettingsI18n(_settingsLang)
    }
}

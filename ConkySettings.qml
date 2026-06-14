import QtQuick
import QtQuick.Controls
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginSettings {
    id: root
    pluginId: "dmsconky"

    function saveAndPersist(key, value) {
        root.saveValue(key, value)
        SettingsData.setPluginSetting(root.pluginId, key, value)
        SettingsData.savePluginSettings()
    }

    Column {
        width: parent.width
        spacing: 0

        StyledText {
            text: I18n.tr("Module")
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
                    text: I18n.tr("Clock")
                    checked: root.loadValue("showClock", true)
                    onToggled: c => root.saveAndPersist("showClock", c)
                }
                DankToggle {
                    width: parent.width
                    text: I18n.tr("Weather")
                    checked: root.loadValue("showWeather", true)
                    onToggled: c => root.saveAndPersist("showWeather", c)
                }
                DankToggle {
                    width: parent.width
                    text: I18n.tr("Network")
                    checked: root.loadValue("showNetwork", true)
                    onToggled: c => root.saveAndPersist("showNetwork", c)
                }
                DankToggle {
                    width: parent.width
                    text: I18n.tr("Music")
                    checked: root.loadValue("showMusic", true)
                    onToggled: c => root.saveAndPersist("showMusic", c)
                }
                DankToggle {
                    width: parent.width
                    text: I18n.tr("Storage")
                    checked: root.loadValue("showStorage", true)
                    onToggled: c => root.saveAndPersist("showStorage", c)
                }
                DankToggle {
                    width: parent.width
                    text: I18n.tr("Rotating Album")
                    checked: root.loadValue("showRotatingAlbum", true)
                    onToggled: c => root.saveAndPersist("showRotatingAlbum", c)
                }
            }
        }

        Item { width: 1; height: Theme.spacingS }

        StyledText {
            text: I18n.tr("Default View")
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
                        { label: I18n.tr("Conky"), value: "conky" },
                        { label: I18n.tr("Apps"), value: "apps" }
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
            text: I18n.tr("Colors")
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

                ColorPicker { compact: true; title: I18n.tr("Primary Color"); settingKey: "accentColor"; defaultColor: "#7C3AED" }
                ColorPicker { compact: true; title: I18n.tr("Secondary Color"); settingKey: "accent2Color"; defaultColor: "#D97706" }
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
            text: I18n.tr("Clock Colors")
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

                ColorRow { label: I18n.tr("Hour");    settingKey: "clockHourColor";    defaultColor: "#6366F1" }
                ColorRow { label: I18n.tr("Minute");  settingKey: "clockMinuteColor";  defaultColor: "#F97316" }
                ColorRow { label: I18n.tr("Second");  settingKey: "clockSecondColor";  defaultColor: "#EC4899" }
                ColorRow { label: I18n.tr("Colon");   settingKey: "clockColonColor";   defaultColor: "#3B82F6" }
                ColorRow { label: I18n.tr("Weekday"); settingKey: "dateWeekdayColor";  defaultColor: "#EAB308" }
                ColorRow { label: I18n.tr("Day");     settingKey: "dateDayColor";      defaultColor: "#06B6D4" }
                ColorRow { label: I18n.tr("Month");   settingKey: "dateMonthColor";    defaultColor: "#EC4899" }
            }
        }

        Item { width: 1; height: Theme.spacingM }

        // ---- Ring Gauge Colors ----
        StyledText {
            text: I18n.tr("Ring Gauge Colors")
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

                ColorRow { label: I18n.tr("CPU");     settingKey: "cpuGaugeColor";     defaultColor: "#DC2626" }
                ColorRow { label: I18n.tr("Memory");  settingKey: "memGaugeColor";     defaultColor: "#EAB308" }
                ColorRow { label: I18n.tr("Battery"); settingKey: "batteryGaugeColor"; defaultColor: "#22C55E" }
                ColorRow { label: I18n.tr("AC");      settingKey: "batteryAcGaugeColor"; defaultColor: "#22C55E" }
                ColorRow { label: I18n.tr("Temp");    settingKey: "tempGaugeColor";    defaultColor: "#EF4444" }
                ColorRow { label: I18n.tr("Bg");      settingKey: "ringBgColor";       defaultColor: "#94A3B8" }
            }
        }

        Item { width: 1; height: Theme.spacingM }

        // ---- Display ----
        StyledText {
            text: I18n.tr("Display")
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
                    text: I18n.tr("Transparency") + ": " + Math.round(root.loadValue("bgOpacity", 0.0) * 100) + "%"
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
                    text: I18n.tr("Widget Size") + ": " + root.loadValue("widgetWidth", 298) + " × " + root.loadValue("widgetHeight", 522)
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
                    text: I18n.tr("Icon Size") + ": " + root.loadValue("appSize", 80) + "px"
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
                    text: I18n.tr("Music Player")
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
                    text: I18n.tr("GUI: /path/to/app | Terminal: alacritty -e /path/to/app | Kitty: kitty /path/to/app | Konsole: konsole -e /path/to/app")
                    font.pixelSize: Theme.fontSizeSmall; color: "#3B82F6"
                    wrapMode: Text.Wrap; width: parent.width
                }
            }
        }

        Item { width: 1; height: Theme.spacingM }

        // ---- Particles ----
        StyledText {
            text: I18n.tr("Particles")
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
                    text: I18n.tr("Enable")
                    checked: root.loadValue("showLauncherParticles", true)
                    onToggled: c => root.saveAndPersist("showLauncherParticles", c)
                }

                StyledText {
                    text: I18n.tr("Style")
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
                    text: I18n.tr("Opacity") + ": " + Math.round(root.loadValue("particleOpacity", 1.0) * 100) + "%"
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
                    text: I18n.tr("Count") + ": " + root.loadValue("particleCount", 150)
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
                    text: I18n.tr("Size") + ": " + root.loadValue("particleSize", 8.0).toFixed(1)
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

        // ── About / GitHub ────────────────────────────────────────────────────
        StyledText {
            text: I18n.tr("About")
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
                        text: I18n.tr("Found a bug or have a feature request? Join us on GitHub.")
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceVariantText
                        wrapMode: Text.Wrap
                    }
                }

                DankButton {
                    id: githubBtn
                    anchors.verticalCenter: parent.verticalCenter
                    text: I18n.tr("GitHub")
                    iconName: "code"
                    backgroundColor: Theme.withAlpha(Theme.primary, 0.1)
                    textColor: Theme.primary
                    onClicked: Qt.openUrlExternally("https://github.com/suruibin/dms-conky")
                }
            }
        }

    }
}

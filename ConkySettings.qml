import QtQuick
import QtQuick.Controls
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginSettings {
    id: root
    pluginId: "conky"

    function saveAndPersist(key, value) {
        root.saveValue(key, value)
        SettingsData.setPluginSetting("conky", key, value)
        SettingsData.savePluginSettings()
    }

    Column {
        width: parent.width
        spacing: 0

        StyledText {
            text: "Display Sections"
            font.pixelSize: Theme.fontSizeMedium
            font.bold: true
            color: Theme.surfaceText
        }
        Item { width: 1; height: Theme.spacingS }

        DankToggle {
            width: parent.width
            text: "Show Clock"
            checked: root.loadValue("showClock", true)
            onToggled: c => root.saveAndPersist("showClock", c)
        }
        DankToggle {
            width: parent.width
            text: "Show Weather"
            checked: root.loadValue("showWeather", true)
            onToggled: c => root.saveAndPersist("showWeather", c)
        }
        DankToggle {
            width: parent.width
            text: "Show Network"
            checked: root.loadValue("showNetwork", true)
            onToggled: c => root.saveAndPersist("showNetwork", c)
        }
        DankToggle {
            width: parent.width
            text: "Show Music Player"
            checked: root.loadValue("showMusic", true)
            onToggled: c => root.saveAndPersist("showMusic", c)
        }

        Item { width: 1; height: Theme.spacingM }

        StyledText {
            text: "Primary Color"
            font.pixelSize: Theme.fontSizeMedium
            font.bold: true
            color: Theme.surfaceText
        }
        Item { width: 1; height: Theme.spacingS }

        Flow {
            width: parent.width
            spacing: 6
            Repeater {
                model: ["#5105DB", "#7C3AED", "#8B5CF6", "#A855F7", "#6366F1", "#2563EB", "#3B82F6", "#0891B2", "#06B6D4", "#14B8A6", "#059669", "#10B981", "#22C55E", "#EAB308", "#F59E0B", "#D97706", "#F97316", "#DC2626", "#EF4444", "#DB2777", "#EC4899", "#D946EF", "#ffffff", "#94A3B8", "#64748B", "#334155"]
                Rectangle {
                    required property var modelData
                    property string c: modelData
                    width: 26; height: 26; radius: 13
                    color: c
                    border.width: root.loadValue("accentColor", "#5105DB") === c ? 3 : 0
                    border.color: Theme.surfaceText
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.saveAndPersist("accentColor", c)
                    }
                }
            }
        }

        Item { width: 1; height: Theme.spacingS }

        StyledText {
            text: "Secondary Color"
            font.pixelSize: Theme.fontSizeMedium
            font.bold: true
            color: Theme.surfaceText
        }
        Item { width: 1; height: Theme.spacingS }

        Flow {
            width: parent.width
            spacing: 6
            Repeater {
                model: ["#FF1493", "#F43F5E", "#E11D48", "#DC2626", "#EF4444", "#F97316", "#F59E0B", "#EAB308", "#22C55E", "#10B981", "#14B8A6", "#06B6D4", "#0EA5E9", "#3B82F6", "#6366F1", "#8B5CF6", "#A855F7", "#D946EF", "#EC4899", "#DB2777", "#94A3B8", "#64748B", "#334155", "#ffffff"]
                Rectangle {
                    required property var modelData
                    property string c: modelData
                    width: 26; height: 26; radius: 13
                    color: c
                    border.width: root.loadValue("accent2Color", "#FF1493") === c ? 3 : 0
                    border.color: Theme.surfaceText
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.saveAndPersist("accent2Color", c)
                    }
                }
            }
        }

        Rectangle {
            width: parent.width; height: 1
            color: Theme.withAlpha(Theme.surfaceVariantText, 0.15)
        }
        Item { width: 1; height: Theme.spacingM }

        // ---- Clock / Date Colors ----
        StyledText {
            text: "Clock Colors"
            font.pixelSize: Theme.fontSizeMedium
            font.bold: true
            color: Theme.surfaceText
        }
        Item { width: 1; height: Theme.spacingS }

        // Generic color-row component: label + 12-color picker
        component ColorRow: Row {
            spacing: 3
            property string label: ""
            property string settingKey: ""
            property string defaultColor: "#f0f0f0"

            StyledText {
                text: label
                width: 56; anchors.verticalCenter: parent.verticalCenter
                font.pixelSize: 11; color: Theme.surfaceVariantText
            }
            Repeater {
                model: ["#f0f0f0", "#EF4444", "#F97316", "#EAB308", "#22C55E", "#14B8A6", "#06B6D4", "#3B82F6", "#6366F1", "#8B5CF6", "#EC4899", "#94A3B8"]
                Rectangle {
                    required property var modelData
                    property string c: modelData
                    width: 20; height: 20; radius: 10; color: c
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

        ColorRow { label: "Hour";    settingKey: "clockHourColor" }
        ColorRow { label: "Minute";  settingKey: "clockMinuteColor" }
        ColorRow { label: "Second";  settingKey: "clockSecondColor" }
        ColorRow { label: "Colon";   settingKey: "clockColonColor" }
        ColorRow { label: "Weekday"; settingKey: "dateWeekdayColor" }
        ColorRow { label: "Day";     settingKey: "dateDayColor" }
        ColorRow { label: "Month";   settingKey: "dateMonthColor" }

        Rectangle {
            width: parent.width; height: 1
            color: Theme.withAlpha(Theme.surfaceVariantText, 0.15)
        }
        Item { width: 1; height: Theme.spacingM }

        StyledText {
            text: "Ring Gauge Colors"
            font.pixelSize: Theme.fontSizeMedium
            font.bold: true
            color: Theme.surfaceText
        }
        Item { width: 1; height: Theme.spacingS }

        ColorRow { label: "CPU";     settingKey: "cpuGaugeColor";     defaultColor: "#5105DB" }
        ColorRow { label: "Memory";  settingKey: "memGaugeColor";     defaultColor: "#8B0AC3" }
        ColorRow { label: "Battery"; settingKey: "batteryGaugeColor"; defaultColor: "#C20EAC" }
        ColorRow { label: "AC";      settingKey: "batteryAcGaugeColor"; defaultColor: "#22C55E" }
        ColorRow { label: "Temp";    settingKey: "tempGaugeColor";    defaultColor: "#FF1493" }

        Rectangle {
            width: parent.width; height: 1
            color: Theme.withAlpha(Theme.surfaceVariantText, 0.15)
        }
        Item { width: 1; height: Theme.spacingM }

        StyledText {
            text: "Background: " + Math.round(root.loadValue("bgOpacity", 0.0) * 100) + "%"
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.surfaceVariantText
        }
        Slider {
            width: parent.width
            from: 0.0; to: 1.0; stepSize: 0.01
            value: root.loadValue("bgOpacity", 0.0)
            onValueChanged: root.saveAndPersist("bgOpacity", value)
        }

        Item { width: 1; height: Theme.spacingM }

        StyledText {
            text: "Widget Size: " + root.loadValue("widgetWidth", 330) + " × " + root.loadValue("widgetHeight", 620)
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.surfaceVariantText
        }
        Slider {
            width: parent.width
            from: 280; to: 600; stepSize: 10
            value: root.loadValue("widgetWidth", 330)
            onValueChanged: root.saveAndPersist("widgetWidth", value)
        }
        Slider {
            width: parent.width
            from: 500; to: 1200; stepSize: 10
            value: root.loadValue("widgetHeight", 620)
            onValueChanged: root.saveAndPersist("widgetHeight", value)
        }

        Item { width: 1; height: Theme.spacingS }

        StyledText {
            text: "App Icon Size: " + root.loadValue("appSize", 88) + "px"
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.surfaceVariantText
        }
        Slider {
            width: parent.width
            from: 48; to: 128; stepSize: 4
            value: root.loadValue("appSize", 88)
            onValueChanged: root.saveAndPersist("appSize", value)
        }

        Rectangle {
            width: parent.width; height: 1
            color: Theme.withAlpha(Theme.surfaceVariantText, 0.15)
        }
        Item { width: 1; height: Theme.spacingM }

        // ── About / GitHub ────────────────────────────────────────────────────
        StyledText {
            text: "About"
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
                        text: "Found a bug or have a feature request? Join us on GitHub."
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceVariantText
                        wrapMode: Text.Wrap
                    }
                }

                DankButton {
                    id: githubBtn
                    anchors.verticalCenter: parent.verticalCenter
                    text: "GitHub"
                    iconName: "code"
                    backgroundColor: Theme.withAlpha(Theme.primary, 0.1)
                    textColor: Theme.primary
                    onClicked: Qt.openUrlExternally("https://github.com/suruibin/dms-conky")
                }
            }
        }

    }
}

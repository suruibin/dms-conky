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
            text: I18n.tr("Module")
            font.pixelSize: Theme.fontSizeMedium
            font.bold: true
            color: Theme.surfaceText
        }
        Item { width: 1; height: Theme.spacingS }

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

        Item { width: 1; height: Theme.spacingS }

        StyledText {
            text: I18n.tr("Default View")
            font.pixelSize: Theme.fontSizeMedium
            font.bold: true
            color: Theme.surfaceText
        }
        Item { width: 1; height: Theme.spacingS }

        Row {
            spacing: 6
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

        Item { width: 1; height: Theme.spacingM }

        component ColorPicker: Column {
            width: parent.width
            property string title: ""
            property string settingKey: ""
            property string defaultColor: "#5105DB"

            StyledText {
                text: title
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
                        border.width: root.loadValue(settingKey, defaultColor) === c ? 3 : 0
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

        ColorPicker { title: I18n.tr("Primary Color"); settingKey: "accentColor"; defaultColor: "#5105DB" }

        Item { width: 1; height: Theme.spacingS }

        ColorPicker { title: I18n.tr("Secondary Color"); settingKey: "accent2Color"; defaultColor: "#FF1493" }

        Rectangle {
            width: parent.width; height: 1
            color: Theme.withAlpha(Theme.surfaceVariantText, 0.15)
        }
        Item { width: 1; height: Theme.spacingM }

        // ---- Clock / Date Colors ----
        StyledText {
            text: I18n.tr("Clock Colors")
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
                model: ["#f0f0f0", "#F43F5E", "#EF4444", "#DC2626", "#F97316", "#EA580C", "#EAB308", "#84CC16", "#22C55E", "#10B981", "#14B8A6", "#06B6D4", "#0EA5E9", "#3B82F6", "#6366F1", "#8B5CF6", "#A855F7", "#D946EF", "#EC4899", "#94A3B8"]
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

        ColorRow { label: I18n.tr("Hour");    settingKey: "clockHourColor" }
        ColorRow { label: I18n.tr("Minute");  settingKey: "clockMinuteColor" }
        ColorRow { label: I18n.tr("Second");  settingKey: "clockSecondColor" }
        ColorRow { label: I18n.tr("Colon");   settingKey: "clockColonColor" }
        ColorRow { label: I18n.tr("Weekday"); settingKey: "dateWeekdayColor" }
        ColorRow { label: I18n.tr("Day");     settingKey: "dateDayColor" }
        ColorRow { label: I18n.tr("Month");   settingKey: "dateMonthColor" }

        Rectangle {
            width: parent.width; height: 1
            color: Theme.withAlpha(Theme.surfaceVariantText, 0.15)
        }
        Item { width: 1; height: Theme.spacingM }

        StyledText {
            text: I18n.tr("Ring Gauge Colors")
            font.pixelSize: Theme.fontSizeMedium
            font.bold: true
            color: Theme.surfaceText
        }
        Item { width: 1; height: Theme.spacingS }

        ColorRow { label: I18n.tr("CPU");     settingKey: "cpuGaugeColor";     defaultColor: "#5105DB" }
        ColorRow { label: I18n.tr("Memory");  settingKey: "memGaugeColor";     defaultColor: "#8B0AC3" }
        ColorRow { label: I18n.tr("Battery"); settingKey: "batteryGaugeColor"; defaultColor: "#C20EAC" }
        ColorRow { label: I18n.tr("AC");      settingKey: "batteryAcGaugeColor"; defaultColor: "#22C55E" }
        ColorRow { label: I18n.tr("Temp");    settingKey: "tempGaugeColor";    defaultColor: "#FF1493" }
        ColorRow { label: I18n.tr("Bg");      settingKey: "ringBgColor";       defaultColor: "#26ffffff" }

        Rectangle {
            width: parent.width; height: 1
            color: Theme.withAlpha(Theme.surfaceVariantText, 0.15)
        }
        Item { width: 1; height: Theme.spacingM }

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

        Item { width: 1; height: Theme.spacingM }

        StyledText {
            text: I18n.tr("Widget Size") + ": " + root.loadValue("widgetWidth", 330) + " × " + root.loadValue("widgetHeight", 620)
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
            text: I18n.tr("Icon Size") + ": " + root.loadValue("appSize", 88) + "px"
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

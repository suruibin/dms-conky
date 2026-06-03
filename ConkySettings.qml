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

        // ---- Clock / Date Colors ----
        StyledText {
            text: "Clock Colors"
            font.pixelSize: Theme.fontSizeMedium
            font.bold: true
            color: Theme.surfaceText
        }
        Item { width: 1; height: Theme.spacingS }

        // Generic color-row component: label + 9-color picker
        component ColorRow: Row {
            spacing: 4
            property string label: ""
            property string settingKey: ""
            property string defaultColor: "#f0f0f0"

            StyledText {
                text: label
                width: 56; anchors.verticalCenter: parent.verticalCenter
                font.pixelSize: 11; color: Theme.surfaceVariantText
            }
            Repeater {
                model: ["#f0f0f0", "#EF4444", "#F97316", "#EAB308", "#22C55E", "#06B6D4", "#3B82F6", "#8B5CF6", "#EC4899"]
                Rectangle {
                    required property var modelData
                    property string c: modelData
                    width: 24; height: 24; radius: 12; color: c
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
                model: ["#5105DB", "#7C3AED", "#2563EB", "#0891B2", "#059669", "#D97706", "#DC2626", "#DB2777", "#ffffff"]
                Rectangle {
                    required property var modelData
                    property string c: modelData
                    width: 30; height: 30; radius: 15
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
                model: ["#FF1493", "#F43F5E", "#F97316", "#EAB308", "#22C55E", "#06B6D4", "#8B5CF6", "#EC4899", "#94A3B8"]
                Rectangle {
                    required property var modelData
                    property string c: modelData
                    width: 30; height: 30; radius: 15
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

    }
}

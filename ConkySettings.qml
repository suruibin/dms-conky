import QtQuick
import QtQuick.Controls
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginSettings {
    id: root
    pluginId: "conky"

    Column {
        width: parent.width
        spacing: 0

        StyledText {
            text: "Display Sections"
            font.pixelSize: Theme.fontSizeMedium
            font.weight: Font.Bold
            color: Theme.surfaceText
        }
        Item { width: 1; height: Theme.spacingS }

        DankToggle {
            width: parent.width
            text: "Show Clock"
            checked: root.loadValue("showClock", true)
            onToggled: c => root.saveValue("showClock", c)
        }
        DankToggle {
            width: parent.width
            text: "Show Weather"
            checked: root.loadValue("showWeather", true)
            onToggled: c => root.saveValue("showWeather", c)
        }
        DankToggle {
            width: parent.width
            text: "Show Network"
            checked: root.loadValue("showNetwork", true)
            onToggled: c => root.saveValue("showNetwork", c)
        }
        DankToggle {
            width: parent.width
            text: "Show Music Player"
            checked: root.loadValue("showMusic", true)
            onToggled: c => root.saveValue("showMusic", c)
        }

        Item { width: 1; height: Theme.spacingM }

        StyledText {
            text: "Primary Color"
            font.pixelSize: Theme.fontSizeMedium
            font.weight: Font.Bold
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
                        onClicked: root.saveValue("accentColor", c)
                    }
                }
            }
        }

        Item { width: 1; height: Theme.spacingS }

        StyledText {
            text: "Secondary Color"
            font.pixelSize: Theme.fontSizeMedium
            font.weight: Font.Bold
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
                        onClicked: root.saveValue("accent2Color", c)
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
            onValueChanged: root.saveValue("bgOpacity", value)
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
            onValueChanged: root.saveValue("widgetWidth", value)
        }
        Slider {
            width: parent.width
            from: 500; to: 1200; stepSize: 10
            value: root.loadValue("widgetHeight", 620)
            onValueChanged: root.saveValue("widgetHeight", value)
        }

        Item { width: 1; height: Theme.spacingM }

        // ======== App Launcher Settings ========
        StyledText {
            text: "App Launcher"
            font.pixelSize: Theme.fontSizeMedium
            font.weight: Font.Bold
            color: Theme.surfaceText
        }
        Item { width: 1; height: Theme.spacingS }

        StyledText {
            text: "Launcher Background: " + Math.round(root.loadValue("backgroundOpacity", 80)) + "%"
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.surfaceVariantText
        }
        Slider {
            width: parent.width
            from: 0; to: 100; stepSize: 1
            value: root.loadValue("backgroundOpacity", 80)
            onValueChanged: root.saveValue("backgroundOpacity", value)
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
            onValueChanged: root.saveValue("appSize", value)
        }

        Item { width: 1; height: Theme.spacingS }

        StyledText {
            text: "View Mode"
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.surfaceVariantText
        }
        Row {
            spacing: 6
            Repeater {
                model: [
                    { label: "Grid", value: "grid" },
                    { label: "List", value: "list" },
                    { label: "Compact", value: "compact" }
                ]
                Rectangle {
                    required property var modelData
                    width: 60; height: 28; radius: 6
                    color: root.loadValue("viewMode", "grid") === modelData.value ? Theme.primary : Theme.withAlpha(Theme.surfaceText, 0.08)
                    StyledText {
                        anchors.centerIn: parent
                        text: modelData.label
                        font.pixelSize: 11
                        color: root.loadValue("viewMode", "grid") === modelData.value ? Theme.onPrimary : Theme.surfaceText
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.saveValue("viewMode", modelData.value)
                    }
                }
            }
        }

        Item { width: 1; height: Theme.spacingS }

        DankToggle {
            width: parent.width
            text: "Show Launcher Header"
            checked: root.loadValue("showHeader", true)
            onToggled: c => root.saveValue("showHeader", c)
        }
    }
}

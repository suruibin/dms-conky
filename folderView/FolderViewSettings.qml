import QtQuick
import QtQuick.Controls
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins
import "./dms-common"

PluginSettings {
    id: root
    pluginId: "folderView"

    SettingsCard {
        id: appearanceSection
        SectionTitle { 
            text: I18n.tr("Appearance")
            icon: "palette" 
            showReset: backgroundOpacity.isDirty || borderOpacity.isDirty || cellSize.isDirty || viewMode.isDirty || headerPosition.isDirty || showHeader.isDirty || showHidden.isDirty || emptyColor.isDirty || folderColor.isDirty
            onResetClicked: {
                backgroundOpacity.resetToDefault();
                borderOpacity.resetToDefault();
                cellSize.resetToDefault();
                viewMode.resetToDefault();
                headerPosition.resetToDefault();
                showHeader.resetToDefault();
                showHidden.resetToDefault();
                emptyColor.resetToDefault();
                folderColor.resetToDefault();
            }
        }

        SliderSettingPlus {
            id: backgroundOpacity
            settingKey: "backgroundOpacity"
            label: I18n.tr("Background Opacity")
            defaultValue: 80
            minimum: 0
            maximum: 100
            unit: "%"
            leftLabel: "0%"
            rightLabel: "100%"
        }

        Separator {}

        SliderSettingPlus {
            id: borderOpacity
            settingKey: "borderOpacity"
            label: I18n.tr("Border Opacity")
            defaultValue: 0
            minimum: 0
            maximum: 100
            unit: "%"
            leftLabel: "0%"
            rightLabel: "100%"
        }

        Separator {}

        SliderSettingPlus {
            id: cellSize
            settingKey: "cellSize"
            label: I18n.tr("Icon Size")
            description: I18n.tr("Adjust the size of file and folder icons.")
            defaultValue: 84
            minimum: 64
            maximum: 128
            unit: "px"
            leftLabel: "64"
            rightLabel: "128"
        }

        Separator {}

        ButtonGroupSettingPlus {
            id: viewMode
            settingKey: "viewMode"
            label: I18n.tr("View Mode")
            options: [
                { label: I18n.tr("Grid View"), value: "grid" },
                { label: I18n.tr("List View"), value: "list" },
                { label: I18n.tr("Compact View"), value: "compact" }
            ]
            defaultValue: "grid"
        }

        Separator {}

        ButtonGroupSettingPlus {
            id: headerPosition
            settingKey: "headerPosition"
            label: I18n.tr("Header Position")
            options: [
                { label: I18n.tr("Top"),    value: "top"    },
                { label: I18n.tr("Bottom"), value: "bottom" }
            ]
            defaultValue: "top"
        }

        Separator {}

        ToggleSettingPlus {
            id: showHeader
            settingKey: "showHeader"
            label: I18n.tr("Show Folder Header")
            defaultValue: true
        }

        Separator {}

        ToggleSettingPlus {
            id: showHidden
            settingKey: "showHidden"
            label: I18n.tr("Show Hidden Files")
            defaultValue: false
        }

        Separator {}

        Item {
            id: emptyColor
            width: parent.width
            implicitHeight: 50

            readonly property string value: pluginData?.emptyColor ?? "#FF1744"
            readonly property bool isDirty: false

            function resetToDefault() {
                if (pluginService)
                    pluginService.savePluginData("folderView", "emptyColor", "#FF1744");
            }

            StyledText {
                text: I18n.tr("Empty Indicator Color")
                font.pixelSize: Theme.fontSizeLarge
                font.weight: Font.Medium
                color: Theme.surfaceText
                anchors.left: parent.left
                anchors.top: parent.top
            }

            Row {
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                spacing: 6

                Repeater {
                    model: ["#FF1744", "#00E676", "#FFEA00", "#448AFF", "#D500F9", "#00BFA5", "#FF9100", "#E91E63", "#00BCD4", "#795548"]

                    delegate: Rectangle {
                        width: 14; height: 14; radius: 2
                        color: modelData
                        border.width: emptyColor.value === modelData ? 2 : 1
                        border.color: emptyColor.value === modelData ? Theme.surfaceText : Theme.withAlpha(Theme.outline, 0.3)

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (pluginService)
                                    pluginService.savePluginData("folderView", "emptyColor", modelData);
                            }
                        }
                    }
                }
            }
        }

        Separator {}

        Item {
            id: folderColor
            width: parent.width
            implicitHeight: 50

            readonly property string value: pluginData?.folderColor ?? ""
            readonly property bool isDirty: false

            function resetToDefault() {
                if (pluginService)
                    pluginService.savePluginData("folderView", "folderColor", "");
            }

            StyledText {
                text: I18n.tr("Folder Icon Color")
                font.pixelSize: Theme.fontSizeLarge
                font.weight: Font.Medium
                color: Theme.surfaceText
                anchors.left: parent.left
                anchors.top: parent.top
            }

            Row {
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                spacing: 6

                Repeater {
                    model: ["", "#FF1744", "#00E676", "#FFEA00", "#448AFF", "#D500F9", "#00BFA5", "#FF9100", "#E91E63", "#00BCD4"]

                    delegate: Rectangle {
                        width: 14; height: 14; radius: modelData === "" ? 7 : 2
                        color: modelData || Theme.primary
                        border.width: folderColor.value === modelData ? 2 : 1
                        border.color: folderColor.value === modelData ? Theme.surfaceText : Theme.withAlpha(Theme.outline, 0.3)

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (pluginService)
                                    pluginService.savePluginData("folderView", "folderColor", modelData);
                            }
                        }
                    }
                }
            }
        }
    }

    SettingsCard {
        SectionTitle { 
            id: usageTitle
            text: I18n.tr("Usage Guide")
            icon: "menu_book" 
            collapsible: true
            settingKey: "usageGuideExpanded"
        }

        UsageGuide {
            expanded: usageTitle.isExpanded
            items: [
                I18n.tr("<b>Left-click</b> the folder title to switch between system directories."),
                I18n.tr("<b>Left-click</b> the <b>+ icon</b> to create new folders, documents, or <b>app shortcuts</b>."),
                I18n.tr("<b>Double-click</b> any item to open it with the system default application."),
                I18n.tr("<b>Middle-click</b> an item to open the <b>context menu</b> for file actions."),
                I18n.tr("<b>Middle-click</b> empty space to <b>Paste</b> files or images from clipboard."),
                I18n.tr("Use <b>Ctrl</b> and <b>Shift</b> for multi-selection operations.")
            ]
        }
    }

    PluginAbout {
        repoUrl: "https://github.com/hthienloc/dms-folder-view"
    }
}

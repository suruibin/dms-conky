import QtQuick
import Quickshell
import qs.Common
import qs.Widgets

Item {
    id: root
    property string iconSource: ""
    property real iconSize: 24
    // "A" corner badge marking AppImage entries in the launcher
    property bool showAppImageBadge: false

    implicitWidth: iconSize
    implicitHeight: iconSize

    property bool imageError: false
    // Fallback glyph color; callers on custom backgrounds pass the adaptive fgColor
    property color fallbackColor: Theme.surfaceText

    Image {
        id: appImage
        // file:// URLs / absolute paths load directly; only theme icon names go through iconPath
        property bool isFilePath: iconSource.indexOf("file://") === 0 || iconSource.indexOf("/") === 0
        source: iconSource === "" ? ""
                : isFilePath ? iconSource : Quickshell.iconPath(iconSource)
        // Full-bleed file icons need optical padding to match theme icons
        anchors.fill: parent
        anchors.margins: isFilePath ? Math.round(root.iconSize * 0.1) : 0
        fillMode: Image.PreserveAspectFit
        visible: iconSource !== "" && !root.imageError
        onStatusChanged: {
            if (status == Image.Error) root.imageError = true
            else if (status == Image.Ready) root.imageError = false
        }
    }

    DankIcon {
        id: fallbackIcon
        anchors.fill: parent
        name: "extension"
        size: iconSize
        color: root.fallbackColor
        visible: iconSource === "" || root.imageError
    }

    // AppImage marker badge (bottom-right "A")
    Rectangle {
        readonly property real badgeSize: Math.min(18, Math.max(10, Math.round(root.iconSize * 0.3)))
        visible: root.showAppImageBadge
        width: badgeSize; height: badgeSize; radius: badgeSize / 2
        anchors.right: parent.right; anchors.bottom: parent.bottom
        anchors.rightMargin: -2; anchors.bottomMargin: -2
        color: "#4CAF50"
        StyledText {
            anchors.centerIn: parent
            // Optical centering: cap glyph sits high in its bbox (descent gap below baseline)
            anchors.verticalCenterOffset: Math.round(parent.badgeSize * 0.07)
            anchors.horizontalCenterOffset: -1
            text: "A"
            font.pixelSize: parent.badgeSize * 0.8
            font.bold: true
            color: "#ffffff"
        }
    }
}

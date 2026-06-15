import QtQuick
import Quickshell
import qs.Common
import qs.Widgets

Item {
    id: root
    property string iconSource: ""
    property real iconSize: 24

    implicitWidth: iconSize
    implicitHeight: iconSize

    property bool imageError: false

    Image {
        id: appImage
        anchors.fill: parent
        source: iconSource ? Quickshell.iconPath(iconSource) : ""
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
        color: Theme.surfaceText
        visible: iconSource === "" || root.imageError
    }
}

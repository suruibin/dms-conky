import QtQuick
import Quickshell
import qs.Common
import qs.Widgets

Item {
    id: root
    property Item widget: null
    property real iconFactor: 20
    property int fontSize: Theme.fontSizeSmall
    property int hoveredIdx: -1

    MouseArea {
        id: rowCard
        anchors.fill: parent
        anchors.leftMargin: Theme.spacingXS
        anchors.rightMargin: Theme.spacingXS
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            clickAnim.start()
            Quickshell.execDetached(["sh", "-c", widget.cleanExec(appExec)])
        }

        Rectangle {
            id: rowContainer
            width: parent.parent.width
            height: parent.parent.height
            anchors.centerIn: parent
            radius: Math.round(Theme.cornerRadius / 2)
            color: (index === root.hoveredIdx) ? Theme.withAlpha(root.widget.hoverHighlightColor, 0.12) : "transparent"
            border.color: (index === root.hoveredIdx) ? Theme.withAlpha(root.widget.hoverHighlightColor, 0.3) : "transparent"
            border.width: (index === root.hoveredIdx) ? 1 : 0

            SequentialAnimation {
                id: clickAnim
                NumberAnimation { target: rowContainer; property: "scale"; to: 0.98; duration: 60 }
                NumberAnimation { target: rowContainer; property: "scale"; to: 1.0; duration: 100 }
            }

            Row {
                anchors.fill: parent
                anchors.leftMargin: Theme.spacingS
                anchors.rightMargin: Theme.spacingS
                spacing: Theme.spacingS
                anchors.verticalCenter: parent.verticalCenter

                AppIcon {
                    width: Math.round(root.iconFactor * (root.widget.appSize / 88.0))
                    height: width
                    iconSize: width
                    iconSource: appIcon
                    anchors.verticalCenter: parent.verticalCenter
                }

                StyledText {
                    text: appName
                    font.pixelSize: root.fontSize
                    color: Theme.surfaceText
                    anchors.verticalCenter: parent.verticalCenter
                    elide: Text.ElideRight
                    width: parent.width - parent.spacing - Math.round(root.iconFactor * (root.widget.appSize / 88.0))
                }
            }
        }
    }
}

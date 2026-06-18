import QtQuick
import QtQuick.Controls
import qs.Common
import qs.Widgets
import "./dms-common"

Popup {
    id: renameDialog
    width: 260
    height: 156
    padding: 0
    modal: false
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) { close(); event.accepted = true; }
    }

    x: parent ? Math.round((parent.width - width) / 2) : 0
    y: parent ? Math.round((parent.height - height) / 2) : 0

    property string filePath: ""
    property string oldName: ""
    property string fileExt: ""
    property bool isDir: false
    property var inputField: null

    onOpened: {
        Qt.callLater(() => {
            if (renameDialog.inputField) {
                renameDialog.inputField.forceActiveFocus();
                renameDialog.inputField.selectAll();
            }
        });
    }

    background: Rectangle {
        color: "transparent"
    }

    contentItem: Rectangle {
        color: Theme.withAlpha(Theme.surfaceContainer, 0.95)
        radius: Theme.cornerRadius
        border.color: Theme.withAlpha(Theme.outline, 0.15)
        border.width: 1

        Column {
            anchors.fill: parent
            anchors.margins: Theme.spacingM
            spacing: Theme.spacingS

            StyledText {
                text: I18n.tr("Rename")
                font.bold: true
                font.pixelSize: Theme.fontSizeMedium
                color: Theme.surfaceText
            }

            Row {
                width: parent.width
                spacing: Theme.spacingS

                DankTextField {
                    id: renameField
                    width: parent.width - (extLabel.visible ? extLabel.implicitWidth + Theme.spacingS : 0)
                    placeholderText: I18n.tr("Enter new name...")
                    focus: true
                    onAccepted: renameDialog.performRename()

                    Component.onCompleted: {
                        renameDialog.inputField = renameField;
                    }
                }

                StyledText {
                    id: extLabel
                    text: renameDialog.fileExt
                    font.pixelSize: Theme.fontSizeMedium
                    color: Theme.surfaceText
                    opacity: 0.6
                    anchors.verticalCenter: parent.verticalCenter
                    visible: text !== ""
                }
            }

            Row {
                width: parent.width
                spacing: Theme.spacingS
                layoutDirection: Qt.RightToLeft

                DankButton {
                    text: I18n.tr("Rename")
                    backgroundColor: Theme.primary
                    textColor: Theme.primaryText
                    onClicked: renameDialog.performRename()
                }

                DankButton {
                    text: I18n.tr("Cancel")
                    backgroundColor: Theme.surfaceContainerHigh
                    textColor: Theme.surfaceText
                    onClicked: renameDialog.close()
                }
            }
        }
    }

    function showFor(path, name, isDirectory) {
        let cleanPath = String(path);
        let isVirtualStack = cleanPath.startsWith("stack://");
        if (!isVirtualStack) {
            if (cleanPath.startsWith("file://")) {
                cleanPath = cleanPath.substring(7);
            }
            if (cleanPath.startsWith("localhost/")) {
                cleanPath = cleanPath.substring(9);
            }
        }
        renameDialog.filePath = cleanPath;
        renameDialog.oldName = name;
        renameDialog.isDir = !!isDirectory;

        let baseName = name;
        let extension = "";
        if (!renameDialog.isDir) {
            const lastDot = name.lastIndexOf(".");
            if (lastDot > 0) {
                baseName = name.substring(0, lastDot);
                extension = name.substring(lastDot);
            }
        }
        renameDialog.fileExt = extension;

        if (renameDialog.inputField) {
            renameDialog.inputField.text = baseName;
        }
        renameDialog.open();
    }

    function performRename() {
        if (renameDialog.inputField && parent && typeof parent.applyRename === "function") {
            parent.applyRename(renameDialog.filePath, renameDialog.oldName, renameDialog.isDir, renameDialog.inputField.text);
        }
        renameDialog.close();
    }
}

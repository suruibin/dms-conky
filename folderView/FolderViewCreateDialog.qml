import QtQuick
import QtQuick.Controls
import Quickshell
import qs.Common
import qs.Widgets
import qs.Services
import "./dms-common"

Popup {
    id: createDialog
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

    property string targetFolderUrl: ""
    property bool isFolder: true
    property var inputField: null

    onOpened: {
        Qt.callLater(() => {
            if (createDialog.inputField) {
                createDialog.inputField.forceActiveFocus();
                createDialog.inputField.selectAll();
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
                text: createDialog.isFolder ? I18n.tr("New Folder") : I18n.tr("New Document")
                font.bold: true
                font.pixelSize: Theme.fontSizeMedium
                color: Theme.surfaceText
            }

            Row {
                width: parent.width
                spacing: Theme.spacingS

                DankTextField {
                    id: createField
                    width: parent.width
                    placeholderText: createDialog.isFolder ? I18n.tr("Folder name...") : I18n.tr("File name...")
                    focus: true
                    onAccepted: createDialog.performCreate()

                    Component.onCompleted: {
                        createDialog.inputField = createField;
                    }
                }
            }

            Row {
                width: parent.width
                spacing: Theme.spacingS
                layoutDirection: Qt.RightToLeft

                DankButton {
                    text: I18n.tr("Create")
                    backgroundColor: Theme.primary
                    textColor: Theme.primaryText
                    onClicked: createDialog.performCreate()
                }

                DankButton {
                    text: I18n.tr("Cancel")
                    backgroundColor: Theme.surfaceContainerHigh
                    textColor: Theme.surfaceText
                    onClicked: createDialog.close()
                }
            }
        }
    }

    function showFor(folderOnly) {
        createDialog.isFolder = !!folderOnly;
        if (createDialog.inputField) {
            createDialog.inputField.text = createDialog.isFolder ? "New Folder" : "New Document.txt";
        }
        createDialog.open();
    }

    function performCreate() {
        if (!createDialog.inputField) {
            createDialog.close();
            return;
        }
        const name = createDialog.inputField.text.trim();
        if (name.length === 0) {
            createDialog.close();
            return;
        }

        let pathStr = String(createDialog.targetFolderUrl);
        if (pathStr.startsWith("file://")) {
            pathStr = pathStr.substring(7);
        }
        if (pathStr.startsWith("localhost/")) {
            pathStr = pathStr.substring(9);
        }
        
        const targetPath = pathStr + "/" + name;
        
        try {
            if (createDialog.isFolder) {
                Quickshell.execDetached(["mkdir", "-p", targetPath]);
            } else {
                Quickshell.execDetached(["touch", targetPath]);
            }
        } catch (e) {
            ToastService.showToast("Create error: " + e.message, ToastService.levelError);
        }
        createDialog.close();
    }
}

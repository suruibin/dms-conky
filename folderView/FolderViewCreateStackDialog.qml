import QtQuick
import QtQuick.Controls
import Quickshell
import qs.Common
import qs.Widgets
import qs.Services
import "./dms-common"

Popup {
    id: createStackDialog
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

    property var selectedPaths: []
    property var inputField: null

    onOpened: {
        Qt.callLater(() => {
            if (createStackDialog.inputField) {
                createStackDialog.inputField.forceActiveFocus();
                createStackDialog.inputField.selectAll();
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
                text: I18n.tr("Create Stack")
                font.bold: true
                font.pixelSize: Theme.fontSizeMedium
                color: Theme.surfaceText
            }

            Row {
                width: parent.width
                spacing: Theme.spacingS

                DankTextField {
                    id: stackNameField
                    width: parent.width
                    placeholderText: I18n.tr("Stack name...")
                    focus: true
                    onAccepted: createStackDialog.performCreate()

                    Component.onCompleted: {
                        createStackDialog.inputField = stackNameField;
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
                    onClicked: createStackDialog.performCreate()
                }

                DankButton {
                    text: I18n.tr("Cancel")
                    backgroundColor: Theme.surfaceContainerHigh
                    textColor: Theme.surfaceText
                    onClicked: createStackDialog.close()
                }
            }
        }
    }

    function showFor(paths) {
        createStackDialog.selectedPaths = paths || [];
        if (createStackDialog.inputField) {
            createStackDialog.inputField.text = "New Stack";
        }
        createStackDialog.open();
    }

    function performCreate() {
        if (!createStackDialog.inputField) {
            createStackDialog.close();
            return;
        }
        const name = createStackDialog.inputField.text.trim();
        if (name.length === 0) {
            createStackDialog.close();
            return;
        }

        root.createStack(name, createStackDialog.selectedPaths);
        createStackDialog.close();
    }
}

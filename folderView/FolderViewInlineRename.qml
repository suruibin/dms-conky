import QtQuick
import qs.Common
import qs.Widgets

// In-place filename editor used by the FolderView item delegates. It replaces
// an item's name label while the user renames it. Emits accepted() with the
// trimmed new base name (the extension is re-applied by the caller) or
// canceled() when the edit is dismissed. Host it in a Loader sized to the
// label it replaces; the Loader can derive its height from implicitHeight.
FocusScope {
    id: editor

    property string targetName: ""
    property bool targetIsDir: false
    property int fontPixelSize: Theme.fontSizeSmall

    signal accepted(string newBaseName)
    signal canceled

    // Guarantees exactly one of accepted()/canceled() is emitted, even though
    // the text field fires editingFinished again as it is torn down.
    property bool _finished: false

    implicitWidth: 200
    implicitHeight: Math.round(fontPixelSize + 14)

    function _baseName() {
        let name = String(editor.targetName);
        if (!editor.targetIsDir) {
            const lastDot = name.lastIndexOf(".");
            if (lastDot > 0)
                return name.substring(0, lastDot);
        }
        return name;
    }

    function commit() {
        if (editor._finished)
            return;
        editor._finished = true;
        editor.accepted(field.text.trim());
    }

    function cancel() {
        if (editor._finished)
            return;
        editor._finished = true;
        editor.canceled();
    }

    Keys.onEscapePressed: event => {
        event.accepted = true;
        editor.cancel();
    }

    Keys.onLeftPressed: event => event.accepted = true
    Keys.onRightPressed: event => event.accepted = true
    Keys.onUpPressed: event => event.accepted = true
    Keys.onDownPressed: event => event.accepted = true

    DankTextField {
        id: field

        anchors.fill: parent
        topPadding: Theme.spacingXS
        bottomPadding: Theme.spacingXS
        font.pixelSize: editor.fontPixelSize
        placeholderText: I18n.tr("Enter new name...")
        onAccepted: editor.commit()
        onEditingFinished: editor.commit()
    }

    Component.onCompleted: {
        Qt.callLater(() => {
            // The editor can be torn down within the same tick (e.g. the item
            // is removed from the model), so the deferred field may be gone.
            if (!field)
                return;
            field.text = editor._baseName();
            field.forceActiveFocus();
            field.selectAll();
        });
    }
}

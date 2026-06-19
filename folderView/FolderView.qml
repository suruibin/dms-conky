import QtQuick
import QtQuick.Controls
import Qt.labs.folderlistmodel
import Qt.labs.platform as Platform
import Quickshell
import Quickshell.Widgets
import qs.Common
import qs.Widgets
import qs.Services
import qs.Modules.Plugins
import QtQuick.Dialogs
import "./dms-common"

DesktopPluginComponent {
    id: root

    property bool acceptsKeyboardFocus: true


    // Desktop widget dimensions
    minWidth: 200
    minHeight: 200
    
    // Default initial size if not set
    widgetWidth: pluginData.widgetWidth ?? 320
    widgetHeight: pluginData.widgetHeight ?? 400

    // Settings config
    readonly property real backgroundOpacity: (pluginData.backgroundOpacity ?? 80) / 100
    readonly property real borderOpacity: (pluginData.borderOpacity ?? 0) / 100
    property bool showHidden: pluginData.showHidden ?? false
    property int cellSize: pluginData.cellSize ?? 84
    readonly property double sizeScale: cellSize / 84.0
    readonly property string sortBy: pluginData.sortBy ?? "name"
    readonly property string viewMode: pluginData.viewMode ?? "grid"
    readonly property string headerPosition: pluginData.headerPosition ?? "top"
    property bool showHeader: pluginData.showHeader ?? true
    readonly property var pinnedPaths: pluginData.pinnedPaths ?? []
    onPinnedPathsChanged: { updateFilteredModel(); buildFolderDropdownModel(); }

    property var folderDropdownModel: []
    property var stacks: pluginData.stacks ?? []
    onStacksChanged: updateFilteredModel()
    property var expandedStackIds: []

    readonly property bool isScrolledDown: viewMode === "grid"
        ? (typeof fileGrid !== "undefined" && fileGrid ? fileGrid.contentY > 50 : false)
        : viewMode === "list"
        ? (typeof fileList !== "undefined" && fileList ? fileList.contentY > 50 : false)
        : viewMode === "compact"
        ? (typeof fileCompact !== "undefined" && fileCompact ? fileCompact.contentY > 50 : false)
        : false

    // Resolved Folder Settings & URL
    readonly property string folderType: pluginData.folderType ?? "desktop"
    readonly property string customFolderPath: pluginData.customFolderPath ?? ""

    readonly property string targetFolderUrl: {
        switch (folderType) {
            case "home":
                return Platform.StandardPaths.writableLocation(Platform.StandardPaths.HomeLocation).toString();
            case "downloads":
                return Platform.StandardPaths.writableLocation(Platform.StandardPaths.DownloadLocation).toString();
            case "music":
                return Platform.StandardPaths.writableLocation(Platform.StandardPaths.MusicLocation).toString();
            case "pictures":
                return Platform.StandardPaths.writableLocation(Platform.StandardPaths.PicturesLocation).toString();
            case "videos":
                return Platform.StandardPaths.writableLocation(Platform.StandardPaths.MoviesLocation).toString();
            case "documents":
                return Platform.StandardPaths.writableLocation(Platform.StandardPaths.DocumentsLocation).toString();
            case "trash":
                return Platform.StandardPaths.writableLocation(Platform.StandardPaths.HomeLocation).toString() + "/.local/share/Trash/files";
            case "custom": {
                if (customFolderPath && customFolderPath.trim() !== "") {
                    const clean = customFolderPath.trim();
                    if (clean.startsWith("~/")) {
                        return Platform.StandardPaths.writableLocation(Platform.StandardPaths.HomeLocation).toString() + clean.substring(1);
                    }
                    return "file://" + clean;
                }
                return Platform.StandardPaths.writableLocation(Platform.StandardPaths.DesktopLocation).toString();
            }
            default:
                return Platform.StandardPaths.writableLocation(Platform.StandardPaths.DesktopLocation).toString();
        }
    }

    readonly property string folderDisplayName: {
        switch (folderType) {
            case "home": return I18n.tr("Home");
            case "desktop": return I18n.tr("Desktop");
            case "downloads": return I18n.tr("Downloads");
            case "music": return I18n.tr("Music");
            case "pictures": return I18n.tr("Pictures");
            case "videos": return I18n.tr("Videos");
            case "documents": return I18n.tr("Documents");
            case "trash": return I18n.tr("Trash");
            case "custom":
                if (customFolderPath) {
                    const parts = customFolderPath.trim().split("/");
                    return parts[parts.length - 1] || I18n.tr("Folder");
                }
                return I18n.tr("Folder");
            default: return I18n.tr("Folder");
        }
    }

    // Sorting field mapper
    readonly property int folderSortField: {
        switch (sortBy) {
            case "time": return FolderListModel.Time;
            case "size": return FolderListModel.Size;
            case "type": return FolderListModel.Type;
            default: return FolderListModel.Name;
        }
    }

    // Selected file tracking
    property var selectedFilePaths: []
    property var selectedPathsSet: ({})
    property string lastSelectedFilePath: ""
    property string searchPattern: ""
    property string selectedFileInfo: ""
    property string emptyColor: pluginData.emptyColor ?? "#FF1744"
    property string folderColor: pluginData.folderColor ?? ""

    // Inline rename state: file path of the item currently renamed in place
    // ("" when no item is being renamed). _inlineRenameArmPath holds the path
    // queued by inlineRenameArmTimer until it fires.
    property string renamingFilePath: ""
    property string _inlineRenameArmPath: ""

    function clearSelection() {
        selectedFilePaths = [];
        selectedPathsSet = ({});
        lastSelectedFilePath = "";
    }

    function toggleSelection(filePath) {
        let arr = [];
        for (let i = 0; i < root.selectedFilePaths.length; i++)
            arr.push(root.selectedFilePaths[i]);
        let idx = arr.indexOf(filePath);
        if (idx === -1) {
            arr.push(filePath);
        } else {
            arr.splice(idx, 1);
        }
        let set = ({});
        for (let i = 0; i < arr.length; i++)
            set[arr[i]] = true;
        selectedPathsSet = set;
        selectedFilePaths = arr;
        lastSelectedFilePath = filePath;
        selectionClearTimer.restart();
    }

    function selectSingle(filePath) {
        let set = ({});
        set[filePath] = true;
        selectedPathsSet = set;
        selectedFilePaths = [filePath];
        lastSelectedFilePath = filePath;
        selectionClearTimer.restart();
    }

    function selectRangeTo(currentIndex) {
        if (lastSelectedFilePath === "") {
            if (filteredModel.count > currentIndex) {
                selectSingle(filteredModel.get(currentIndex).filePath);
            }
            return;
        }

        let lastIndex = -1;
        for (let i = 0; i < filteredModel.count; i++) {
            if (filteredModel.get(i).filePath === lastSelectedFilePath) {
                lastIndex = i;
                break;
            }
        }

        if (lastIndex === -1) {
            if (filteredModel.count > currentIndex) {
                selectSingle(filteredModel.get(currentIndex).filePath);
            }
            return;
        }

        let start = Math.min(lastIndex, currentIndex);
        let end = Math.max(lastIndex, currentIndex);
        let newSelection = [];
        for (let i = 0; i < root.selectedFilePaths.length; i++)
            newSelection.push(root.selectedFilePaths[i]);

        let newSet = ({});
        for (let i = 0; i < newSelection.length; i++)
            newSet[newSelection[i]] = true;

        for (let i = start; i <= end; i++) {
            let path = filteredModel.get(i).filePath;
            if (!newSet[path]) {
                newSet[path] = true;
                newSelection.push(path);
            }
        }
        selectedPathsSet = newSet;
        selectedFilePaths = newSelection;
        selectionClearTimer.restart();
    }

    function _cleanPath(url) {
        let path = String(url);
        if (path.startsWith("file://")) {
            path = path.substring(7);
        }
        if (path.startsWith("localhost/")) {
            path = path.substring(9);
        }
        return path;
    }

    // Single source of truth for renaming, shared by the inline editor and the
    // rename dialog. Handles both virtual stacks and on-disk files; the
    // extension is preserved from oldName for files.
    function applyRename(rawPath, oldName, isDir, newBaseName) {
        try {
            const trimmed = String(newBaseName).trim();
            if (trimmed.length === 0)
                return;

            // A slash would turn the rename into a move into another directory
            // (or an invalid path), so reject it.
            if (trimmed.indexOf("/") !== -1) {
                ToastService.showToast(I18n.tr("Rename failed") + ": " + I18n.tr("Name cannot contain slashes"), ToastService.levelError);
                return;
            }

            let ext = "";
            if (!isDir) {
                const lastDot = String(oldName).lastIndexOf(".");
                if (lastDot > 0)
                    ext = String(oldName).substring(lastDot);
            }
            const newName = trimmed + ext;
            if (newName === String(oldName))
                return;

            let pathStr = String(rawPath);
            if (pathStr.startsWith("stack://")) {
                root.renameStack(pathStr.substring(8), trimmed);
                return;
            }

            pathStr = root._cleanPath(pathStr);
            if (!pathStr || pathStr.length === 0)
                return;

            const parts = pathStr.split("/");
            parts.pop();
            const newPath = parts.join("/") + "/" + newName;
            Quickshell.execDetached(["mv", pathStr, newPath]);
        } catch (e) {
            ToastService.showToast(I18n.tr("Rename failed") + ": " + e.message, ToastService.levelError);
        }
    }

    function armInlineRename(filePath) {
        root._inlineRenameArmPath = filePath;
        inlineRenameArmTimer.restart();
    }

    // Shared by all three view delegates: a left click on the name label of an
    // item that is already the sole selection arms an inline rename; any other
    // left click just (re)selects the item.
    function handleItemLabelClick(mouseArea, labelItem, mouseX, mouseY, filePath) {
        const lp = mouseArea.mapToItem(labelItem, mouseX, mouseY);
        const onLabel = labelItem.visible && lp.x >= 0 && lp.x <= labelItem.width && lp.y >= 0 && lp.y <= labelItem.height;
        const wasSole = root.selectedFilePaths.length === 1 && root.selectedFilePaths[0] === filePath;
        if (wasSole && onLabel) {
            root.armInlineRename(filePath);
        } else {
            root.selectSingle(filePath);
        }
    }

    function isPathInFilteredModel(path) {
        for (let i = 0; i < filteredModel.count; i++) {
            if (filteredModel.get(i).filePath === path)
                return true;
        }
        return false;
    }

    function beginInlineRename(filePath) {
        inlineRenameArmTimer.stop();
        // The item may have vanished during the arm delay (e.g. deleted by
        // another process). Don't enter a rename that no delegate can ever
        // dismiss, which would leave renamingFilePath stuck non-empty.
        if (!isPathInFilteredModel(filePath))
            return;
        root.renamingFilePath = filePath;
    }

    function endInlineRename() {
        inlineRenameArmTimer.stop();
        // Clear on the next tick: this runs from inside the inline editor's own
        // signal handler, so flipping renamingFilePath here would tear the
        // editor down while it is still emitting.
        Qt.callLater(() => {
            root.renamingFilePath = "";
        });
    }

    function dragMimeData(filePath) {
        // Dragging an item that is part of the current selection drags the
        // whole selection; otherwise just the pressed item.
        let paths = (root.selectedFilePaths.length > 0 && root.selectedFilePaths.indexOf(filePath) !== -1)
            ? root.selectedFilePaths
            : [filePath];
        paths = paths.filter(p => !String(p).startsWith("stack://")).map(p => root._cleanPath(p));
        const uris = paths.map(p => "file://" + p.split("/").map(encodeURIComponent).join("/"));
        return {
            "text/uri-list": uris.join("\r\n") + "\r\n",
            "text/plain": paths.join("\n")
        };
    }

    function launchDesktopFile(path) {
        let cleanPath = root._cleanPath(path);
        let shellCmd = 'cmd=$(grep -m 1 "^Exec=" "' + cleanPath + '" | cut -d= -f2- | sed "s/%[fFuUiIcDkKvV]//g"); exec sh -c "$cmd"';
        Quickshell.execDetached(["sh", "-c", shellCmd]);
    }

    // Folder navigation
    property var folderHistory: []
    property var forwardHistory: []
    function resolveStandardFolderPath(type) {
        switch (type) {
            case "home": return Platform.StandardPaths.writableLocation(Platform.StandardPaths.HomeLocation).toString();
            case "desktop": return Platform.StandardPaths.writableLocation(Platform.StandardPaths.DesktopLocation).toString();
            case "downloads": return Platform.StandardPaths.writableLocation(Platform.StandardPaths.DownloadLocation).toString();
            case "music": return Platform.StandardPaths.writableLocation(Platform.StandardPaths.MusicLocation).toString();
            case "pictures": return Platform.StandardPaths.writableLocation(Platform.StandardPaths.PicturesLocation).toString();
            case "videos": return Platform.StandardPaths.writableLocation(Platform.StandardPaths.MoviesLocation).toString();
            case "documents": return Platform.StandardPaths.writableLocation(Platform.StandardPaths.DocumentsLocation).toString();
            case "trash": return Platform.StandardPaths.writableLocation(Platform.StandardPaths.HomeLocation).toString() + "/.local/share/Trash/files";
            default: return "";
        }
    }

    function navigateToFolder(folderPath) {
        let cleanPath = root._cleanPath(String(folderPath));
        let current = root.targetFolderUrl;
        let currentClean = root._cleanPath(String(current));
        if (currentClean !== cleanPath) {
            let hist = [];
            for (let i = 0; i < root.folderHistory.length; i++)
                hist.push(root.folderHistory[i]);
            if (hist.length === 0 || hist[hist.length - 1] !== currentClean)
                hist.push(currentClean);
            root.folderHistory = hist;
            root.forwardHistory = [];
        }
        let url = cleanPath.startsWith("file://") ? cleanPath : "file://" + cleanPath;
        folderModel.folder = url;
        if (pluginService) {
            pluginService.savePluginData(pluginId, "customFolderPath", cleanPath);
            pluginService.savePluginData(pluginId, "folderType", "custom");
        }
    }

    function goBackFolder() {
        let hist = [];
        for (let i = 0; i < root.folderHistory.length; i++)
            hist.push(root.folderHistory[i]);
        if (hist.length > 0) {
            let currentClean = root._cleanPath(String(root.targetFolderUrl));
            let fwd = [];
            for (let i = 0; i < root.forwardHistory.length; i++)
                fwd.push(root.forwardHistory[i]);
            fwd.push(currentClean);
            root.forwardHistory = fwd;
            let prev = hist.pop();
            root.folderHistory = hist;
            let url = prev.startsWith("file://") ? prev : "file://" + prev;
            folderModel.folder = url;
            if (pluginService) {
                pluginService.savePluginData(pluginId, "customFolderPath", prev);
                pluginService.savePluginData(pluginId, "folderType", "custom");
            }
        }
    }

    function goForwardFolder() {
        let fwd = [];
        for (let i = 0; i < root.forwardHistory.length; i++)
            fwd.push(root.forwardHistory[i]);
        if (fwd.length > 0) {
            let currentClean = root._cleanPath(String(root.targetFolderUrl));
            let hist = [];
            for (let i = 0; i < root.folderHistory.length; i++)
                hist.push(root.folderHistory[i]);
            hist.push(currentClean);
            root.folderHistory = hist;
            let next = fwd.pop();
            root.forwardHistory = fwd;
            let url = next.startsWith("file://") ? next : "file://" + next;
            folderModel.folder = url;
            if (pluginService) {
                pluginService.savePluginData(pluginId, "customFolderPath", next);
                pluginService.savePluginData(pluginId, "folderType", "custom");
            }
        }
    }

    function togglePin(filePath) {
        if (!pluginService) return;
        let pins = [];
        for (let i = 0; i < root.pinnedPaths.length; i++) {
            pins.push(root.pinnedPaths[i]);
        }
        let index = pins.indexOf(filePath);
        if (index !== -1) {
            pins.splice(index, 1);
        } else {
            pins.push(filePath);
        }
        pluginService.savePluginData(pluginId, "pinnedPaths", pins);
    }

    function pasteFromClipboard() {
        let scriptPath = decodeURIComponent(root._cleanPath(Qt.resolvedUrl("paste.py")));
        let pathStr = decodeURIComponent(root._cleanPath(root.targetFolderUrl));

        ToastService.showToast(I18n.tr("Pasting files..."), ToastService.levelInfo);
        Quickshell.execDetached([scriptPath, pathStr]);
    }

    function dropFiles(urls) {
        // Copy files dragged in from external windows into the current folder.
        let fileUris = urls.map(u => String(u)).filter(u => u.startsWith("file://"));
        if (fileUris.length === 0) return;

        let scriptPath = decodeURIComponent(root._cleanPath(Qt.resolvedUrl("paste.py")));
        let pathStr = decodeURIComponent(root._cleanPath(root.targetFolderUrl));

        ToastService.showToast(I18n.tr("Copying files..."), ToastService.levelInfo);
        Quickshell.execDetached([scriptPath, "--drop", pathStr].concat(fileUris));
    }

    onSelectedFilePathsChanged: {
        // A changed selection means any pending click-to-rename no longer
        // targets the clicked item.
        inlineRenameArmTimer.stop();
        if (selectedFilePaths.length > 0) {
            selectionClearTimer.restart();
        } else {
            selectionClearTimer.stop();
        }

        // Update selected file info for header display
        if (selectedFilePaths.length === 1) {
            const selPath = selectedFilePaths[0];
            let info = "";
            for (let i = 0; i < filteredModel.count; i++) {
                const item = filteredModel.get(i);
                if (item.filePath === selPath) {
                    const name = String(item.fileName || "");
                    const mtime = item.fileModified ? root.formatDate(item.fileModified) : "";
                    const isDir = item.fileIsDir;
                    const size = (!isDir && item.fileSize) ? root.formatFileSize(item.fileSize) : "";
                    const parts = [name];
                    if (mtime) parts.push(mtime);
                    if (size) parts.push(size);
                    info = parts.join("  ");
                    break;
                }
            }
            root.selectedFileInfo = info;
        } else {
            root.selectedFileInfo = "";
        }
    }

    Timer {
        id: selectionClearTimer
        interval: 5000 // 5 seconds of inactivity
        repeat: false
        onTriggered: {
            if (!renameDialog.opened && !quickMenu.opened && root.renamingFilePath === "") {
                clearSelection();
            } else {
                selectionClearTimer.restart();
            }
        }
    }

    // Delays click-to-rename so a double-click (open) cancels it first.
    Timer {
        id: inlineRenameArmTimer
        interval: 400 // ~ system double-click interval
        repeat: false
        onTriggered: root.beginInlineRename(root._inlineRenameArmPath)
    }

    Component.onDestruction: {
        selectionClearTimer.stop();
        inlineRenameArmTimer.stop();
    }
    Component.onCompleted: buildFolderDropdownModel()

    ListModel {
        id: filteredModel
    }

    function updateFilteredModel() {
        filteredModel.clear();
        if (folderModel.status !== FolderListModel.Ready) return;
        
        const pattern = root.searchPattern.toLowerCase();
        let pinnedDirs = [];
        let pinnedFiles = [];
        let unpinnedDirs = [];
        let unpinnedFiles = [];

        // Load stacks in this folder and get list of files in collapsed stacks
        let currentFolderStacks = [];
        let collapsedFilePaths = new Set();
        let fileToExpandedStackMap = {}; // filePath -> stackId
        let expandedStackFilesMap = {}; // stackId -> array of item objects
        try {
            let sList = root.stacks || [];
            currentFolderStacks = sList.filter(s => s.folder === root.targetFolderUrl);
            
            // Sort stacks based on sortBy setting
            if (root.sortBy === "time") {
                currentFolderStacks.sort((a, b) => b.id.localeCompare(a.id));
            } else {
                currentFolderStacks.sort((a, b) => a.name.localeCompare(b.name, undefined, {numeric: true, sensitivity: 'base'}));
            }

            for (let s of currentFolderStacks) {
                let isExpanded = root.expandedStackIds.indexOf(s.id) !== -1;
                if (!isExpanded) {
                    for (let p of s.filePaths) {
                        collapsedFilePaths.add(p);
                    }
                } else {
                    for (let p of s.filePaths) {
                        fileToExpandedStackMap[p] = s.id;
                    }
                }
            }
        } catch (e) {
            console.log("Error loading stacks: " + e);
        }

        for (let i = 0; i < folderModel.count; i++) {
            try {
                const fName = folderModel.get(i, "fileName");
                const fPath = folderModel.get(i, "filePath");
                const fIsDir = folderModel.get(i, "fileIsDir");
                const fModified = folderModel.get(i, "fileModified");
                const fSize = folderModel.get(i, "fileSize") || 0;
                
                if (fName === undefined || fName === null || fPath === undefined || fPath === null) {
                    continue;
                }
                
                const nameStr = String(fName);
                let pathStr = String(fPath);

                // Skip file if it is in a collapsed stack
                if (collapsedFilePaths.has(pathStr)) {
                    continue;
                }
                
                // Extract extension once for all subsequent checks
                const ext = nameStr.includes(".") ? nameStr.split(".").pop().toLowerCase() : "";
                const isDir = !!fIsDir;

                // 1. Search Pattern filter check
                if (pattern !== "" && nameStr.toLowerCase().indexOf(pattern) === -1) {
                    continue;
                }

                // 2. File Type filter check (inlined extension checks — avoids 3 function calls per item)
                if (root.filterType !== "all") {
                    if (root.filterType === "folders" && !isDir) continue;
                    if (root.filterType === "files" && isDir) continue;
                    if (root.filterType === "images" && (isDir || ["jpg","jpeg","png","gif","webp","svg","bmp"].indexOf(ext) === -1)) continue;
                    if (root.filterType === "documents" && (isDir || ["doc","docx","pdf","txt","odt","xls","xlsx","ppt","pptx","md","csv"].indexOf(ext) === -1)) continue;
                    if (root.filterType === "audio_video" && (isDir || ["mp3","wav","ogg","flac","m4a","mp4","mkv","avi","mov","webm","flv"].indexOf(ext) === -1)) continue;
                }

                // 3. Time filter check
                if (root.filterTime !== "all" && fModified !== undefined && fModified !== null) {
                    const elapsed = new Date() - fModified;
                    if (root.filterTime === "today" && elapsed > 24 * 60 * 60 * 1000) continue;
                    if (root.filterTime === "week" && elapsed > 7 * 24 * 60 * 60 * 1000) continue;
                    if (root.filterTime === "month" && elapsed > 30 * 24 * 60 * 60 * 1000) continue;
                    if (root.filterTime === "year" && elapsed > 365 * 24 * 60 * 60 * 1000) continue;
                }

                let isDesktop = nameStr.endsWith(".desktop") && !isDir;
                let displayBaseName = isDesktop ? nameStr.slice(0, -8) : nameStr;
                let itemType = root.getItemType(nameStr, !!fIsDir);
                let iconName = root.getIconName(nameStr, !!fIsDir);
                let iconColor = root.getIconColor(nameStr, !!fIsDir);
                let isEmpty = !fIsDir ? (fSize === 0) : false;
                let item = {
                    filePath: pathStr,
                    fileName: nameStr,
                    displayBaseName: displayBaseName,
                    fileIsDir: !!fIsDir,
                    itemType: itemType,
                    iconName: iconName,
                    iconColor: iconColor,
                    fileModified: fModified,
                    fileSize: fSize,
                    isEmpty: isEmpty,
                    isDesktop: isDesktop,
                    appName: "",
                    appIcon: "",
                    appExec: "",
                    isStack: false,
                    isExpanded: false,
                    belongingStackId: ""
                };

                // Async check: empty folders
                if (fIsDir) {
                    let checkPath = root._cleanPath(pathStr);
                    let safePath = checkPath.replace(/'/g, "'\\''");
                    Proc.runCommand("emptyCheck-" + Math.random(), ["sh", "-c", "ls -A '" + safePath + "' 2>/dev/null | head -1 | wc -l"], (out, code) => {
                        if (code === 0) {
                            let hasContent = parseInt(String(out).trim()) > 0;
                            for (let k = 0; k < filteredModel.count; k++) {
                                if (filteredModel.get(k).filePath === pathStr) {
                                    filteredModel.setProperty(k, "isEmpty", !hasContent);
                                    break;
                                }
                            }
                        }
                    });
                }
                
                let expandedStackId = fileToExpandedStackMap[pathStr];
                if (expandedStackId !== undefined) {
                    item.belongingStackId = expandedStackId;
                    if (!expandedStackFilesMap[expandedStackId]) {
                        expandedStackFilesMap[expandedStackId] = [];
                    }
                    expandedStackFilesMap[expandedStackId].push(item);
                    
                    if (isDesktop) {
                        let safePath = root._cleanPath(pathStr);
                        Proc.runCommand("parseDesktop-" + Math.random(), ["cat", safePath], (out, code) => {
                            if (code === 0 && out) {
                                let aName = "";
                                let aIcon = "";
                                let aExec = "";
                                let lines = out.split('\n');
                                for (let j = 0; j < lines.length; j++) {
                                    let l = lines[j].trim();
                                    if (l.startsWith("Name=") && !aName) aName = l.substring(5).trim();
                                    else if (l.startsWith("Icon=") && !aIcon) aIcon = l.substring(5).trim();
                                    else if (l.startsWith("Exec=") && !aExec) aExec = l.substring(5).trim();
                                }
                                
                                let targetIdx = -1;
                                for (let k = 0; k < filteredModel.count; k++) {
                                    if (filteredModel.get(k).filePath === pathStr) {
                                        targetIdx = k;
                                        break;
                                    }
                                }
                                
                                if (targetIdx !== -1) {
                                    filteredModel.setProperty(targetIdx, "appName", aName);
                                    filteredModel.setProperty(targetIdx, "appIcon", aIcon);
                                    filteredModel.setProperty(targetIdx, "appExec", aExec);
                                    filteredModel.setProperty(targetIdx, "displayBaseName", aName);
                                }
                            }
                        });
                    }
                    continue; // Skip partitioning to general list
                }

                if (isDesktop) {
                    let safePath = root._cleanPath(pathStr);
                    Proc.runCommand("parseDesktop-" + Math.random(), ["cat", safePath], (out, code) => {
                        if (code === 0 && out) {
                            let aName = "";
                            let aIcon = "";
                            let aExec = "";
                            let lines = out.split('\n');
                            for (let j = 0; j < lines.length; j++) {
                                let l = lines[j].trim();
                                if (l.startsWith("Name=") && !aName) aName = l.substring(5).trim();
                                else if (l.startsWith("Icon=") && !aIcon) aIcon = l.substring(5).trim();
                                else if (l.startsWith("Exec=") && !aExec) aExec = l.substring(5).trim();
                            }
                            
                            // Find the item index since model might have changed
                            let targetIdx = -1;
                            for (let k = 0; k < filteredModel.count; k++) {
                                if (filteredModel.get(k).filePath === pathStr) {
                                    targetIdx = k;
                                    break;
                                }
                            }
                            
                            if (targetIdx !== -1) {
                                filteredModel.setProperty(targetIdx, "appName", aName);
                                filteredModel.setProperty(targetIdx, "appIcon", aIcon);
                                filteredModel.setProperty(targetIdx, "appExec", aExec);
                                filteredModel.setProperty(targetIdx, "displayBaseName", aName);
                            }
                        }
                    });
                }

                let isPinned = root.pinnedPaths.indexOf(pathStr) !== -1;
                if (isPinned) {
                    if (fIsDir) {
                        pinnedDirs.push(item);
                    } else {
                        pinnedFiles.push(item);
                    }
                } else {
                    if (fIsDir) {
                        unpinnedDirs.push(item);
                    } else {
                        unpinnedFiles.push(item);
                    }
                }
            } catch (e) {
                console.log("Error processing file at index " + i + ": " + e);
            }
        }
        
        let pinnedStacks = [];
        let unpinnedStacks = [];

        // Append virtual stack items to pinnedStacks or unpinnedStacks
        for (let s of currentFolderStacks) {
            let isExpanded = root.expandedStackIds.indexOf(s.id) !== -1;
            let stackItem = {
                filePath: "stack://" + s.id,
                fileName: s.name,
                fileIsDir: true,
                isDesktop: false,
                displayBaseName: s.name,
                itemType: "dir",
                iconName: "layers",
                iconColor: Theme.primary,
                isEmpty: false,
                appName: "",
                appIcon: "",
                appExec: "",
                isStack: true,
                isExpanded: isExpanded,
                belongingStackId: isExpanded ? s.id : ""
            };
            
            let isPinned = root.pinnedPaths.indexOf("stack://" + s.id) !== -1;
            if (isPinned) {
                pinnedStacks.push(stackItem);
            } else {
                unpinnedStacks.push(stackItem);
            }
        }

        // 1. Pinned Stacks
        pinnedStacks.forEach(function(item) {
            filteredModel.append(item);
            if (item.isStack && item.isExpanded) {
                let sFiles = expandedStackFilesMap[item.belongingStackId] || [];
                sFiles.forEach(function(f) {
                    filteredModel.append(f);
                });
            }
        });

        // 2. Pinned Directories
        pinnedDirs.forEach(function(item) { filteredModel.append(item); });

        // 3. Pinned Files
        pinnedFiles.forEach(function(item) { filteredModel.append(item); });
        
        // 4. Unpinned Stacks
        unpinnedStacks.forEach(function(item) {
            filteredModel.append(item);
            if (item.isStack && item.isExpanded) {
                let sFiles = expandedStackFilesMap[item.belongingStackId] || [];
                sFiles.forEach(function(f) {
                    filteredModel.append(f);
                });
            }
        });

        // 5. Unpinned Directories
        unpinnedDirs.forEach(function(item) { filteredModel.append(item); });
        
        // 6. Unpinned Files
        unpinnedFiles.forEach(function(item) { filteredModel.append(item); });

        // Release the inline-rename lock if the edited item is no longer present
        // after this refresh (e.g. it was trashed/moved while being renamed),
        // otherwise renamingFilePath stays stuck and selectionClearTimer never
        // clears the selection again.
        if (root.renamingFilePath !== "" && !isPathInFilteredModel(root.renamingFilePath)) {
            inlineRenameArmTimer.stop();
            root.renamingFilePath = "";
        }
    }

    function createStack(stackName, filePaths) {
        let newStack = {
            "id": "stack_" + Date.now() + "_" + Math.floor(Math.random() * 1000),
            "name": stackName,
            "folder": root.targetFolderUrl,
            "filePaths": filePaths
        };
        let newStacks = [...stacks, newStack];
        root.stacks = newStacks;
        if (pluginService) {
            pluginService.savePluginData(pluginId, "stacks", newStacks);
        }
        clearSelection();
        updateFilteredModel();
    }

    function renameStack(stackId, newName) {
        let newStacks = stacks.map(s => {
            if (s.id === stackId) {
                s.name = newName;
            }
            return s;
        });
        root.stacks = newStacks;
        if (pluginService) {
            pluginService.savePluginData(pluginId, "stacks", newStacks);
        }
        updateFilteredModel();
    }

    function ungroupStack(stackId) {
        let newStacks = stacks.filter(s => s.id !== stackId);
        root.stacks = newStacks;
        if (pluginService) {
            pluginService.savePluginData(pluginId, "stacks", newStacks);
        }
        expandedStackIds = expandedStackIds.filter(id => id !== stackId);
        clearSelection();
        updateFilteredModel();
    }

    function toggleStackExpanded(stackId) {
        let arr = [...expandedStackIds];
        let idx = arr.indexOf(stackId);
        if (idx === -1) {
            arr.push(stackId);
        } else {
            arr.splice(idx, 1);
        }
        expandedStackIds = arr;
        updateFilteredModel();
    }

    onSearchPatternChanged: updateFilteredModel()
 
    // Basic Filtering Properties
    property string filterType: "all"
    property string filterTime: "all"
    onFilterTypeChanged: updateFilteredModel()
    onFilterTimeChanged: updateFilteredModel()
    onFolderColorChanged: updateFilteredModel()

    function scrollToTop() {
        if (viewMode === "grid" && typeof fileGrid !== "undefined" && fileGrid) {
            fileGrid.contentY = 0;
        } else if (viewMode === "list" && typeof fileList !== "undefined" && fileList) {
            fileList.contentY = 0;
        } else if (viewMode === "compact" && typeof fileCompact !== "undefined" && fileCompact) {
            fileCompact.contentY = 0;
        }
    }

    function buildFolderDropdownModel() {
        var items = [
            { label: I18n.tr("Home"), value: "home", icon: "home" },
            { label: I18n.tr("Desktop"), value: "desktop", icon: "desktop_mac" },
            { label: I18n.tr("Downloads"), value: "downloads", icon: "download" },
            { label: I18n.tr("Music"), value: "music", icon: "music_note" },
            { label: I18n.tr("Pictures"), value: "pictures", icon: "image" },
            { label: I18n.tr("Videos"), value: "videos", icon: "movie" },
            { label: I18n.tr("Documents"), value: "documents", icon: "description" },
            { label: I18n.tr("Trash"), value: "trash", icon: "delete" }
        ];

        // Resolve home as clean filesystem path (strip file:// if present)
        var homeUrl = Platform.StandardPaths.writableLocation(Platform.StandardPaths.HomeLocation).toString();
        var homePath = homeUrl;
        if (homePath.indexOf("file://") === 0) homePath = homePath.substring(7);

        // Collect standard paths (clean paths, no file:// prefix) to skip duplicates
        var stdPaths = {};
        stdPaths[homePath] = true;
        stdPaths[homePath + "/Desktop"] = true;
        stdPaths[homePath + "/Downloads"] = true;
        stdPaths[homePath + "/Music"] = true;
        stdPaths[homePath + "/Pictures"] = true;
        stdPaths[homePath + "/Videos"] = true;
        stdPaths[homePath + "/Documents"] = true;

        // Read GTK bookmarks (system file manager favorites)
        var bookmarkItems = [];
        try {
            var bkUrl = homeUrl;
            if (bkUrl.charAt(bkUrl.length - 1) !== "/") bkUrl += "/";
            bkUrl += ".config/gtk-3.0/bookmarks";
            var xhr = new XMLHttpRequest();
            xhr.open("GET", bkUrl, false);
            xhr.send();
            if (xhr.status === 0 || xhr.status === 200) {
                var lines = xhr.responseText.split("\n");
                for (var bi = 0; bi < lines.length; bi++) {
                    var line = String(lines[bi]).trim();
                    if (line === "") continue;
                    // Format: "file:///path optional_label"
                    var spaceIdx = line.indexOf(" ");
                    var uri = spaceIdx >= 0 ? line.substring(0, spaceIdx) : line;
                    var label = spaceIdx >= 0 ? line.substring(spaceIdx + 1).trim() : "";
                    var filePath = decodeURIComponent(uri);
                    if (filePath.indexOf("file://") === 0) filePath = filePath.substring(7);

                    // Skip if matches a standard path
                    if (stdPaths[filePath] !== undefined) continue;
                    // Skip home root or empty
                    if (filePath === "" || filePath === homePath) continue;

                    var displayName = label || filePath.split("/").filter(function(s) { return s !== ""; }).pop() || filePath;
                    bookmarkItems.push({ label: displayName, value: "bookmark", icon: "bookmark", path: filePath });
                }
            }
        } catch (e) {}

        // Add bookmarks section
        if (bookmarkItems.length > 0) {
            items.push({ value: "separator", icon: "", label: "" });
            for (var bj = 0; bj < bookmarkItems.length; bj++) {
                items.push(bookmarkItems[bj]);
            }
        }

        // Add pinnedPaths (folderView's own pin-to-top items)
        var pins = root.pinnedPaths || [];
        var hasPins = false;
        for (var pi = 0; pi < pins.length; pi++) {
            if (String(pins[pi]).indexOf("stack://") !== 0) { hasPins = true; break; }
        }

        if (hasPins) {
            items.push({ value: "separator", icon: "", label: "" });
            for (var i = 0; i < pins.length; i++) {
                var pinPath = String(pins[i]);
                if (pinPath.indexOf("stack://") === 0) continue;
                var parts = pinPath.split("/");
                var name = parts[parts.length - 1] || pinPath;
                items.push({ label: name, value: "pinned", icon: "push_pin", path: pinPath });
            }
        }

        items.push({ label: I18n.tr("Custom..."), value: "custom", icon: "folder" });
        root.folderDropdownModel = items;
    }

    Connections {
        target: folderModel
        function onStatusChanged() {
            if (folderModel.status === FolderListModel.Ready) {
                updateFilteredModel();
            }
        }
        function onCountChanged() {
            updateFilteredModel();
        }
    }

    function formatFileSize(bytes) {
        if (!bytes || bytes <= 0) return "";
        const units = ["B", "KB", "MB", "GB", "TB"];
        let i = 0;
        let size = bytes;
        while (size >= 1024 && i < units.length - 1) { size /= 1024; i++; }
        return size.toFixed(i === 0 ? 0 : 1) + " " + units[i];
    }

    function formatDate(date) {
        if (!date) return "";
        const d = new Date(date);
        const pad = n => String(n).padStart(2, "0");
        return d.getFullYear() + "-" + pad(d.getMonth() + 1) + "-" + pad(d.getDate())
            + " " + pad(d.getHours()) + ":" + pad(d.getMinutes());
    }

    function isImage(fileName) {
        const ext = fileName.split('.').pop().toLowerCase();
        return ["jpg", "jpeg", "png", "gif", "webp", "svg", "bmp"].indexOf(ext) !== -1;
    }

    function getItemType(fileName, isDir) {
        if (isDir) return "dir";
        const ext = fileName.split('.').pop().toLowerCase();
        if (["jpg","jpeg","png","gif","webp","svg","bmp"].indexOf(ext) !== -1) return "image";
        if (["mp3","wav","ogg","flac","m4a"].indexOf(ext) !== -1) return "audio";
        if (["pdf"].indexOf(ext) !== -1) return "pdf";
        if (["mp4","mkv","avi","mov","webm","flv"].indexOf(ext) !== -1) return "video";
        return "other";
    }

    function getIconName(fileName, isDir) {
        if (isDir) return "folder";
        
        const ext = fileName.split('.').pop().toLowerCase();
        switch (ext) {
            case "jpg":
            case "jpeg":
            case "png":
            case "gif":
            case "webp":
            case "svg":
            case "bmp":
                return "image";
            case "mp3":
            case "wav":
            case "ogg":
            case "flac":
            case "m4a":
                return "audiotrack";
            case "mp4":
            case "mkv":
            case "avi":
            case "mov":
            case "webm":
                return "video_library";
            case "pdf":
                return "picture_as_pdf";
            case "zip":
            case "tar":
            case "gz":
            case "bz2":
            case "xz":
            case "rar":
            case "7z":
                return "archive";
            case "txt":
            case "md":
            case "json":
            case "xml":
            case "yaml":
            case "yml":
            case "conf":
            case "ini":
                return "description";
            case "sh":
            case "py":
            case "js":
            case "ts":
            case "rs":
            case "go":
            case "c":
            case "cpp":
            case "h":
            case "java":
            case "html":
            case "css":
                return "terminal";
            case "desktop":
                return "bookmark";
            default:
                return "insert_drive_file";
        }
    }

    function getIconColor(fileName, isDir) {
        if (isDir) return root.folderColor || Theme.primary;
        
        const ext = fileName.split('.').pop().toLowerCase();
        switch (ext) {
            case "jpg":
            case "jpeg":
            case "png":
            case "gif":
            case "webp":
            case "svg":
            case "bmp":
                return "#00BFA5"; // Teal
            case "mp3":
            case "wav":
            case "ogg":
            case "flac":
            case "m4a":
            case "mp4":
            case "mkv":
            case "avi":
            case "mov":
            case "webm":
                return "#7C4DFF"; // Indigo
            case "pdf":
                return "#FF1744"; // Red
            case "zip":
            case "tar":
            case "gz":
            case "bz2":
            case "xz":
            case "rar":
            case "7z":
                return "#FF9100"; // Amber
            case "txt":
            case "md":
            case "json":
            case "xml":
            case "yaml":
            case "yml":
            case "conf":
            case "ini":
                return "#2979FF"; // Blue
            case "sh":
            case "py":
            case "js":
            case "ts":
            case "rs":
            case "go":
            case "c":
            case "cpp":
            case "h":
            case "java":
            case "html":
            case "css":
                return "#FF5252"; // Coral Red
            default:
                return Theme.surfaceText;
        }
    }

    // Outer frosted glass background
    StyledRect {
        anchors.fill: parent
        anchors.margins: 15
        radius: Theme.cornerRadius
        clip: true
        color: Theme.withAlpha(Theme.surfaceContainer, root.backgroundOpacity)
        border.color: root.editMode ? Theme.primary : Theme.withAlpha(Theme.outline, root.borderOpacity)
        border.width: root.editMode ? 2 : 1

        Item {
            anchors.fill: parent
            anchors.margins: Theme.spacingM

            // Premium Header (left content: folder name + file status)
            Item {
                id: headerContainer
                anchors.left: parent.left
                anchors.right: settingsBox.left
                height: 24
                anchors.top: parent.top
                visible: root.showHeader

                states: [
                    State {
                        name: "bottom"
                        when: root.headerPosition === "bottom"
                        AnchorChanges {
                            target: headerContainer
                            anchors.top: undefined
                            anchors.bottom: parent.bottom
                        }
                    }
                ]

                // Left: Folder Selector + File Status
                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: 22
                    height: parent.height
                    spacing: Theme.spacingS

                    // Folder Selection
                    MouseArea {
                        id: folderSelectorBtn
                        height: parent.height
                        width: folderRow.implicitWidth
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: folderDropdown.visible ? folderDropdown.close() : folderDropdown.open()

                        Row {
                            id: folderRow
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Theme.spacingXS
                            DankIcon { name: "folder_open"; size: 18; color: folderSelectorBtn.containsMouse ? Theme.primary : Theme.surfaceText; opacity: folderSelectorBtn.containsMouse ? 1.0 : 0.8; anchors.verticalCenter: parent.verticalCenter }
                            StyledText { text: root.folderDisplayName; font.pixelSize: Theme.fontSizeSmall; font.bold: true; color: folderSelectorBtn.containsMouse ? Theme.primary : Theme.surfaceText; opacity: folderSelectorBtn.containsMouse ? 1.0 : 0.8; anchors.verticalCenter: parent.verticalCenter }
                            DankIcon { name: "arrow_drop_down"; size: 14; color: folderSelectorBtn.containsMouse ? Theme.primary : Theme.surfaceText; opacity: folderSelectorBtn.containsMouse ? 1.0 : 0.6; anchors.verticalCenter: parent.verticalCenter }
                        }
                    }

                    // File Status
                    MouseArea {
                        id: fileStatusBtn
                        height: parent.height; width: fileStatusRow.implicitWidth
                        hoverEnabled: true; cursorShape: Qt.PointingHandCursor; visible: folderModel.count > 0
                        onClicked: mouse => {
                            if (quickMenu.visible) { quickMenu.close(); return; }
                            if (root.selectedFilePaths.length === 0) return;
                            const globalPos = mapToItem(root, mouse.x, mouse.y);
                            quickMenu.parent = root;
                            quickMenu.x = Math.max(0, Math.min(root.width - quickMenu.width, globalPos.x));
                            quickMenu.y = Math.max(0, Math.min(root.height - quickMenu.height, globalPos.y));
                            if (root.selectedFilePaths.length === 1) {
                                const path = root.selectedFilePaths[0];
                                quickMenu.currentPath = path;
                                quickMenu.currentName = path.split('/').pop();
                                for (let i = 0; i < filteredModel.count; i++) {
                                    if (filteredModel.get(i).filePath === path) { quickMenu.currentIsDir = filteredModel.get(i).fileIsDir; break; }
                                }
                            }
                            quickMenu.open();
                        }
                        Row {
                            id: fileStatusRow; anchors.verticalCenter: parent.verticalCenter; spacing: 4
                            StyledText {
                                text: {
                                    let c = folderModel.count, s = root.selectedFilePaths.length;
                                    let str = "(" + c + ")";
                                    if (s > 0) str += " [" + s + " " + I18n.tr("selected") + "]";
                                    return str;
                                }
                                font.pixelSize: Theme.fontSizeSmall
                                color: fileStatusBtn.containsMouse ? Theme.primary : Theme.surfaceVariantText
                                opacity: fileStatusBtn.containsMouse ? 1.0 : 0.6
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            StyledText { text: root.selectedFileInfo; font.pixelSize: Theme.fontSizeSmall - 1; color: Theme.surfaceVariantText; opacity: 0.7; anchors.verticalCenter: parent.verticalCenter; visible: root.selectedFileInfo !== ""; elide: Text.ElideRight }
                        }
                    }
                }
            }

            // Back button (top-left, visible when in subfolder)
            MouseArea {
                id: backBtn
                anchors.left: parent.left
                anchors.top: parent.top
                width: 20
                height: 24
                visible: root.folderHistory.length > 0
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.goBackFolder()
                z: 5

                DankIcon {
                    anchors.centerIn: parent
                    name: "arrow_back"
                    size: 16
                    color: backBtn.containsMouse ? Theme.primary : Theme.surfaceText
                    opacity: backBtn.containsMouse ? 1.0 : 0.7
                }
            }

            // Right-side controls (hidden when showHeader is off)
            Item {
                id: headerControls
                anchors.right: settingsBox.left
                anchors.top: parent.top
                width: Math.max(childrenRect.width, 60)
                height: 24
                visible: root.showHeader
                z: 10

                states: [
                    State {
                        name: "bottom"
                        when: root.headerPosition === "bottom"
                        AnchorChanges {
                            target: headerControls
                            anchors.top: undefined
                            anchors.bottom: parent.bottom
                        }
                    }
                ]

                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.spacingS

                    // Back to Top Button
                    MouseArea {
                        id: backToTopBtn
                        width: visible ? 20 : 0
                        height: 20
                        visible: root.isScrolledDown
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.scrollToTop()

                        Behavior on width { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }

                        DankIcon {
                            anchors.centerIn: parent
                            name: "arrow_upward"
                            size: 16
                            color: backToTopBtn.containsMouse ? Theme.primary : Theme.surfaceText
                            opacity: backToTopBtn.containsMouse ? 1.0 : 0.7
                        }
                    }

                    // Premium Dynamic Expanding Search Input
                    Rectangle {
                        id: headerSearchContainer
                        
                        // Explicitly expanded state matching App Launcher design
                        property bool expanded: false
                        
                        width: expanded ? 120 : 20
                        height: 20
                        radius: 10
                        color: expanded 
                            ? Theme.withAlpha(Theme.surfaceText, headerSearchField.activeFocus ? 0.12 : 0.08) 
                            : "transparent"
                        border.color: expanded 
                            ? (headerSearchField.activeFocus ? Theme.primary : Theme.withAlpha(Theme.surfaceText, 0.3)) 
                            : "transparent"
                        border.width: expanded ? 1 : 0
                        
                        anchors.verticalCenter: parent.verticalCenter
                        clip: true

                        Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }

                        // Clicking on the container focuses the text input (which triggers expansion)
                        MouseArea {
                            anchors.fill: parent
                            visible: !headerSearchContainer.expanded
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                headerSearchContainer.expanded = true;
                                headerSearchField.forceActiveFocus();
                            }
                        }

                        DankIcon {
                            id: headerSearchIcon
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: headerSearchContainer.expanded ? 4 : (headerSearchContainer.width - size) / 2
                            name: "search"
                            size: 14
                            color: Theme.surfaceText
                            opacity: headerSearchField.activeFocus ? 1.0 : (headerSearchContainer.expanded ? 0.6 : 0.7)
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                        }

                        TextInput {
                            id: headerSearchField
                            anchors.left: headerSearchIcon.right
                            anchors.leftMargin: 4
                            anchors.right: headerClearBtn.visible ? headerClearBtn.left : parent.right
                            anchors.rightMargin: 4
                            anchors.verticalCenter: parent.verticalCenter
                            font.pixelSize: Theme.fontSizeSmall - 1
                            color: Theme.surfaceText
                            selectByMouse: true
                            visible: headerSearchContainer.expanded
                            opacity: headerSearchContainer.expanded ? 1.0 : 0.0
                            Behavior on opacity { NumberAnimation { duration: 150 } }

                            // Placeholder Text
                            Text {
                                text: I18n.tr("Search...")
                                font.pixelSize: Theme.fontSizeSmall - 1
                                color: Theme.surfaceText
                                opacity: 0.35
                                visible: headerSearchField.text === "" && !headerSearchField.activeFocus
                            }

                            onTextChanged: root.searchPattern = text.trim()

                            // Escape collapses search and restores focus to main handler
                            Keys.onPressed: event => {
                                if (event.key === Qt.Key_Escape) {
                                    headerSearchField.text = "";
                                    root.searchPattern = "";
                                    headerSearchContainer.expanded = false;
                                    keyHandler.forceActiveFocus();
                                    event.accepted = true;
                                }
                            }
                        }

                        // Clear and Collapse button
                        MouseArea {
                            id: headerClearBtn
                            width: 12
                            height: 12
                            anchors.right: parent.right
                            anchors.rightMargin: 4
                            anchors.verticalCenter: parent.verticalCenter
                            visible: headerSearchContainer.expanded
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            
                            DankIcon {
                                anchors.centerIn: parent
                                name: "close"
                                size: 10
                                color: Theme.surfaceText
                                opacity: headerClearBtn.containsMouse ? 0.9 : 0.5
                            }

                            onClicked: {
                                headerSearchField.text = "";
                                root.searchPattern = "";
                                headerSearchField.focus = false;
                                headerSearchContainer.expanded = false;
                            }
                        }
                    }

                    // View Mode Switcher
                    MouseArea {
                        id: viewModeBtn
                        width: 20
                        height: 20
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: viewModeDropdown.visible ? viewModeDropdown.close() : viewModeDropdown.open()

                        DankIcon {
                            anchors.centerIn: parent
                            name: root.viewMode === "grid" ? "grid_view"
                                : root.viewMode === "list" ? "view_list"
                                : "view_module"
                            size: 16
                            color: viewModeBtn.containsMouse ? Theme.primary : Theme.surfaceText
                            opacity: viewModeBtn.containsMouse ? 1.0 : 0.7
                        }
                    }

                    // View Mode Dropdown
                    Popup {
                        id: viewModeDropdown
                        parent: viewModeBtn
                        width: 130
                        height: viewModeColumn.implicitHeight + Theme.spacingS * 2
                        padding: 0
                        modal: true
                        dim: false
                        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
                        x: viewModeBtn.width - viewModeDropdown.width
                        y: root.headerPosition === "bottom" ? -height - 4 : viewModeBtn.height + 4

                        background: Rectangle { color: "transparent" }

                        contentItem: Rectangle {
                            color: Theme.withAlpha(Theme.surfaceContainer, 0.95)
                            radius: Theme.cornerRadius
                            border.color: Theme.withAlpha(Theme.outline, 0.15)
                            border.width: 1

                            Column {
                                id: viewModeColumn
                                anchors.fill: parent
                                anchors.margins: Theme.spacingS
                                spacing: 2

                                Repeater {
                                    model: [
                                        { label: I18n.tr("Grid View"), value: "grid", icon: "grid_view" },
                                        { label: I18n.tr("List View"), value: "list", icon: "view_list" },
                                        { label: I18n.tr("Compact View"), value: "compact", icon: "view_module" }
                                    ]

                                    delegate: Rectangle {
                                        width: parent.width
                                        height: 28
                                        radius: Theme.cornerRadius - 2
                                        color: vmArea.containsMouse ? Theme.withAlpha(Theme.primary, 0.15) : "transparent"

                                        Row {
                                            anchors.left: parent.left
                                            anchors.leftMargin: Theme.spacingS
                                            anchors.right: parent.right
                                            anchors.rightMargin: Theme.spacingS
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: Theme.spacingS

                                            DankIcon {
                                                name: modelData.icon
                                                size: 14
                                                color: root.viewMode === modelData.value ? Theme.primary : Theme.surfaceText
                                                anchors.verticalCenter: parent.verticalCenter
                                            }

                                            StyledText {
                                                text: modelData.label
                                                font.pixelSize: Theme.fontSizeSmall
                                                font.bold: root.viewMode === modelData.value
                                                color: root.viewMode === modelData.value ? Theme.primary : Theme.surfaceText
                                                anchors.verticalCenter: parent.verticalCenter
                                            }
                                        }

                                        MouseArea {
                                            id: vmArea
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                viewModeDropdown.close();
                                                if (pluginService) {
                                                    pluginService.savePluginData(pluginId, "viewMode", modelData.value);
                                                }
                                            }
                                        }
                                    }
                }
            }
        }
    }

                    // Create Button (New Folder / New File)
                    MouseArea {
                        id: createBtn
                        width: 20
                        height: 20
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: createDropdown.open()

                        DankIcon {
                            anchors.centerIn: parent
                            name: "add"
                            size: 16
                            color: createBtn.containsMouse ? Theme.primary : Theme.surfaceText
                            opacity: createBtn.containsMouse ? 1.0 : 0.7
                        }
                    }

                    // Sort By Button
                    MouseArea {
                        id: sortByBtn
                        width: 20
                        height: 20
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: sortByDropdown.open()
 
                        DankIcon {
                            anchors.centerIn: parent
                            name: {
                                switch (root.sortBy) {
                                    case "time": return "schedule";
                                    case "size": return "bar_chart";
                                    case "type": return "category";
                                    default: return "sort_by_alpha";
                                }
                            }
                            size: 16
                            color: sortByBtn.containsMouse ? Theme.primary : Theme.surfaceText
                            opacity: sortByBtn.containsMouse ? 1.0 : 0.7
                        }
                    }
 
                    // Filter Button
                    MouseArea {
                        id: filterBtn
                        width: 20
                        height: 20
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: filterDropdown.open()

                        DankIcon {
                            anchors.centerIn: parent
                            name: "filter_list"
                            size: 16
                            color: (root.filterType !== "all" || root.filterTime !== "all") ? Theme.primary : (filterBtn.containsMouse ? Theme.primary : Theme.surfaceText)
                            opacity: (root.filterType !== "all" || root.filterTime !== "all" || filterBtn.containsMouse) ? 1.0 : 0.7
                        }
                    }

                }
            }

            // Settings button (always visible at bottom-right)
            Item {
                id: settingsBox
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                width: 20
                height: 24
                z: 10
                opacity: root.showHeader ? 1.0 : (settingsBtn.containsMouse ? 1.0 : 0.05)
                Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }

                MouseArea {
                    id: settingsBtn
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: settingsDropdown.visible ? settingsDropdown.close() : settingsDropdown.open()

                    DankIcon {
                        anchors.centerIn: parent
                        name: "settings"
                        size: 16
                        color: settingsBtn.containsMouse ? Theme.primary : Theme.surfaceText
                        opacity: settingsBtn.containsMouse ? 1.0 : 0.7
                    }
                }

                // Settings Popup
                Popup {
                    id: settingsDropdown
                    parent: settingsBtn
                    width: 220
                    height: Math.min(500, settingsColumn.implicitHeight + Theme.spacingM * 2)
                    padding: 0
                    modal: true
                    dim: false
                    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
                    x: settingsBtn.width - settingsDropdown.width
                    y: -height - 4

                    background: Rectangle { color: "transparent" }

                    contentItem: Rectangle {
                        color: Theme.withAlpha(Theme.surfaceContainer, 0.95)
                        radius: Theme.cornerRadius
                        border.color: Theme.withAlpha(Theme.outline, 0.15)
                        border.width: 1

                        Column {
                            id: settingsColumn
                            anchors.fill: parent
                            anchors.margins: Theme.spacingM
                            spacing: Theme.spacingS

                            StyledText {
                                text: I18n.tr("Appearance")
                                font.pixelSize: Theme.fontSizeSmall
                                font.bold: true
                                color: Theme.surfaceText
                            }

                            // Background Opacity
                            Row { width: parent.width; height: 24; spacing: Theme.spacingS
                                StyledText { text: I18n.tr("Bg Opacity"); font.pixelSize: Theme.fontSizeSmall - 1; color: Theme.surfaceVariantText; width: 70; anchors.verticalCenter: parent.verticalCenter }
                                Item { width: parent.width - 70 - 40; height: parent.height; anchors.verticalCenter: parent.verticalCenter
                                    Slider {
                                        id: bgSlider; anchors.verticalCenter: parent.verticalCenter; width: parent.width
                                        from: 0; to: 100; value: pluginData.backgroundOpacity ?? 80
                                        onMoved: { if (pluginService) pluginService.savePluginData(pluginId, "backgroundOpacity", Math.round(value)) }
                                    }
                                }
                                StyledText { text: Math.round(bgSlider.value) + "%"; font.pixelSize: Theme.fontSizeSmall - 1; color: Theme.surfaceText; width: 35; anchors.verticalCenter: parent.verticalCenter }
                            }

                            // Border Opacity
                            Row { width: parent.width; height: 24; spacing: Theme.spacingS
                                StyledText { text: I18n.tr("Border Op"); font.pixelSize: Theme.fontSizeSmall - 1; color: Theme.surfaceVariantText; width: 70; anchors.verticalCenter: parent.verticalCenter }
                                Item { width: parent.width - 70 - 40; height: parent.height; anchors.verticalCenter: parent.verticalCenter
                                    Slider {
                                        id: borderSlider; anchors.verticalCenter: parent.verticalCenter; width: parent.width
                                        from: 0; to: 100; value: pluginData.borderOpacity ?? 0
                                        onMoved: { if (pluginService) pluginService.savePluginData(pluginId, "borderOpacity", Math.round(value)) }
                                    }
                                }
                                StyledText { text: Math.round(borderSlider.value) + "%"; font.pixelSize: Theme.fontSizeSmall - 1; color: Theme.surfaceText; width: 35; anchors.verticalCenter: parent.verticalCenter }
                            }

                            // Header Position
                            Row { width: parent.width; height: 24; spacing: Theme.spacingS
                                StyledText { text: I18n.tr("Header"); font.pixelSize: Theme.fontSizeSmall - 1; color: Theme.surfaceVariantText; width: 70; anchors.verticalCenter: parent.verticalCenter }
                                Row { spacing: Theme.spacingXS; anchors.verticalCenter: parent.verticalCenter
                                    Repeater {
                                        model: [{label: "Top", val: "top"}, {label: "Bottom", val: "bottom"}]
                                        delegate: Rectangle {
                                            width: 50; height: 22; radius: 4
                                            color: (root.headerPosition === modelData.val) ? Theme.primary : (hpArea.containsMouse ? Theme.withAlpha(Theme.surfaceText, 0.1) : "transparent")
                                            border.color: (root.headerPosition === modelData.val) ? Theme.primary : Theme.withAlpha(Theme.outline, 0.2)
                                            border.width: 1
                                            StyledText { anchors.centerIn: parent; text: modelData.label; font.pixelSize: Theme.fontSizeSmall - 1; color: (root.headerPosition === modelData.val) ? Theme.onPrimary : Theme.surfaceText }
                                            MouseArea { id: hpArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                onClicked: { if (pluginService) pluginService.savePluginData(pluginId, "headerPosition", modelData.val); settingsDropdown.close() } } } }
                                }
                            }

                            // Show Header toggle
                            Row { width: parent.width; height: 24; spacing: Theme.spacingS
                                StyledText { text: I18n.tr("Show Header"); font.pixelSize: Theme.fontSizeSmall - 1; color: Theme.surfaceVariantText; width: 70; anchors.verticalCenter: parent.verticalCenter }
                                Item { width: 40; height: parent.height; anchors.verticalCenter: parent.verticalCenter
                                    DankIcon {
                                        anchors.centerIn: parent; name: root.showHeader ? "toggle_on" : "toggle_off"; size: 24
                                        color: root.showHeader ? Theme.primary : Theme.surfaceVariantText
                                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                            onClicked: { root.showHeader = !root.showHeader; if (pluginService) pluginService.savePluginData(pluginId, "showHeader", root.showHeader); settingsDropdown.close() } } }
                                }
                            }

                            // Empty indicator color
                            Column { width: parent.width; spacing: 6
                                StyledText { text: I18n.tr("Empty Color"); font.pixelSize: Theme.fontSizeSmall - 1; color: Theme.surfaceVariantText }
                                Row { spacing: 5
                                    Repeater {
                                        model: ["#FF1744", "#00E676", "#FFEA00", "#448AFF", "#D500F9", "#00BFA5", "#FF9100", "#E91E63", "#00BCD4", "#795548"]
                                        delegate: Rectangle {
                                            width: 14; height: 14; radius: 2
                                            color: modelData
                                            border.width: root.emptyColor === modelData ? 2 : 1
                                            border.color: root.emptyColor === modelData ? Theme.surfaceText : Theme.withAlpha(Theme.outline, 0.3)
                                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                                onClicked: { root.emptyColor = modelData; if (pluginService) pluginService.savePluginData(pluginId, "emptyColor", modelData); settingsDropdown.close() } }
                                        }
                                    }
                                }
                            }

                            // Folder icon color
                            Column { width: parent.width; spacing: 6
                                StyledText { text: I18n.tr("Folder Color"); font.pixelSize: Theme.fontSizeSmall - 1; color: Theme.surfaceVariantText }
                                Row { spacing: 5
                                    Repeater {
                                        model: ["", "#FF1744", "#00E676", "#FFEA00", "#448AFF", "#D500F9", "#00BFA5", "#FF9100", "#E91E63", "#00BCD4"]
                                        delegate: Rectangle {
                                            width: 14; height: 14; radius: modelData === "" ? 7 : 2
                                            color: modelData || Theme.primary
                                            border.width: root.folderColor === modelData ? 2 : 1
                                            border.color: root.folderColor === modelData ? Theme.surfaceText : Theme.withAlpha(Theme.outline, 0.3)
                                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                                onClicked: { root.folderColor = modelData; if (pluginService) pluginService.savePluginData(pluginId, "folderColor", modelData); settingsDropdown.close() } }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            // Grid View container
            Item {
                id: filesContainer
                anchors.left: parent.left
                anchors.right: parent.right
                clip: true

                // Default anchors: header at top
                anchors.top: (root.showHeader && root.headerPosition === "top") ? headerContainer.bottom : parent.top
                anchors.topMargin: (root.showHeader && root.headerPosition === "top") ? Theme.spacingS : 0
                anchors.bottom: parent.bottom

                states: [
                    State {
                        name: "headerBottom"
                        when: root.showHeader && root.headerPosition === "bottom"
                        AnchorChanges {
                            target: filesContainer
                            anchors.top: parent.top
                            anchors.bottom: headerContainer.top
                        }
                        PropertyChanges {
                            target: filesContainer
                            anchors.topMargin: 0
                            anchors.bottomMargin: Theme.spacingS
                        }
                    }
                ]

                FolderListModel {
                    id: folderModel
                    folder: root.targetFolderUrl
                    showDirsFirst: true
                    showHidden: root.showHidden
                    sortField: root.folderSortField
                }

                GridView {
                    id: fileGrid
                    // Center grid content horizontally so left/right borders stay equal
                    readonly property int _cols: Math.max(1, Math.floor((parent ? parent.width : root.cellSize) / root.cellSize))
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: _cols * root.cellSize
                    anchors.horizontalCenter: parent.horizontalCenter
                    cellWidth: root.cellSize
                    cellHeight: root.cellSize + 16
                    model: filteredModel
                    visible: root.viewMode === "grid"
                    boundsBehavior: Flickable.StopAtBounds
                    cacheBuffer: cellHeight * 3

                    // Smooth add/remove transitions
                    add: Transition {
                        NumberAnimation { properties: "opacity,scale"; from: 0; to: 1.0; duration: 100; easing.type: Easing.OutQuad }
                    }
                    remove: Transition {
                        NumberAnimation { property: "opacity"; to: 0; duration: 80 }
                    }

                    delegate: Item {
                        id: delegateRoot
                        width: fileGrid.cellWidth
                        height: fileGrid.cellHeight

                        required property string filePath
                        required property string fileName
                        required property bool fileIsDir
                        required property int index
                        required property string displayBaseName
                        required property string iconName
                        required property string iconColor
                        required property string itemType

                        required property bool isDesktop
                        required property string appIcon
                        required property bool isStack
                        required property string belongingStackId
                        required property bool isEmpty
                        readonly property bool isSelected: root.selectedPathsSet[filePath] !== undefined
                        readonly property bool editing: delegateRoot.filePath !== "" && root.renamingFilePath === delegateRoot.filePath && root.viewMode === "grid"
                        property bool isLaunching: false

                        // Pre-computed colors for reduced binding overhead
                        readonly property color _bgNormal: itemHover.containsMouse
                            ? (belongingStackId !== ""
                                ? (isStack ? Theme.withAlpha(Theme.primary, 0.22) : Theme.withAlpha(Theme.primary, 0.12))
                                : Theme.withAlpha(Theme.surfaceText, 0.06))
                            : (belongingStackId !== ""
                                ? (isStack ? Theme.withAlpha(Theme.primary, 0.12) : Theme.withAlpha(Theme.primary, 0.05))
                                : "transparent")
                        readonly property color _bgColor: isLaunching
                            ? Theme.withAlpha(Theme.primary, 0.3)
                            : (isSelected ? Theme.withAlpha(Theme.primary, 0.15) : _bgNormal)
                        readonly property color _borderColor: isLaunching
                            ? Theme.primary
                            : (isSelected ? Theme.primary
                                : (belongingStackId !== ""
                                    ? (isStack ? Theme.primary : Theme.withAlpha(Theme.primary, 0.25))
                                    : "transparent"))
                        readonly property int _borderWidth: isLaunching ? 2 : (isSelected ? 1 : (belongingStackId !== "" ? 1 : 0))

                        Drag.dragType: Drag.Automatic
                        Drag.supportedActions: Qt.CopyAction

                        DragHandler {
                            id: gridDragHandler
                            target: null
                            acceptedButtons: Qt.LeftButton
                            grabPermissions: PointerHandler.CanTakeOverFromItems | PointerHandler.ApprovesCancellation
                            enabled: !delegateRoot.isStack && !delegateRoot.filePath.startsWith("stack://") && !delegateRoot.editing
                            onActiveChanged: {
                                if (active) {
                                    delegateRoot.Drag.mimeData = root.dragMimeData(delegateRoot.filePath);
                                    delegateRoot.grabToImage(function (result) {
                                        // grabToImage is async: bail out if the press
                                        // was already released in the meantime
                                        if (!gridDragHandler.active)
                                            return;
                                        delegateRoot.Drag.imageSource = result.url;
                                        delegateRoot.Drag.active = true;
                                    });
                                } else {
                                    delegateRoot.Drag.active = false;
                                }
                            }
                        }

                        SequentialAnimation {
                            id: launchPulse
                            running: false
                            NumberAnimation { target: delegateRoot; property: "scale"; to: 0.92; duration: 100; easing.type: Easing.OutQuad }
                            NumberAnimation { target: delegateRoot; property: "scale"; to: 1.05; duration: 150; easing.type: Easing.OutBack }
                            NumberAnimation { target: delegateRoot; property: "scale"; to: 1.0; duration: 100; easing.type: Easing.OutQuad }
                        }

                        Timer {
                            id: launchTimer
                            interval: 800
                            repeat: false
                            onTriggered: delegateRoot.isLaunching = false
                        }

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: Theme.spacingXS
                            radius: Theme.cornerRadius
                            color: delegateRoot._bgColor
                            border.color: delegateRoot._borderColor
                            border.width: delegateRoot._borderWidth

                            Column {
                                anchors.fill: parent
                                anchors.margins: Theme.spacingS
                                spacing: Theme.spacingXS

                                // File/Folder Icon
                                Item {
                                    width: parent.width
                                    height: parent.height - 30

                                    FolderViewThumbnail {
                                        anchors.fill: parent
                                        filePath: delegateRoot.filePath
                                        fileName: delegateRoot.fileName
                                        isDir: delegateRoot.fileIsDir
                                        appIcon: delegateRoot.appIcon
                                        iconName: delegateRoot.iconName
                                        iconColor: delegateRoot.iconColor
                                        itemType: delegateRoot.itemType
                                        sizeScale: root.sizeScale
                                        hover: itemHover.containsMouse
                                    }

                                    // Empty file/folder indicator — red dot centered on icon
                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: 8
                                        height: 8
                                        radius: 4
                                        color: root.emptyColor
                                        visible: delegateRoot.isEmpty
                                    }
                                }

                                // File/Folder Name
                                StyledText {
                                    id: gridNameLabel
                                    width: parent.width
                                    visible: !delegateRoot.editing
                                    font.pixelSize: Theme.fontSizeSmall + 1
                                    text: delegateRoot.displayBaseName
                                    color: Theme.surfaceText
                                    horizontalAlignment: Text.AlignHCenter
                                    elide: Text.ElideRight
                                    maximumLineCount: 2
                                    wrapMode: Text.WrapAnywhere
                                    opacity: itemHover.containsMouse ? 1.0 : 0.85
                                }

                                // Inline rename editor (replaces the label while editing)
                                Loader {
                                    width: parent.width
                                    height: active && item ? item.implicitHeight : 0
                                    active: delegateRoot.editing
                                    visible: active
                                    sourceComponent: Component {
                                        FolderViewInlineRename {
                                            fontPixelSize: Theme.fontSizeSmall - 1
                                            targetName: delegateRoot.fileName
                                            targetIsDir: delegateRoot.fileIsDir
                                            onAccepted: newBaseName => {
                                                root.applyRename(delegateRoot.filePath, delegateRoot.fileName, delegateRoot.fileIsDir, newBaseName);
                                                root.endInlineRename();
                                            }
                                            onCanceled: root.endInlineRename()
                                        }
                                    }
                                }
                            }

                            // Pin indicator overlay
                            DankIcon {
                                name: "push_pin"
                                size: 16
                                color: Theme.primary
                                anchors.top: parent.top
                                anchors.topMargin: Theme.spacingXS + 2
                                anchors.right: parent.right
                                anchors.rightMargin: Theme.spacingXS + 2
                                visible: root.pinnedPaths.indexOf(filePath) !== -1
                            }

                            MouseArea {
                                id: itemHover
                                anchors.fill: parent
                                enabled: !delegateRoot.editing
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                acceptedButtons: Qt.LeftButton | Qt.MiddleButton

                                onClicked: mouse => {
                                    if (mouse.button === Qt.LeftButton) {
                                        if (delegateRoot.filePath.startsWith("stack://")) {
                                            let stackId = delegateRoot.filePath.substring(8);
                                            root.toggleStackExpanded(stackId);
                                            return;
                                        }
                                        if (mouse.modifiers & Qt.ControlModifier) {
                                            root.toggleSelection(delegateRoot.filePath);
                                        } else if (mouse.modifiers & Qt.ShiftModifier) {
                                            root.selectRangeTo(delegateRoot.index);
                                        } else {
                                            // Clicking the name label of an already-selected item starts
                                            // an inline rename; a double-click opens instead (see below).
                                            root.handleItemLabelClick(itemHover, gridNameLabel, mouse.x, mouse.y, delegateRoot.filePath);
                                        }
                                    } else if (mouse.button === Qt.MiddleButton) {
                                        inlineRenameArmTimer.stop();
                                        if (root.selectedFilePaths.indexOf(delegateRoot.filePath) === -1) {
                                            root.selectSingle(delegateRoot.filePath);
                                        }

                                        quickMenu.currentPath = delegateRoot.filePath;
                                        quickMenu.currentName = delegateRoot.fileName;
                                        quickMenu.currentIsDir = delegateRoot.fileIsDir;
                                        
                                        const globalPos = mapToItem(root, mouse.x, mouse.y);
                                        quickMenu.parent = root;
                                        quickMenu.x = Math.max(0, Math.min(root.width - quickMenu.width, globalPos.x));
                                        quickMenu.y = Math.max(0, Math.min(root.height - quickMenu.height, globalPos.y));
                                        quickMenu.open();
                                    }
                                }

                                onDoubleClicked: mouse => {
                                    if (mouse.button === Qt.LeftButton) {
                                        inlineRenameArmTimer.stop();
                                        if (delegateRoot.filePath.startsWith("stack://")) {
                                            let stackId = delegateRoot.filePath.substring(8);
                                            root.toggleStackExpanded(stackId);
                                            return;
                                        }
                                        isLaunching = true;
                                        launchPulse.restart();
                                        launchTimer.restart();
                                        // Open file or navigate into folder
                                        if (delegateRoot.fileIsDir) { root.navigateToFolder(delegateRoot.filePath); } else if (delegateRoot.isDesktop) {
                                            root.launchDesktopFile(delegateRoot.filePath);
                                        } else {
                                            Quickshell.execDetached(["gio", "open", root._cleanPath(delegateRoot.filePath)]);
                                        }
                                        root.clearSelection();
                                    }
                                }
                            }
                        }
                    }
                }

                // List View of files
                ListView {
                    id: fileList
                    anchors.fill: parent
                    model: filteredModel
                    visible: root.viewMode === "list"
                    boundsBehavior: Flickable.StopAtBounds
                    spacing: 2
                    clip: true
                    cacheBuffer: 100

                    // Smooth add/remove transitions
                    add: Transition {
                        NumberAnimation { property: "opacity"; from: 0; to: 1.0; duration: 80 }
                    }
                    remove: Transition {
                        NumberAnimation { property: "opacity"; to: 0; duration: 60 }
                    }

                    delegate: Item {
                        id: listDelegateRoot
                        width: fileList.width
                        height: Math.round(36 * root.sizeScale)

                        required property string filePath
                        required property string fileName
                        required property bool fileIsDir
                        required property int index
                        required property string displayBaseName
                        required property string iconName
                        required property string iconColor
                        required property string itemType

                        required property bool isDesktop
                        required property string appIcon
                        required property bool isStack
                        required property string belongingStackId
                        required property bool isEmpty
                        readonly property bool isSelected: root.selectedPathsSet[filePath] !== undefined
                        readonly property bool editing: listDelegateRoot.filePath !== "" && root.renamingFilePath === listDelegateRoot.filePath && root.viewMode === "list"
                        property bool isLaunching: false

                        // Pre-computed colors
                        readonly property color _bgNormal: listItemHover.containsMouse
                            ? (belongingStackId !== ""
                                ? (isStack ? Theme.withAlpha(Theme.primary, 0.22) : Theme.withAlpha(Theme.primary, 0.12))
                                : Theme.withAlpha(Theme.surfaceText, 0.06))
                            : (belongingStackId !== ""
                                ? (isStack ? Theme.withAlpha(Theme.primary, 0.12) : Theme.withAlpha(Theme.primary, 0.05))
                                : "transparent")
                        readonly property color _bgColor: isLaunching
                            ? Theme.withAlpha(Theme.primary, 0.3)
                            : (isSelected ? Theme.withAlpha(Theme.primary, 0.15) : _bgNormal)
                        readonly property color _borderColor: isLaunching
                            ? Theme.primary
                            : (isSelected ? Theme.primary
                                : (belongingStackId !== ""
                                    ? (isStack ? Theme.primary : Theme.withAlpha(Theme.primary, 0.25))
                                    : "transparent"))
                        readonly property int _borderWidth: isLaunching ? 1 : (isSelected ? 1 : (belongingStackId !== "" ? 1 : 0))

                        Drag.dragType: Drag.Automatic
                        Drag.supportedActions: Qt.CopyAction

                        DragHandler {
                            id: listDragHandler
                            target: null
                            acceptedButtons: Qt.LeftButton
                            grabPermissions: PointerHandler.CanTakeOverFromItems | PointerHandler.ApprovesCancellation
                            enabled: !listDelegateRoot.isStack && !listDelegateRoot.filePath.startsWith("stack://") && !listDelegateRoot.editing
                            onActiveChanged: {
                                if (active) {
                                    listDelegateRoot.Drag.mimeData = root.dragMimeData(listDelegateRoot.filePath);
                                    listDelegateRoot.grabToImage(function (result) {
                                        // grabToImage is async: bail out if the press
                                        // was already released in the meantime
                                        if (!listDragHandler.active)
                                            return;
                                        listDelegateRoot.Drag.imageSource = result.url;
                                        listDelegateRoot.Drag.active = true;
                                    });
                                } else {
                                    listDelegateRoot.Drag.active = false;
                                }
                            }
                        }

                        SequentialAnimation {
                            id: listLaunchPulse
                            running: false
                            NumberAnimation { target: listDelegateRoot; property: "scale"; to: 0.98; duration: 100; easing.type: Easing.OutQuad }
                            NumberAnimation { target: listDelegateRoot; property: "scale"; to: 1.02; duration: 150; easing.type: Easing.OutBack }
                            NumberAnimation { target: listDelegateRoot; property: "scale"; to: 1.0; duration: 100; easing.type: Easing.OutQuad }
                        }

                        Timer {
                            id: listLaunchTimer
                            interval: 800
                            repeat: false
                            onTriggered: listDelegateRoot.isLaunching = false
                        }

                        Rectangle {
                            anchors.fill: parent
                            anchors.leftMargin: Theme.spacingXS
                            anchors.rightMargin: Theme.spacingXS
                            radius: Theme.cornerRadius - 2
                            color: listDelegateRoot._bgColor
                            border.color: listDelegateRoot._borderColor
                            border.width: listDelegateRoot._borderWidth

                            Row {
                                id: listRow
                                anchors.fill: parent
                                anchors.leftMargin: Theme.spacingS
                                anchors.rightMargin: Theme.spacingS
                                spacing: Theme.spacingS
                                anchors.verticalCenter: parent.verticalCenter

                                FolderViewThumbnail {
                                    width: Math.round(20 * root.sizeScale)
                                    height: width
                                    anchors.verticalCenter: parent.verticalCenter
                                    filePath: listDelegateRoot.filePath
                                    fileName: listDelegateRoot.fileName
                                    isDir: listDelegateRoot.fileIsDir
                                    appIcon: listDelegateRoot.appIcon
                                    iconName: listDelegateRoot.iconName
                                    iconColor: listDelegateRoot.iconColor
                                    itemType: listDelegateRoot.itemType
                                    sizeScale: root.sizeScale
                                    hover: listItemHover.containsMouse
                                }

                                StyledText {
                                    id: listNameLabel
                                    font.pixelSize: Theme.fontSizeSmall + 2
                                    visible: !listDelegateRoot.editing
                                    width: parent.width - Math.round(20 * root.sizeScale) - (root.pinnedPaths.indexOf(filePath) !== -1 ? 32 : 12)
                                    text: listDelegateRoot.displayBaseName
                                    color: listDelegateRoot.isEmpty ? root.emptyColor : Theme.surfaceText
                                    anchors.verticalCenter: parent.verticalCenter
                                    elide: Text.ElideRight
                                    maximumLineCount: 1
                                }

                                // Inline rename editor (replaces the label while editing)
                                Loader {
                                    active: listDelegateRoot.editing
                                    visible: active
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - Math.round(20 * root.sizeScale) - (root.pinnedPaths.indexOf(listDelegateRoot.filePath) !== -1 ? 32 : 12)
                                    height: active && item ? item.implicitHeight : 0
                                    sourceComponent: Component {
                                        FolderViewInlineRename {
                                            fontPixelSize: Theme.fontSizeSmall
                                            targetName: listDelegateRoot.fileName
                                            targetIsDir: listDelegateRoot.fileIsDir
                                            onAccepted: newBaseName => {
                                                root.applyRename(listDelegateRoot.filePath, listDelegateRoot.fileName, listDelegateRoot.fileIsDir, newBaseName);
                                                root.endInlineRename();
                                            }
                                            onCanceled: root.endInlineRename()
                                        }
                                    }
                                }
                            }

                            // Pin indicator
                            DankIcon {
                                name: "push_pin"
                                size: 14
                                color: Theme.primary
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.right: parent.right
                                anchors.rightMargin: Theme.spacingS
                                visible: root.pinnedPaths.indexOf(filePath) !== -1
                            }

                            MouseArea {
                                id: listItemHover
                                anchors.fill: parent
                                enabled: !listDelegateRoot.editing
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                acceptedButtons: Qt.LeftButton | Qt.MiddleButton

                                onClicked: mouse => {
                                    if (mouse.button === Qt.LeftButton) {
                                        if (listDelegateRoot.filePath.startsWith("stack://")) {
                                            let stackId = listDelegateRoot.filePath.substring(8);
                                            root.toggleStackExpanded(stackId);
                                            return;
                                        }
                                        if (mouse.modifiers & Qt.ControlModifier) {
                                            root.toggleSelection(listDelegateRoot.filePath);
                                        } else if (mouse.modifiers & Qt.ShiftModifier) {
                                            root.selectRangeTo(listDelegateRoot.index);
                                        } else {
                                            // Clicking the name label of an already-selected item starts
                                            // an inline rename; a double-click opens instead (see below).
                                            root.handleItemLabelClick(listItemHover, listNameLabel, mouse.x, mouse.y, listDelegateRoot.filePath);
                                        }
                                    } else if (mouse.button === Qt.MiddleButton) {
                                        inlineRenameArmTimer.stop();
                                        if (root.selectedFilePaths.indexOf(listDelegateRoot.filePath) === -1) {
                                            root.selectSingle(listDelegateRoot.filePath);
                                        }

                                        quickMenu.currentPath = listDelegateRoot.filePath;
                                        quickMenu.currentName = listDelegateRoot.fileName;
                                        quickMenu.currentIsDir = listDelegateRoot.fileIsDir;
                                        
                                        const globalPos = mapToItem(root, mouse.x, mouse.y);
                                        quickMenu.parent = root;
                                        quickMenu.x = Math.max(0, Math.min(root.width - quickMenu.width, globalPos.x));
                                        quickMenu.y = Math.max(0, Math.min(root.height - quickMenu.height, globalPos.y));
                                        quickMenu.open();
                                    }
                                }

                                onDoubleClicked: mouse => {
                                    if (mouse.button === Qt.LeftButton) {
                                        inlineRenameArmTimer.stop();
                                        if (listDelegateRoot.filePath.startsWith("stack://")) {
                                            let stackId = listDelegateRoot.filePath.substring(8);
                                            root.toggleStackExpanded(stackId);
                                            return;
                                        }
                                        listDelegateRoot.isLaunching = true;
                                        listLaunchPulse.restart();
                                        // Open file or navigate into folder
                                        if (listDelegateRoot.fileIsDir) { root.navigateToFolder(listDelegateRoot.filePath); } else if (listDelegateRoot.isDesktop) {
                                            root.launchDesktopFile(listDelegateRoot.filePath);
                                        } else {
                                            Quickshell.execDetached(["gio", "open", root._cleanPath(listDelegateRoot.filePath)]);
                                        }
                                        listLaunchTimer.restart();
                                        root.clearSelection();
                                    }
                                }
                            }
                        }
                    }
                }

                // Compact View of files (1 or 2 columns list layout)
                GridView {
                    id: fileCompact
                    anchors.fill: parent
                    cellWidth: parent.width / 3
                    cellHeight: Math.round(30 * root.sizeScale)
                    model: filteredModel
                    visible: root.viewMode === "compact"
                    boundsBehavior: Flickable.StopAtBounds
                    clip: true
                    cacheBuffer: 100

                    // Smooth add/remove transitions
                    add: Transition {
                        NumberAnimation { properties: "opacity,scale"; from: 0; to: 1.0; duration: 80 }
                    }
                    remove: Transition {
                        NumberAnimation { property: "opacity"; to: 0; duration: 60 }
                    }

                    delegate: Item {
                        id: compactDelegateRoot
                        width: fileCompact.cellWidth
                        height: Math.round(30 * root.sizeScale)

                        required property string filePath
                        required property string fileName
                        required property bool fileIsDir
                        required property int index
                        required property string displayBaseName
                        required property string iconName
                        required property string iconColor
                        required property string itemType

                        required property bool isDesktop
                        required property string appIcon
                        required property bool isStack
                        required property string belongingStackId
                        required property bool isEmpty
                        readonly property bool isSelected: root.selectedPathsSet[filePath] !== undefined
                        readonly property bool editing: compactDelegateRoot.filePath !== "" && root.renamingFilePath === compactDelegateRoot.filePath && root.viewMode === "compact"
                        property bool isLaunching: false

                        // Pre-computed colors
                        readonly property color _bgNormal: compactItemHover.containsMouse
                            ? (belongingStackId !== ""
                                ? (isStack ? Theme.withAlpha(Theme.primary, 0.22) : Theme.withAlpha(Theme.primary, 0.12))
                                : Theme.withAlpha(Theme.surfaceText, 0.06))
                            : (belongingStackId !== ""
                                ? (isStack ? Theme.withAlpha(Theme.primary, 0.12) : Theme.withAlpha(Theme.primary, 0.05))
                                : "transparent")
                        readonly property color _bgColor: isLaunching
                            ? Theme.withAlpha(Theme.primary, 0.3)
                            : (isSelected ? Theme.withAlpha(Theme.primary, 0.15) : _bgNormal)
                        readonly property color _borderColor: isLaunching
                            ? Theme.primary
                            : (isSelected ? Theme.primary
                                : (belongingStackId !== ""
                                    ? (isStack ? Theme.primary : Theme.withAlpha(Theme.primary, 0.25))
                                    : "transparent"))
                        readonly property int _borderWidth: isLaunching ? 1 : (isSelected ? 1 : (belongingStackId !== "" ? 1 : 0))

                        Drag.dragType: Drag.Automatic
                        Drag.supportedActions: Qt.CopyAction

                        DragHandler {
                            id: compactDragHandler
                            target: null
                            acceptedButtons: Qt.LeftButton
                            grabPermissions: PointerHandler.CanTakeOverFromItems | PointerHandler.ApprovesCancellation
                            enabled: !compactDelegateRoot.isStack && !compactDelegateRoot.filePath.startsWith("stack://") && !compactDelegateRoot.editing
                            onActiveChanged: {
                                if (active) {
                                    compactDelegateRoot.Drag.mimeData = root.dragMimeData(compactDelegateRoot.filePath);
                                    compactDelegateRoot.grabToImage(function (result) {
                                        // grabToImage is async: bail out if the press
                                        // was already released in the meantime
                                        if (!compactDragHandler.active)
                                            return;
                                        compactDelegateRoot.Drag.imageSource = result.url;
                                        compactDelegateRoot.Drag.active = true;
                                    });
                                } else {
                                    compactDelegateRoot.Drag.active = false;
                                }
                            }
                        }

                        SequentialAnimation {
                            id: compactLaunchPulse
                            running: false
                            NumberAnimation { target: compactDelegateRoot; property: "scale"; to: 0.98; duration: 100; easing.type: Easing.OutQuad }
                            NumberAnimation { target: compactDelegateRoot; property: "scale"; to: 1.02; duration: 150; easing.type: Easing.OutBack }
                            NumberAnimation { target: compactDelegateRoot; property: "scale"; to: 1.0; duration: 100; easing.type: Easing.OutQuad }
                        }

                        Timer {
                            id: compactLaunchTimer
                            interval: 800
                            repeat: false
                            onTriggered: compactDelegateRoot.isLaunching = false
                        }

                        Rectangle {
                            anchors.fill: parent
                            anchors.leftMargin: Theme.spacingXS
                            anchors.rightMargin: Theme.spacingXS
                            radius: Theme.cornerRadius - 2
                            color: compactDelegateRoot._bgColor
                            border.color: compactDelegateRoot._borderColor
                            border.width: compactDelegateRoot._borderWidth

                            Row {
                                id: compactRow
                                anchors.fill: parent
                                anchors.leftMargin: Theme.spacingS
                                anchors.rightMargin: Theme.spacingS
                                spacing: Theme.spacingS
                                anchors.verticalCenter: parent.verticalCenter

                                FolderViewThumbnail {
                                    width: Math.round(16 * root.sizeScale)
                                    height: width
                                    anchors.verticalCenter: parent.verticalCenter
                                    filePath: compactDelegateRoot.filePath
                                    fileName: compactDelegateRoot.fileName
                                    isDir: compactDelegateRoot.fileIsDir
                                    appIcon: compactDelegateRoot.appIcon
                                    iconName: compactDelegateRoot.iconName
                                    iconColor: compactDelegateRoot.iconColor
                                    itemType: compactDelegateRoot.itemType
                                    sizeScale: root.sizeScale
                                    hover: compactItemHover.containsMouse
                                }

                                StyledText {
                                    id: compactNameLabel
                                    font.pixelSize: Theme.fontSizeSmall + 1
                                    visible: !compactDelegateRoot.editing
                                    width: parent.width - Math.round(16 * root.sizeScale) - (root.pinnedPaths.indexOf(filePath) !== -1 ? 28 : 12)
                                    text: compactDelegateRoot.displayBaseName
                                    color: compactDelegateRoot.isEmpty ? root.emptyColor : Theme.surfaceText
                                    anchors.verticalCenter: parent.verticalCenter
                                    elide: Text.ElideRight
                                    maximumLineCount: 1
                                }

                                // Inline rename editor (replaces the label while editing)
                                Loader {
                                    active: compactDelegateRoot.editing
                                    visible: active
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - Math.round(16 * root.sizeScale) - (root.pinnedPaths.indexOf(compactDelegateRoot.filePath) !== -1 ? 28 : 12)
                                    height: active && item ? item.implicitHeight : 0
                                    sourceComponent: Component {
                                        FolderViewInlineRename {
                                            fontPixelSize: Theme.fontSizeSmall - 1
                                            targetName: compactDelegateRoot.fileName
                                            targetIsDir: compactDelegateRoot.fileIsDir
                                            onAccepted: newBaseName => {
                                                root.applyRename(compactDelegateRoot.filePath, compactDelegateRoot.fileName, compactDelegateRoot.fileIsDir, newBaseName);
                                                root.endInlineRename();
                                            }
                                            onCanceled: root.endInlineRename()
                                        }
                                    }
                                }
                            }

                            // Pin indicator
                            DankIcon {
                                name: "push_pin"
                                size: 12
                                color: Theme.primary
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.right: parent.right
                                anchors.rightMargin: Theme.spacingS
                                visible: root.pinnedPaths.indexOf(filePath) !== -1
                            }

                            MouseArea {
                                id: compactItemHover
                                anchors.fill: parent
                                enabled: !compactDelegateRoot.editing
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                acceptedButtons: Qt.LeftButton | Qt.MiddleButton

                                onClicked: mouse => {
                                    if (mouse.button === Qt.LeftButton) {
                                        if (compactDelegateRoot.filePath.startsWith("stack://")) {
                                            let stackId = compactDelegateRoot.filePath.substring(8);
                                            root.toggleStackExpanded(stackId);
                                            return;
                                        }
                                        if (mouse.modifiers & Qt.ControlModifier) {
                                            root.toggleSelection(compactDelegateRoot.filePath);
                                        } else if (mouse.modifiers & Qt.ShiftModifier) {
                                            root.selectRangeTo(compactDelegateRoot.index);
                                        } else {
                                            // Clicking the name label of an already-selected item starts
                                            // an inline rename; a double-click opens instead (see below).
                                            root.handleItemLabelClick(compactItemHover, compactNameLabel, mouse.x, mouse.y, compactDelegateRoot.filePath);
                                        }
                                    } else if (mouse.button === Qt.MiddleButton) {
                                        inlineRenameArmTimer.stop();
                                        if (root.selectedFilePaths.indexOf(compactDelegateRoot.filePath) === -1) {
                                            root.selectSingle(compactDelegateRoot.filePath);
                                        }

                                        quickMenu.currentPath = compactDelegateRoot.filePath;
                                        quickMenu.currentName = compactDelegateRoot.fileName;
                                        quickMenu.currentIsDir = compactDelegateRoot.fileIsDir;
                                        
                                        const globalPos = mapToItem(root, mouse.x, mouse.y);
                                        quickMenu.parent = root;
                                        quickMenu.x = Math.max(0, Math.min(root.width - quickMenu.width, globalPos.x));
                                        quickMenu.y = Math.max(0, Math.min(root.height - quickMenu.height, globalPos.y));
                                        quickMenu.open();
                                    }
                                }

                                onDoubleClicked: mouse => {
                                    if (mouse.button === Qt.LeftButton) {
                                        inlineRenameArmTimer.stop();
                                        if (compactDelegateRoot.filePath.startsWith("stack://")) {
                                            let stackId = compactDelegateRoot.filePath.substring(8);
                                            root.toggleStackExpanded(stackId);
                                            return;
                                        }
                                        compactDelegateRoot.isLaunching = true;
                                        compactLaunchPulse.restart();
                                        // Open file or navigate into folder
                                        if (compactDelegateRoot.fileIsDir) { root.navigateToFolder(compactDelegateRoot.filePath); } else if (compactDelegateRoot.isDesktop) {
                                            root.launchDesktopFile(compactDelegateRoot.filePath);
                                        } else {
                                            Quickshell.execDetached(["gio", "open", root._cleanPath(compactDelegateRoot.filePath)]);
                                        }
                                        compactLaunchTimer.restart();
                                        root.clearSelection();
                                    }
                                }
                            }
                        }
                    }
                }

                // Background area for middle-click on empty space → new file dialog
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.MiddleButton
                    z: -1
                    onClicked: mouse => {
                        if (mouse.button === Qt.MiddleButton)
                            createDialog.showFor(false);
                    }
                }

                // Wheel overlay — scroll, Ctrl+Wheel zooms, mouse side buttons for back/forward
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: false
                    acceptedButtons: Qt.ExtraButton1 | Qt.ExtraButton2
                    onWheel: wheel => {
                        if (wheel.modifiers & Qt.ControlModifier) {
                            let delta = wheel.angleDelta.y > 0 ? 2 : -2;
                            let newSize = Math.max(64, Math.min(128, root.cellSize + delta));
                            if (newSize !== root.cellSize) {
                                root.cellSize = newSize;
                                if (pluginService)
                                    pluginService.savePluginData(pluginId, "cellSize", newSize);
                            }
                            wheel.accepted = true;
                        } else {
                            var target = fileGrid.visible ? fileGrid :
                                         (fileList.visible ? fileList : fileCompact)
                            if (target && target.contentHeight > target.height) {
                                wheel.accepted = true
                                target.contentY = Math.max(0, Math.min(
                                    target.contentY - wheel.angleDelta.y,
                                    target.contentHeight - target.height))
                            }
                        }
                    }
                    onClicked: mouse => {
                        if (mouse.button === Qt.ExtraButton2 && root.folderHistory.length > 0)
                            root.goBackFolder();
                        else if (mouse.button === Qt.ExtraButton1 && root.forwardHistory.length > 0)
                            root.goForwardFolder();
                    }
                }

                // Placeholder when folder is empty or search returns no results
                Column {
                    anchors.centerIn: parent
                    spacing: Theme.spacingM
                    visible: filteredModel.count === 0 && folderModel.status === FolderListModel.Ready
                    width: parent.width * 0.8

                    DankIcon {
                        name: folderModel.count === 0 ? "folder_open" : "search_off"
                        size: 48
                        color: Theme.surfaceText
                        opacity: 0.25
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    StyledText {
                        text: folderModel.count === 0 
                            ? root.folderDisplayName + " " + I18n.tr("is empty") 
                            : I18n.tr("No search results found")
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceText
                        opacity: 0.4
                        horizontalAlignment: Text.AlignHCenter
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }

                // Copy files dragged in from external windows into the current
                // folder (Drag & Drop In). Disabled for the read-only Trash view.
                DropArea {
                    id: dropArea
                    anchors.fill: parent
                    z: 100
                    enabled: root.folderType !== "trash"
                    keys: ["text/uri-list"]

                    onEntered: drag => {
                        if (drag.hasUrls)
                            drag.accept(Qt.CopyAction);
                        else
                            drag.accepted = false;
                    }
                    onDropped: drop => {
                        if (!drop.hasUrls)
                            return;
                        root.dropFiles(drop.urls);
                        drop.accept(Qt.CopyAction);
                    }

                    // Drop hint shown while dragging files over the widget
                    Rectangle {
                        anchors.fill: parent
                        visible: dropArea.containsDrag
                        radius: Theme.cornerRadius
                        // Darkened background overlay for focus
                        color: Qt.rgba(0, 0, 0, 0.5)
                        
                        Rectangle {
                            anchors.fill: parent
                            radius: parent.radius
                            color: Theme.withAlpha(Theme.primary, 0.15)
                            border.color: Theme.primary
                            border.width: 2
                        }

                        Column {
                            anchors.centerIn: parent
                            spacing: Theme.spacingS

                            DankIcon {
                                name: "download"
                                size: 48
                                color: Theme.primary
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            StyledText {
                                text: I18n.tr("Drop to copy here")
                                font.pixelSize: Theme.fontSizeMedium
                                font.bold: true
                                color: Theme.primary
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }
                    }
                }
            }
        }
    }

    // Keyboard handler — inside StyledRect, as last child for highest z-order
    Item {
        id: keyHandler
        anchors.fill: parent
        focus: true

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                if (renameDialog.opened) renameDialog.close();
                else if (infoDialog.opened) infoDialog.close();
                else if (createDialog.opened) createDialog.close();
                else if (createAppDialog.opened) createAppDialog.close();
                else if (createStackDialog.opened) createStackDialog.close();
                else if (quickMenu.opened) quickMenu.close();
                else if (folderDropdown.opened) folderDropdown.close();
                else if (createDropdown.opened) createDropdown.close();
                else if (sortByDropdown.opened) sortByDropdown.close();
                else if (filterDropdown.opened) filterDropdown.close();
                else if (viewModeDropdown.opened) viewModeDropdown.close();
                else if (settingsDropdown.opened) settingsDropdown.close();
                else if (root.folderHistory.length > 0) root.goBackFolder();
                event.accepted = true;
            }
        }

        Component.onCompleted: forceActiveFocus()
    }

    // Persist dimensions when resized
    onWidgetWidthChanged: {
        if (pluginService && widgetWidth !== pluginData.widgetWidth) {
            pluginService.savePluginData(pluginId, "widgetWidth", widgetWidth);
        }
    }

    onWidgetHeightChanged: {
        if (pluginService && widgetHeight !== pluginData.widgetHeight) {
            pluginService.savePluginData(pluginId, "widgetHeight", widgetHeight);
        }
    }

    // Quick Action Menu on Middle Click
    Popup {
        id: quickMenu
        width: 180
        height: menuColumn.implicitHeight + Theme.spacingS * 2
        padding: 0
        modal: false
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        property string currentPath: ""
        property string currentName: ""
        property bool currentIsDir: false

        background: Rectangle {
            color: "transparent"
        }

        contentItem: Rectangle {
            color: Theme.withAlpha(Theme.surfaceContainer, 0.95)
            radius: Theme.cornerRadius
            border.color: Theme.withAlpha(Theme.outline, 0.15)
            border.width: 1

            Column {
                id: menuColumn
                anchors.fill: parent
                anchors.margins: Theme.spacingS
                spacing: 2

                Repeater {
                    model: [
                        {
                            text: I18n.tr("Open"),
                            icon: "open_in_new",
                            visible: true,
                            action: function() {
                                quickMenu.close();
                                for (let path of root.selectedFilePaths) {
                                    let clean = root._cleanPath(path);
                                    if (clean.endsWith(".desktop")) {
                                        root.launchDesktopFile(path);
                                    } else {
                                        Quickshell.execDetached(["gio", "open", clean]);
                                    }
                                }
                                root.clearSelection();
                            }
                        },
                        {
                            text: I18n.tr("Open with..."),
                            icon: "app_registration",
                            visible: root.selectedFilePaths.length === 1 && !quickMenu.currentPath.startsWith("stack://") && !quickMenu.currentIsDir,
                            action: function() {
                                quickMenu.close();
                                let clean = root._cleanPath(quickMenu.currentPath);
                                Quickshell.execDetached(["dms", "open", clean]);
                                root.clearSelection();
                            }
                        },
                        {
                            text: I18n.tr("Float File"),
                            icon: "picture_in_picture",
                            visible: root.selectedFilePaths.length === 1 && (root.isImage(quickMenu.currentName) || quickMenu.currentName.toLowerCase().endsWith(".pdf")),
                            action: function() {
                                quickMenu.close();
                                const path = root.selectedFilePaths[0];
                                Quickshell.execDetached(["dms", "ipc", "call", "floaty", "floatFromUrl", "file://" + path]);
                            }
                        },
                        {
                            text: I18n.tr("Copy"),
                            icon: "content_copy",
                            visible: true,
                            action: function() {
                                quickMenu.close();
                                const paths = root.selectedFilePaths;
                                const name = quickMenu.currentName;

                                // Single image file: use DMS clipboard.copyFile so it appears
                                // in the DMS clipboard history and can be pasted in any app.
                                if (paths.length === 1 && root.isImage(name)) {
                                    DMSService.sendRequest("clipboard.copyFile", { "filePath": paths[0] }, function(resp) {
                                        if (resp.error) {
                                            ToastService.showToast(I18n.tr("Copy failed") + ": " + resp.error, ToastService.levelError);
                                        } else {
                                            ToastService.showToast(I18n.tr("Image Copied") + ": " + name, ToastService.levelInfo);
                                        }
                                    });
                                    return;
                                }

                                // Multi-file or non-image: use wl-copy with the gnome URI
                                // format so the selection can be pasted into file managers.
                                // Note: dms cl copy cannot be used here because the DMS daemon
                                // intercepts and re-serves the entry, corrupting the content.
                                let uris = [];
                                for (let path of paths) {
                                    uris.push("file://" + path);
                                }
                                const cmd = "echo -ne \"copy\\n" + uris.join("\\n") + "\" | wl-copy -t x-special/gnome-copied-files";
                                Quickshell.execDetached(["bash", "-c", cmd]);

                                const label = paths.length > 1
                                    ? I18n.tr("Copied %1 items").arg(paths.length)
                                    : I18n.tr("File Copied") + ": " + name;
                                ToastService.showToast(label, ToastService.levelInfo);
                            }
                        },
                        {
                            text: I18n.tr("Copy Path"),
                            icon: "content_copy",
                            visible: true,
                            action: function() {
                                quickMenu.close();
                                const joinedPaths = root.selectedFilePaths.join("\n");
                                Quickshell.execDetached(["dms", "cl", "copy", joinedPaths]);
                                
                                let label = root.selectedFilePaths.length > 1
                                    ? I18n.tr("Copied %1 paths").arg(root.selectedFilePaths.length)
                                    : I18n.tr("Copied to Clipboard") + ": " + quickMenu.currentName;
                                ToastService.showToast(label, ToastService.levelInfo);
                            }
                        },
                        {
                            text: I18n.tr("Rename"),
                            icon: "edit",
                            visible: root.selectedFilePaths.length <= 1,
                            action: function() {
                                quickMenu.close();
                                renameDialog.showFor(quickMenu.currentPath, quickMenu.currentName, quickMenu.currentIsDir);
                            }
                        },
                        {
                            text: I18n.tr("Info"),
                            icon: "info",
                            visible: root.selectedFilePaths.length <= 1 && !quickMenu.currentPath.startsWith("stack://"),
                            action: function() {
                                quickMenu.close();
                                infoDialog.showFor(quickMenu.currentPath, quickMenu.currentName, quickMenu.currentIsDir);
                            }
                        },
                        {
                            actionName: "pin",
                            visible: true,
                            action: function() {
                                quickMenu.close();
                                root.togglePin(quickMenu.currentPath);
                            }
                        },
                        {
                            text: I18n.tr("Group into Stack"),
                            icon: "layers",
                            visible: root.selectedFilePaths.length > 1 && root.selectedFilePaths.every(p => !p.startsWith("stack://")),
                            action: function() {
                                quickMenu.close();
                                createStackDialog.showFor(root.selectedFilePaths);
                            }
                        },
                        {
                            text: I18n.tr("Ungroup Stack"),
                            icon: "layers_clear",
                            visible: root.selectedFilePaths.length === 1 && quickMenu.currentPath.startsWith("stack://"),
                            action: function() {
                                quickMenu.close();
                                let stackId = quickMenu.currentPath.substring(8);
                                root.ungroupStack(stackId);
                            }
                        },
                        { isSeparator: true },
                        {
                            text: I18n.tr("Move to Trash"),
                            icon: "delete",
                            dangerous: true,
                            visible: root.selectedFilePaths.every(p => !p.startsWith("stack://")),
                            action: function() {
                                quickMenu.close();
                                const cleanPaths = root.selectedFilePaths.map(p => root._cleanPath(p));
                                Quickshell.execDetached(["gio", "trash"].concat(cleanPaths));
                                root.clearSelection();
                            }
                        }
                    ]

                    delegate: Rectangle {
                        width: parent.width
                        property bool isSeparator: !!modelData.isSeparator
                        property bool itemVisible: modelData.visible !== undefined ? modelData.visible : true
                        visible: itemVisible
                        height: !itemVisible ? 0 : (isSeparator ? 9 : 28)
                        radius: isSeparator ? 0 : Theme.cornerRadius - 2
                        color: isSeparator 
                            ? "transparent"
                            : (menuArea.containsMouse 
                                ? (modelData.dangerous ? Theme.withAlpha(Theme.error, 0.15) : Theme.withAlpha(Theme.primary, 0.15)) 
                                : "transparent")

                        Rectangle {
                            anchors.centerIn: parent
                            width: parent.width - Theme.spacingS * 2
                            height: 1
                            color: Theme.withAlpha(Theme.outline, 0.15)
                            visible: isSeparator
                        }

                        Row {
                            visible: !isSeparator
                            anchors.left: parent.left
                            anchors.leftMargin: Theme.spacingS
                            anchors.right: parent.right
                            anchors.rightMargin: Theme.spacingS
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Theme.spacingS

                            DankIcon {
                                name: modelData.actionName === "pin"
                                    ? "push_pin"
                                    : (modelData.icon || "")
                                size: 14
                                color: modelData.dangerous && menuArea.containsMouse ? Theme.error : Theme.surfaceText
                                anchors.verticalCenter: parent.verticalCenter
                                visible: !isSeparator && parent.parent.itemVisible
                            }

                            StyledText {
                                text: modelData.actionName === "pin"
                                    ? (root.pinnedPaths.indexOf(quickMenu.currentPath) !== -1 ? I18n.tr("Unpin from Top") : I18n.tr("Pin to Top"))
                                    : (modelData.text || "")
                                font.pixelSize: Theme.fontSizeSmall
                                color: modelData.dangerous && menuArea.containsMouse ? Theme.error : Theme.surfaceText
                                anchors.verticalCenter: parent.verticalCenter
                                elide: Text.ElideRight
                                visible: !isSeparator && parent.parent.itemVisible
                            }
                        }

                        MouseArea {
                            id: menuArea
                            anchors.fill: parent
                            enabled: !isSeparator
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: modelData.action()
                        }
                    }
                }
            }
        }
    }

    // Rename Dialog
    FolderViewRenameDialog {
        id: renameDialog
    }

    // Create Stack Dialog
    FolderViewCreateStackDialog {
        id: createStackDialog
    }

    // Info Dialog
    FolderViewInfoDialog {
        id: infoDialog
    }

    // Create Folder/File Dialog
    FolderViewCreateDialog {
        id: createDialog
        targetFolderUrl: root.targetFolderUrl
    }

    // Create App Dialog
    FolderViewCreateAppDialog {
        id: createAppDialog
        targetFolderUrl: root.targetFolderUrl
    }

    // Folder Switcher Dropdown Popup
    Popup {
        id: folderDropdown
        parent: folderSelectorBtn
        width: 140
        height: folderDropdownColumn.implicitHeight + Theme.spacingS * 2
        padding: 0
        modal: true
        dim: false
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        x: 0
        y: root.headerPosition === "bottom" ? -height - 4 : folderSelectorBtn.height + 4

        background: Rectangle {
            color: "transparent"
        }

        contentItem: Rectangle {
            color: Theme.withAlpha(Theme.surfaceContainer, 0.95)
            radius: Theme.cornerRadius
            border.color: Theme.withAlpha(Theme.outline, 0.15)
            border.width: 1

            Column {
                id: folderDropdownColumn
                anchors.fill: parent
                anchors.margins: Theme.spacingS
                spacing: 2

                Repeater {
                    model: root.folderDropdownModel

                    delegate: Rectangle {
                        width: parent.width
                        height: modelData.value === "separator" ? 10 : 28
                        radius: Theme.cornerRadius - 2
                        color: !isSeparator && dropdownItemArea.containsMouse
                            ? Theme.withAlpha(Theme.primary, 0.15)
                            : "transparent"

                        readonly property bool isSeparator: modelData.value === "separator"
                        readonly property bool isPinned: modelData.value === "pinned" || modelData.value === "bookmark"

                        // Separator line
                        Rectangle {
                            anchors.left: parent.left; anchors.leftMargin: Theme.spacingS
                            anchors.right: parent.right; anchors.rightMargin: Theme.spacingS
                            anchors.verticalCenter: parent.verticalCenter
                            height: 1
                            color: Theme.withAlpha(Theme.outline, 0.12)
                            visible: isSeparator
                        }

                        // Normal item row (hidden for separator)
                        Row {
                            visible: !isSeparator
                            anchors.left: parent.left
                            anchors.leftMargin: Theme.spacingS
                            anchors.right: parent.right
                            anchors.rightMargin: Theme.spacingS
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Theme.spacingS

                            DankIcon {
                                name: modelData.icon || "folder"
                                size: 14
                                color: isPinned ? Theme.primary : (root.folderType === modelData.value ? Theme.primary : Theme.surfaceText)
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            StyledText {
                                text: modelData.label
                                font.pixelSize: Theme.fontSizeSmall
                                font.bold: isPinned || root.folderType === modelData.value
                                color: isPinned ? Theme.primary : (root.folderType === modelData.value ? Theme.primary : Theme.surfaceText)
                                anchors.verticalCenter: parent.verticalCenter
                                elide: Text.ElideRight
                            }
                        }

                        MouseArea {
                            id: dropdownItemArea
                            anchors.fill: parent
                            hoverEnabled: !isSeparator
                            cursorShape: isSeparator ? Qt.ArrowCursor : Qt.PointingHandCursor
                            visible: !isSeparator

                            onClicked: {
                                folderDropdown.close();
                                if (isPinned) {
                                    root.navigateToFolder(modelData.path);
                                } else if (modelData.value === "custom") {
                                    folderPickerDialog.open();
                                } else {
                                    // Default standard folder type
                                    var stdPath = root.resolveStandardFolderPath(modelData.value);
                                    if (stdPath !== "") {
                                        root.navigateToFolder(stdPath);
                                        // Override folderType so display name shows correctly (navigateToFolder sets it to "custom")
                                        if (pluginService) {
                                            pluginService.savePluginData(pluginId, "folderType", modelData.value);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Create Dropdown Popup
    Popup {
        id: createDropdown
        parent: createBtn
        width: 140
        height: createDropdownColumn.implicitHeight + Theme.spacingS * 2
        padding: 0
        modal: true
        dim: false
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        x: createBtn.width - createDropdown.width
        y: root.headerPosition === "bottom" ? -height - 4 : createBtn.height + 4

        background: Rectangle {
            color: "transparent"
        }

        contentItem: Rectangle {
            color: Theme.withAlpha(Theme.surfaceContainer, 0.95)
            radius: Theme.cornerRadius
            border.color: Theme.withAlpha(Theme.outline, 0.15)
            border.width: 1

            Column {
                id: createDropdownColumn
                anchors.fill: parent
                anchors.margins: Theme.spacingS
                spacing: 2

                Repeater {
                    model: [
                        { label: I18n.tr("New Folder"), value: "folder", icon: "create_new_folder" },
                        { label: I18n.tr("New Document"), value: "file", icon: "note_add" },
                        { label: I18n.tr("New App"), value: "app", icon: "add_to_home_screen" }
                    ]

                    delegate: Rectangle {
                        width: parent.width
                        height: 28
                        radius: Theme.cornerRadius - 2
                        color: createDropdownItemArea.containsMouse 
                            ? Theme.withAlpha(Theme.primary, 0.15) 
                            : "transparent"

                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: Theme.spacingS
                            anchors.right: parent.right
                            anchors.rightMargin: Theme.spacingS
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Theme.spacingS

                            DankIcon {
                                name: modelData.icon
                                size: 14
                                color: Theme.surfaceText
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            StyledText {
                                text: modelData.label
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceText
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            id: createDropdownItemArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                createDropdown.close();
                                if (modelData.value === "app") {
                                    createAppDialog.show();
                                } else {
                                    createDialog.showFor(modelData.value === "folder");
                                }
                            }
                        }
                    }
                }
            }
        }
    }



    // Sort By Dropdown Popup
    Popup {
        id: sortByDropdown
        parent: sortByBtn
        width: 140
        height: sortByDropdownColumn.implicitHeight + Theme.spacingS * 2
        padding: 0
        modal: true
        dim: false
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        x: sortByBtn.width - sortByDropdown.width
        y: root.headerPosition === "bottom" ? -height - 4 : sortByBtn.height + 4

        background: Rectangle {
            color: "transparent"
        }

        contentItem: Rectangle {
            color: Theme.withAlpha(Theme.surfaceContainer, 0.95)
            radius: Theme.cornerRadius
            border.color: Theme.withAlpha(Theme.outline, 0.15)
            border.width: 1

            Column {
                id: sortByDropdownColumn
                anchors.fill: parent
                anchors.margins: Theme.spacingS
                spacing: 2

                Repeater {
                    model: [
                        { label: I18n.tr("Sort by Name"), value: "name", icon: "sort_by_alpha" },
                        { label: I18n.tr("Sort by Date"), value: "time", icon: "schedule" },
                        { label: I18n.tr("Sort by Size"), value: "size", icon: "bar_chart" },
                        { label: I18n.tr("Sort by Type"), value: "type", icon: "category" }
                    ]

                    delegate: Rectangle {
                        width: parent.width
                        height: 28
                        radius: Theme.cornerRadius - 2
                        color: sortByArea.containsMouse 
                            ? Theme.withAlpha(Theme.primary, 0.15) 
                            : "transparent"

                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: Theme.spacingS
                            anchors.right: parent.right
                            anchors.rightMargin: Theme.spacingS
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Theme.spacingS

                            DankIcon {
                                name: modelData.icon
                                size: 14
                                color: root.sortBy === modelData.value ? Theme.primary : Theme.surfaceText
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            StyledText {
                                text: modelData.label
                                font.pixelSize: Theme.fontSizeSmall
                                font.bold: root.sortBy === modelData.value
                                color: root.sortBy === modelData.value ? Theme.primary : Theme.surfaceText
                                anchors.verticalCenter: parent.verticalCenter
                                elide: Text.ElideRight
                            }
                        }

                        MouseArea {
                            id: sortByArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                sortByDropdown.close();
                                if (pluginService) {
                                    pluginService.savePluginData(pluginId, "sortBy", modelData.value);
                                }
                            }
                        }
                    }
                }
            }
        }
    }



    // Filter Dropdown Popup
    Popup {
        id: filterDropdown
        parent: filterBtn
        width: 160
        height: filterDropdownColumn.implicitHeight + Theme.spacingS * 2
        padding: 0
        modal: true
        dim: false
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        x: filterBtn.width - filterDropdown.width
        y: root.headerPosition === "bottom" ? -height - 4 : filterBtn.height + 4
 
        background: Rectangle {
            color: "transparent"
        }
 
        contentItem: Rectangle {
            color: Theme.withAlpha(Theme.surfaceContainer, 0.95)
            radius: Theme.cornerRadius
            border.color: Theme.withAlpha(Theme.outline, 0.15)
            border.width: 1
 
            Column {
                id: filterDropdownColumn
                anchors.fill: parent
                anchors.margins: Theme.spacingS
                spacing: 4
 
                // Section 1: File Type
                StyledText {
                    text: I18n.tr("File Type")
                    font.pixelSize: Theme.fontSizeSmall - 1
                    font.bold: true
                    color: Theme.surfaceVariantText
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.spacingS
                }
 
                Repeater {
                    model: [
                        { label: I18n.tr("All Files"), value: "all", icon: "menu" },
                        { label: I18n.tr("Folders Only"), value: "folders", icon: "folder" },
                        { label: I18n.tr("Files Only"), value: "files", icon: "description" },
                        { label: I18n.tr("Images Only"), value: "images", icon: "image" },
                        { label: I18n.tr("Documents Only"), value: "documents", icon: "article" },
                        { label: I18n.tr("Audio & Video"), value: "audio_video", icon: "movie" }
                    ]
 
                    delegate: Rectangle {
                        width: parent.width
                        height: 24
                        radius: Theme.cornerRadius - 2
                        color: typeArea.containsMouse ? Theme.withAlpha(Theme.primary, 0.15) : "transparent"
 
                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: Theme.spacingS
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Theme.spacingS
 
                            DankIcon {
                                name: modelData.icon
                                size: 12
                                color: root.filterType === modelData.value ? Theme.primary : Theme.surfaceText
                                anchors.verticalCenter: parent.verticalCenter
                            }
 
                            StyledText {
                                text: modelData.label
                                font.pixelSize: Theme.fontSizeSmall - 1
                                font.bold: root.filterType === modelData.value
                                color: root.filterType === modelData.value ? Theme.primary : Theme.surfaceText
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
 
                        MouseArea {
                            id: typeArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.filterType = modelData.value;
                                filterDropdown.close();
                            }
                        }
                    }
                }
 
                Rectangle {
                    width: parent.width
                    height: 1
                    color: Theme.withAlpha(Theme.outline, 0.1)
                }
 
                // Section 2: Time
                StyledText {
                    text: I18n.tr("Time Modified")
                    font.pixelSize: Theme.fontSizeSmall - 1
                    font.bold: true
                    color: Theme.surfaceVariantText
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.spacingS
                }
 
                Repeater {
                    model: [
                        { label: I18n.tr("Any Time"), value: "all", icon: "schedule" },
                        { label: I18n.tr("Last 24 Hours"), value: "today", icon: "today" },
                        { label: I18n.tr("Last 7 Days"), value: "week", icon: "date_range" },
                        { label: I18n.tr("Last 30 Days"), value: "month", icon: "calendar_month" },
                        { label: I18n.tr("Last 365 Days"), value: "year", icon: "history" }
                    ]

                    delegate: Rectangle {
                        width: parent.width
                        height: 24
                        radius: Theme.cornerRadius - 2
                        color: timeArea.containsMouse ? Theme.withAlpha(Theme.primary, 0.15) : "transparent"

                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: Theme.spacingS
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Theme.spacingS

                            DankIcon {
                                name: modelData.icon
                                size: 12
                                color: root.filterTime === modelData.value ? Theme.primary : Theme.surfaceText
                                anchors.verticalCenter: parent.verticalCenter
                            }
 
                            StyledText {
                                text: modelData.label
                                font.pixelSize: Theme.fontSizeSmall - 1
                                font.bold: root.filterTime === modelData.value
                                color: root.filterTime === modelData.value ? Theme.primary : Theme.surfaceText
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
 
                        MouseArea {
                            id: timeArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.filterTime = modelData.value;
                                filterDropdown.close();
                            }
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: Theme.withAlpha(Theme.outline, 0.1)
                }

                // Show Hidden Files toggle
                Rectangle {
                    width: parent.width
                    height: 28
                    radius: Theme.cornerRadius - 2
                    color: hiddenArea.containsMouse ? Theme.withAlpha(Theme.primary, 0.15) : "transparent"

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: Theme.spacingS
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Theme.spacingS

                        DankIcon {
                            name: root.showHidden ? "visibility" : "visibility_off"
                            size: 14
                            color: root.showHidden ? Theme.primary : Theme.surfaceText
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        StyledText {
                            text: I18n.tr("Show Hidden Files")
                            font.pixelSize: Theme.fontSizeSmall - 1
                            font.bold: root.showHidden
                            color: root.showHidden ? Theme.primary : Theme.surfaceText
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        id: hiddenArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.showHidden = !root.showHidden;
                            if (pluginService)
                                pluginService.savePluginData(pluginId, "showHidden", root.showHidden);
                            filterDropdown.close();
                        }
                    }
                }
            }
        }
    }

    // Native Folder Dialog Selector
    FolderDialog {
        id: folderPickerDialog
        title: I18n.tr("Select Folder")
        currentFolder: root.targetFolderUrl
        onAccepted: {
            let path = root._cleanPath(selectedFolder);
            if (pluginService) {
                pluginService.savePluginData(pluginId, "customFolderPath", path);
                pluginService.savePluginData(pluginId, "folderType", "custom");
            }
        }
    }
}

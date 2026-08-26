/*
 * SPDX-FileCopyrightText: Copyright (C) 2025 kalaksi@users.noreply.github.com
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts


Item {
    id: root
    width: 600
    height: 400

    required property string directorySeparator

    /// Has to be given if using split view with directory tree.
    property string directoryTreeRootPath: "/"
    property string rootPath: root.directoryTreeRootPath
    property int indentWidth: 20
    property int rowHeight: 28
    property int arrowWidth: 20
    property int nameColumnWidth: 200
    property var columnHeaders: []
    property var columnWidths: [0.4]
    property color headerColor: palette.alternateBase
    property color headerBorderColor: palette.mid
    property int sortColumnIndex: 0
    property bool sortAscending: true
    property Menu contextMenu: null
    property bool useSplitView: false
    /// Space beside the directory tree so the split handle does not overlap its scrollbar.
    property int splitHandleGap: 4
    /// Hide directories in the file list.
    property bool hideDirectories: false
    /// When set, used as directory icon in tree views. When empty, a generic folder symbol is shown.
    property string directoryIconSource: ""
    /// Paths to show with reduced opacity (e.g. rows marked for move).
    property var dimmedPaths: []
    property bool enableShortcuts: false

    /// When null, default platform ScrollBar; else used for every tree view (single and split).
    property Component verticalScrollBar: null

    readonly property string selectedDirectory: dirTreeView && dirTreeView.selectedPaths.length > 0 ?
        dirTreeView.selectedPaths[0] : ""

    readonly property var selectedFiles: fileListView && fileListView.selectedPaths.length > 0 ?
        fileListView.selectedPaths : []

    readonly property var selectedFilesOnly: root.selectedFiles ?
        root.selectedFiles.filter(path => !path.endsWith(root.directorySeparator)) : []

    readonly property bool hasSingleSelection: (root.useSplitView && fileListView.selectedPaths.length === 1) ||
        (!root.useSplitView && treeView.selectedPaths.length === 1)

    readonly property bool canNavigateBack: root._historyIndex > 0
    readonly property bool canNavigateForward: root._historyIndex >= 0
        && root._historyIndex < root._historyPaths.length - 1

    property int _maxColumns: 8
    property var _cache: ({})
    property var _expandedDirs: ({})
    property string _expandDirsToPath: ""
    property var _historyPaths: []
    property int _historyIndex: -1
    // -1 = going back, 1 = going forward, 0 = not a history navigation
    property int _pendingHistoryDirection: 0
    // Directory whose next successful response should update the split-view file list.
    property string _pendingFileListPath: ""

    signal directoryExpanded(string path, bool isCached)
    // Contract: the handler must apply the rename and then trigger a refresh (re-list the
    // directory and call openDirectory()/refreshView()). The renamed entry is then
    // automatically re-selected, and scrolled into view, on the next refresh that contains it.
    signal renamed(string fullPath, string newName)

    onColumnHeadersChanged: {
        if (root.columnHeaders.length > root._maxColumns) {
            console.error("FileBrowser: too many columns, maximum allowed is " + root._maxColumns + ".")
            root.columnHeaders = root.columnHeaders.slice(0, root._maxColumns)
        }
    }

    onSelectedDirectoryChanged: {
        let path = root.selectedDirectory
        if (path === "") {
            return
        }
        if (root._expandDirsToPath !== "") {
            return
        }
        // Skip if this is the result of a history navigation we already recorded.
        if (root._historyIndex >= 0 && root._historyPaths[root._historyIndex] === path) {
            root._pendingHistoryDirection = 0
            return
        }
        root._historyPaths = root._historyPaths.slice(0, root._historyIndex + 1).concat([path])
        root._historyIndex = root._historyPaths.length - 1
    }

    Column {
        id: treeViewContainer
        anchors.fill: parent
        visible: !root.useSplitView

        FileBrowserHeader {
            id: header
            width: parent.width
            syncView: treeView.tableView
            rowHeight: root.rowHeight
            columnHeaders: root.columnHeaders
            headerColor: root.headerColor
            headerBorderColor: root.headerBorderColor
            sortColumnIndex: root.sortColumnIndex
            sortAscending: root.sortAscending
            _maxColumns: root._maxColumns

            onHeaderClicked: function(columnIndex) {
                if (columnIndex === root.sortColumnIndex) {
                    root.sortAscending = !root.sortAscending
                }
                else {
                    root.sortColumnIndex = columnIndex
                    root.sortAscending = true
                }
            }
        }

        FileBrowserTreeView {
            id: treeView
            rootPath: root.rootPath
            directorySeparator: root.directorySeparator
            width: parent.width
            height: parent.height - header.height
            indentWidth: root.indentWidth
            rowHeight: root.rowHeight
            arrowWidth: root.arrowWidth
            contextMenu: root.contextMenu
            directoryIconSource: root.directoryIconSource
            dimmedPaths: root.dimmedPaths
            sortColumnIndex: root.sortColumnIndex
            sortAscending: root.sortAscending
            singleSelection: true
            _cache: root._cache
            _expandedDirs: root._expandedDirs
            _maxColumns: root._maxColumns
            verticalScrollBar: root.verticalScrollBar

            onDirectoryExpanded: function(path, isCached) {
                root.directoryExpanded(path, isCached)
            }

            onDirectoryActivated: function(path) {
                let isCached = root._cache[path] !== undefined
                root.directoryExpanded(path, isCached)
            }

            onRenamed: function(fullPath, newName) {
                root.renamed(fullPath, newName)
            }

            Component.onCompleted: {
                let tw = treeView.tableView.width
                for (let c = 0; c < 1 + root._maxColumns; c++) {
                    treeView.tableView.setColumnWidth(c, root._getColumnWidth(c, tw))
                }
            }
        }
    }

    SplitView {
        id: splitViewContainer
        anchors.fill: parent
        orientation: Qt.Horizontal
        visible: root.useSplitView

        // Some platform styles expand the handle's hit area far enough into the directory
        // pane to overlap its vertical scrollbar. Keep a modest grab area biased toward the
        // file-list side, with only a small portion extending into the directory pane.
        handle: Rectangle {
            id: splitHandle
            implicitWidth: 2
            implicitHeight: 2
            color: SplitHandle.pressed ? palette.dark
                : (SplitHandle.hovered ? palette.midlight : palette.mid)

            containmentMask: Item {
                x: -2
                width: 8
                height: splitHandle.height
            }
        }

        Item {
            SplitView.preferredWidth: parent.width * 0.25
            SplitView.minimumWidth: 100

            FileBrowserTreeView {
                id: dirTreeView
                rootPath: root.directoryTreeRootPath
                directorySeparator: root.directorySeparator
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.rightMargin: root.splitHandleGap
                anchors.top: parent.top
                anchors.topMargin: root.rowHeight
                anchors.bottom: parent.bottom
                indentWidth: root.indentWidth
                rowHeight: root.rowHeight
                arrowWidth: root.arrowWidth
                directoryIconSource: root.directoryIconSource
                dimmedPaths: root.dimmedPaths
                hideFiles: true
                singleSelection: true
                enableDirectoryNavigation: true
                _cache: root._cache
                _expandedDirs: root._expandedDirs
                _maxColumns: root._maxColumns
                verticalScrollBar: root.verticalScrollBar

                columnWidthProvider: function(column, totalWidth) {
                    return column === 0 ? totalWidth : 0
                }

                onDirectoryExpanded: function(path, isCached) {
                    root.directoryExpanded(path, isCached)
                }

                onFileListNavigationRequested: function(path) {
                    root._pendingFileListPath = path
                }

                onSelectionChanged: function(_paths) {
                    fileListView.refreshView()
                }
            }
        }

        Column {
            SplitView.fillWidth: true

            FileBrowserHeader {
                id: fileHeader
                width: parent.width
                syncView: fileListView.tableView
                rowHeight: root.rowHeight
                columnHeaders: root.columnHeaders
                headerColor: root.headerColor
                headerBorderColor: root.headerBorderColor
                sortColumnIndex: root.sortColumnIndex
                sortAscending: root.sortAscending
                _maxColumns: root._maxColumns

                onHeaderClicked: function(columnIndex) {
                    if (columnIndex === root.sortColumnIndex) {
                        root.sortAscending = !root.sortAscending
                    }
                    else {
                        root.sortColumnIndex = columnIndex
                        root.sortAscending = true
                    }
                }
            }

            FileBrowserTreeView {
                id: fileListView
                rootPath: root.selectedDirectory
                directorySeparator: root.directorySeparator
                width: parent.width
                height: parent.height - fileHeader.height
                indentWidth: root.indentWidth
                rowHeight: root.rowHeight
                arrowWidth: root.arrowWidth
                contextMenu: root.contextMenu
                directoryIconSource: root.directoryIconSource
                dimmedPaths: root.dimmedPaths
                sortColumnIndex: root.sortColumnIndex
                sortAscending: root.sortAscending
                hideDirectories: root.hideDirectories
                enableDirectoryNavigation: false
                _cache: root._cache
                _maxColumns: root._maxColumns
                verticalScrollBar: root.verticalScrollBar

                onDirectoryExpanded: function(path, isCached) {
                    root.directoryExpanded(path, isCached)
                }

                onDirectoryActivated: function(path) {
                    let isCached = root._cache[path] !== undefined
                    root._pendingFileListPath = path
                    // This request already drives navigation; selecting the matching tree
                    // row must not emit a duplicate directoryExpanded request.
                    dirTreeView.suppressDirectoryExpandedOnSelect = true
                    root.directoryExpanded(path, isCached)
                    dirTreeView.selectPath(path)
                    dirTreeView.suppressDirectoryExpandedOnSelect = false
                }

                onRenamed: function(fullPath, newName) {
                    root.renamed(fullPath, newName)
                }

                Component.onCompleted: {
                    Qt.callLater(function() {
                        let tw = fileListView.tableView.width
                        for (let c = 0; c < 1 + root._maxColumns; c++) {
                            fileListView.tableView.setColumnWidth(c, root._getColumnWidth(c, tw))
                        }
                    })
                }
            }
        }
    }

    Action {
        id: openFileFilter
        enabled: root.enableShortcuts && root.useSplitView
        shortcut: StandardKey.Find
        onTriggered: root.openFilterBar()
    }

    Action {
        id: closeFileFilter
        enabled: root.enableShortcuts && root.useSplitView && fileListView.showFilterBar
        shortcut: StandardKey.Cancel
        onTriggered: root.closeFilterBar()
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.BackButton | Qt.ForwardButton
        onClicked: function(mouse) {
            if (mouse.button === Qt.BackButton) {
                root.navigateBack()
            }
            else if (mouse.button === Qt.ForwardButton) {
                root.navigateForward()
            }
        }
    }

    /// Opens at the given path; initiates listing requests and expands the dir tree segment by segment.
    function openInitialDirectory(dirPath) {
        let normalizedPath = root._normalizeDirectoryPath(dirPath)
        root._pendingFileListPath = normalizedPath
        // Expands the directory tree segment by segment until the path is reached.
        // Keeping the root itself as a target also ensures its file list is initially populated.
        root._expandDirsToPath = normalizedPath

        root.directoryExpanded(root.directoryTreeRootPath, false)
    }

    /// Updates the file list only for the response matching the latest navigation request.
    /// Arrow-only expansion never sets this target, so it only affects the directory tree.
    function _navigateFileListIfRequested(normalizedPath) {
        if (!root.useSplitView || normalizedPath !== root._pendingFileListPath) {
            return
        }
        root._pendingFileListPath = ""
        fileListView.rootPath = normalizedPath
        fileListView.refreshView()
    }

    function openDirectory(dirPath, fileEntries) {
        let normalizedPath = root._normalizeDirectoryPath(dirPath)

        if (normalizedPath in root._expandedDirs
            && root._expandedDirs[normalizedPath] === true
            && (fileEntries === undefined || fileEntries === null)
            && root._expandDirsToPath === "") {

            // Already expanded with content; update file list only when this is navigation
            // (row select), not expand-only via the arrow.
            if (root.useSplitView) {
                root._navigateFileListIfRequested(normalizedPath)
            }
            else {
                treeView.rootPath = normalizedPath
                treeView.refreshView()
            }
            return
        }

        let wasCached = normalizedPath in root._cache

        // Make sure to not just mutate in place.
        let newExpandedDirs = Object.assign({}, root._expandedDirs)
        newExpandedDirs[normalizedPath] = true
        root._expandedDirs = newExpandedDirs

        if (fileEntries !== undefined && fileEntries !== null) {
            root._cache[normalizedPath] = fileEntries
        }

        let cachedEntries = root._cache[normalizedPath]
        if (cachedEntries === undefined || cachedEntries === null) {
            console.error(`Contents for directory ${normalizedPath} haven't been provided`)
            return
        }

        if (wasCached) {
            if (root.useSplitView) {
                let wasSuppressingSelection = dirTreeView.suppressDirectoryExpandedOnSelect
                if (root._expandDirsToPath !== "") {
                    dirTreeView.suppressDirectoryExpandedOnSelect = true
                }
                dirTreeView.refreshView()
                dirTreeView.suppressDirectoryExpandedOnSelect = wasSuppressingSelection
            }
            else {
                treeView.refreshView()
            }
        }
        else {
            if (root.useSplitView) {
                dirTreeView.insertDirectoryContent(normalizedPath, cachedEntries)
            }
            else {
                treeView.insertDirectoryContent(normalizedPath, cachedEntries)
                treeView.rootPath = normalizedPath
            }
        }

        if (root.useSplitView) {
            root._navigateFileListIfRequested(normalizedPath)
        }

        // Handle expansion of the directory tree to the given path if opening directory from deeper level.
        if (root._expandDirsToPath !== "") {
            if (!root.useSplitView) {
                root._expandDirsToPath = ""
                return
            }

            if (normalizedPath === root._expandDirsToPath) {
                root._expandDirsToPath = ""
                // The target response already populated the file list.
                dirTreeView.suppressDirectoryExpandedOnSelect = true
                dirTreeView.selectPath(normalizedPath)
                dirTreeView.suppressDirectoryExpandedOnSelect = false
                return
            }

            let remainingPath = root._expandDirsToPath.substring(normalizedPath.length)
            let remainingSegments = root._getPathComponents(remainingPath)
            if (remainingSegments.length > 0) {
                let nextPath = root._normalizeDirectoryPath(normalizedPath + remainingSegments[0])
                root.directoryExpanded(nextPath, root._cache[nextPath] !== undefined)
            }
            else {
                root._expandDirsToPath = ""
            }
        }
    }

    function refreshView() {
        if (root.useSplitView) {
            dirTreeView.refreshView()
            fileListView.refreshView()
        }
        else {
            treeView.refreshView()
        }
    }

    function openFilterBar() {
        fileListView.showFilterBar = true
        fileListView.focusFilterField()
    }

    function closeFilterBar() {
        fileListView.showFilterBar = false
    }

    function toggleDirectory(normalizedPath) {
        if (root.useSplitView) {
            dirTreeView.toggleDirectory(normalizedPath)
        }
        else {
            treeView.toggleDirectory(normalizedPath)
        }
    }

    function clearCache() {
        root._cache = {}
        root._expandedDirs = {}
        root._expandDirsToPath = ""
        root._pendingFileListPath = ""
        root.refreshView()
    }

    function startRenameForSelected() {
        if (root.useSplitView) {
            fileListView.startRename()
        }
        else {
            treeView.startRename()
        }
    }

    function selectFilePath(path) {
        if (root.useSplitView) {
            fileListView.selectPath(path)
        }
        else {
            treeView.selectPath(path)
        }
    }

    function getCellValue(path, columnIndex) {
        let view = root.useSplitView ? fileListView : treeView
        for (let r = 0; r < view.tableView.model.rowCount; r++) {
            if (view.getPathAtRow(r) === path)
                return view.getCellValue(r, columnIndex)
        }
        return undefined
    }

    function buildEntry(directory, name, fileType, columnData) {
        if (columnData.length !== root.columnHeaders.length) {
            console.error("Column data length does not match column headers length")
            return null
        }
        if (root.columnHeaders.length > root._maxColumns) {
            console.error("FileBrowser: too many columns, maximum allowed is " + root._maxColumns + ".")
            return null
        }

        let fullPath = root._normalizeDirectoryPath(directory) + name
        if (fileType === "d") {
            fullPath = root._normalizeDirectoryPath(fullPath)
        }

        let result = {
            name: name,
            fullPath: fullPath,
            fileType: fileType
        };

        for (let i = 0; i < root._maxColumns; i++) {
            if (i < columnData.length) {
                result["column-" + i] = columnData[i]
            }
            else {
                result["column-" + i] = ""
            }
        }

        return result
    }

    // TODO: implement for non-unix systems.
    function _normalizeDirectoryPath(path) {
        if (!path.endsWith(root.directorySeparator) && path !== "/") {
            path = path + root.directorySeparator
        }
        return path
    }

    function _getColumnWidth(column, tableViewWidth) {
        if (column < root.columnWidths.length) {
            return root.columnWidths[column] * tableViewWidth
        }

        if (column > root.columnHeaders.length) {
            return 0
        }

        let missingWidths = root.columnHeaders.length - root.columnWidths.length + 1
        if (missingWidths > 0) {
            let remainingWidth = Math.max(0.0, 1.0 - root.columnWidths.reduce((total, width) => total + width, 0))
            let evenWidth = remainingWidth / missingWidths
            return evenWidth * tableViewWidth
        }
        return 0
    }

    function _getPathComponents(fullPath) {
        let parts = fullPath.split(root.directorySeparator).filter(p => p.length > 0)
        return parts
    }

    /// Called by the parent when a directory listing failed for the given path.
    /// Returns true if the error was handled as a history navigation (caller should not log it).
    function navigationError(path) {
        let normalizedPath = root._normalizeDirectoryPath(path)
        if (normalizedPath === root._pendingFileListPath) {
            root._pendingFileListPath = ""
        }
        // Failure at any segment makes the remaining expand-to-path traversal impossible.
        if (root._expandDirsToPath.startsWith(normalizedPath)) {
            if (root._pendingFileListPath === root._expandDirsToPath) {
                root._pendingFileListPath = ""
            }
            root._expandDirsToPath = ""
        }

        if (root._pendingHistoryDirection === 0) {
            return false
        }
        root._historyPaths = root._historyPaths.filter((_, i) => i !== root._historyIndex)
        if (root._pendingHistoryDirection > 0) {
            root._historyIndex -= 1
        }
        root._historyIndex = Math.max(-1, Math.min(root._historyIndex, root._historyPaths.length - 1))
        let direction = root._pendingHistoryDirection
        root._pendingHistoryDirection = 0
        if (direction < 0) {
            root.navigateBack()
        }
        else {
            root.navigateForward()
        }
        return true
    }

    function navigateBack() {
        if (root._historyIndex <= 0) {
            return
        }
        root._historyIndex -= 1
        root._pendingHistoryDirection = -1
        root.navigateToDirectory(root._historyPaths[root._historyIndex])
    }

    function navigateForward() {
        if (root._historyIndex >= root._historyPaths.length - 1) {
            return
        }
        root._historyIndex += 1
        root._pendingHistoryDirection = 1
        root.navigateToDirectory(root._historyPaths[root._historyIndex])
    }

    function navigateToDirectory(dirPath) {
        let normalizedPath = root._normalizeDirectoryPath(dirPath)
        root._pendingFileListPath = normalizedPath
        root._expandDirsToPath = normalizedPath
        let isCached = root._cache[root.directoryTreeRootPath] !== undefined
        root.directoryExpanded(root.directoryTreeRootPath, isCached)
    }
}

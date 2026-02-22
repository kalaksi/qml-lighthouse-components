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
    /// Hide directories in the file list.
    property bool hideDirectories: false
    /// When set, used as directory icon in tree views. When empty, a generic folder symbol is shown.
    property string directoryIconSource: ""
    /// Paths to show with reduced opacity (e.g. rows marked for move).
    property var dimmedPaths: []

    readonly property string selectedDirectory: dirTreeView && dirTreeView.selectedPaths.length > 0 ?
        dirTreeView.selectedPaths[0] : ""

    readonly property var selectedFiles: fileListView && fileListView.selectedPaths.length > 0 ?
        fileListView.selectedPaths : []

    readonly property var selectedFilesOnly: root.selectedFiles ?
        root.selectedFiles.filter(path => !path.endsWith(root.directorySeparator)) : []

    readonly property bool hasSingleSelection: (root.useSplitView && fileListView.selectedPaths.length === 1) ||
        (!root.useSplitView && treeView.selectedPaths.length === 1)

    property int _maxColumns: 8
    property var _cache: ({})
    property var _expandedDirs: ({})
    property string _expandDirsToPath: ""

    signal directoryExpanded(string path, bool isCached)
    signal renamed(string fullPath, string newName)

    onColumnHeadersChanged: {
        if (root.columnHeaders.length > root._maxColumns) {
            console.error("FileBrowser: too many columns, maximum allowed is " + root._maxColumns + ".")
            root.columnHeaders = root.columnHeaders.slice(0, root._maxColumns)
        }
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

        Column {
            SplitView.preferredWidth: parent.width * 0.25
            SplitView.minimumWidth: 100

            Item {
                width: parent.width
                height: root.rowHeight
            }

            FileBrowserTreeView {
                id: dirTreeView
                rootPath: root.directoryTreeRootPath
                directorySeparator: root.directorySeparator
                width: parent.width
                height: parent.height - root.rowHeight
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

                columnWidthProvider: function(column, totalWidth) {
                    return column === 0 ? totalWidth : 0
                }

                onDirectoryExpanded: function(path, isCached) {
                    root.directoryExpanded(path, isCached)
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

                onDirectoryExpanded: function(path, isCached) {
                    root.directoryExpanded(path, isCached)
                }

                onDirectoryActivated: function(path) {
                    let isCached = root._cache[path] !== undefined
                    root.directoryExpanded(path, isCached)
                    dirTreeView.selectPath(path)
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

    /// Opens at the given path; initiates listing requests and expands the dir tree segment by segment.
    function openInitialDirectory(dirPath) {
        let normalizedPath = root._normalizeDirectoryPath(dirPath)

        if (normalizedPath !== root.directoryTreeRootPath) {
            // Expands the directory tree segment by segment until the path is reached.
            root._expandDirsToPath = normalizedPath
        }

        root.directoryExpanded(root.directoryTreeRootPath, false)
    }

    function openDirectory(dirPath, fileEntries) {
        let normalizedPath = root._normalizeDirectoryPath(dirPath)

        if (normalizedPath in root._expandedDirs
            && root._expandedDirs[normalizedPath] === true
            && (fileEntries === undefined || fileEntries === null)) {

            // Already expanded with content, do nothing.
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
                fileListView.refreshView()
            }
            else {
                treeView.refreshView()
            }
        }
        else {
            if (root.useSplitView) {
                dirTreeView.insertDirectoryContent(normalizedPath, cachedEntries)
                // Prevents unnecessary navigation to intermediate directories.
                let atTarget = root._expandDirsToPath !== "" && normalizedPath === root._expandDirsToPath
                if (atTarget) {
                    fileListView.rootPath = normalizedPath
                }
                fileListView.refreshView()
            }
            else {
                treeView.insertDirectoryContent(normalizedPath, cachedEntries)
                treeView.rootPath = normalizedPath
            }
        }

        // Handle expansion of the directory tree to the given path if opening directory from deeper level.
        if (root._expandDirsToPath !== "") {
            if (!root.useSplitView) {
                root._expandDirsToPath = ""
                return
            }

            if (normalizedPath === root._expandDirsToPath) {
                dirTreeView.selectPath(normalizedPath)
                root._expandDirsToPath = ""
                return
            }

            let remainingPath = root._expandDirsToPath.substring(normalizedPath.length)
            let remainingSegments = root._getPathComponents(remainingPath)
            if (remainingSegments.length > 0) {
                let nextPath = normalizedPath + remainingSegments[0]
                root.directoryExpanded(nextPath, false)
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
}

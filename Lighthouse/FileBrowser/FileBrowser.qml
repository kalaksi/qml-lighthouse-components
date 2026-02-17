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
    readonly property string selectedDirectory: dirTreeView && dirTreeView.selectedPaths.length > 0 ?
        dirTreeView.selectedPaths[0] : "/"
    readonly property var selectedFiles: fileListView && fileListView.selectedPaths.length > 0 ?
        fileListView.selectedPaths : []
    readonly property bool hasSingleSelection: (root.useSplitView && fileListView.selectedPaths.length === 1) ||
        (!root.useSplitView && treeView.selectedPaths.length === 1)

    property int _maxColumns: 8
    property string _fileListRootPath: ""
    property var _cache: ({})
    property var _expandedDirs: ({})

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
            width: parent.width
            height: parent.height - header.height
            indentWidth: root.indentWidth
            rowHeight: root.rowHeight
            arrowWidth: root.arrowWidth
            contextMenu: root.contextMenu
            directoryIconSource: root.directoryIconSource
            sortColumnIndex: root.sortColumnIndex
            sortAscending: root.sortAscending
            rootPath: "/"
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
                Qt.callLater(function() {
                    let tw = treeView.tableView.width
                    for (let c = 0; c < 1 + root._maxColumns; c++) {
                        treeView.tableView.setColumnWidth(c, root._getColumnWidth(c, tw))
                    }
                })
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
                width: parent.width
                height: parent.height - root.rowHeight
                indentWidth: root.indentWidth
                rowHeight: root.rowHeight
                arrowWidth: root.arrowWidth
                directoryIconSource: root.directoryIconSource
                rootPath: "/"
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
                _maxColumns: root._maxColumns
                sortColumnIndex: root.sortColumnIndex
                sortAscending: root.sortAscending

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
                width: parent.width
                height: parent.height - fileHeader.height
                indentWidth: root.indentWidth
                rowHeight: root.rowHeight
                arrowWidth: root.arrowWidth
                contextMenu: root.contextMenu
                directoryIconSource: root.directoryIconSource
                _cache: root._cache
                _maxColumns: root._maxColumns
                sortColumnIndex: root.sortColumnIndex
                sortAscending: root.sortAscending
                rootPath: root.selectedDirectory
                hideDirectories: root.hideDirectories
                enableDirectoryNavigation: false

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

    function openDirectory(dirPath, fileEntries) {
        let normalizedPath = root._normalizeDirectoryPath(dirPath)

        if (normalizedPath in root._expandedDirs
            && root._expandedDirs[normalizedPath] === true
            && (fileEntries === undefined || fileEntries === null)) {

            // Already expanded with content, do nothing.
            return
        }

        let wasCached = normalizedPath in root._cache

        root._expandedDirs[normalizedPath] = true

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
                fileListView.refreshView()
            }
            else {
                treeView.insertDirectoryContent(normalizedPath, cachedEntries)
                treeView.rootPath = normalizedPath
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

    function buildEntry(directory, name, fileType, columnData) {
        if (columnData.length !== root.columnHeaders.length) {
            console.error("Column data length does not match column headers length")
            return null
        }
        if (root.columnHeaders.length > root._maxColumns) {
            console.error("FileBrowser: too many columns, maximum allowed is " + root._maxColumns + ".")
            return null
        }

        let fullPath = directory === "/" ? "/" + name : directory + name
        let fullPathStr = String(fullPath)
        if (fileType === "d" && !fullPathStr.endsWith("/")) {
            fullPath = fullPathStr + "/"
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

    function _normalizeDirectoryPath(path) {
        let pathStr = String(path)
        if (!pathStr.endsWith("/") && pathStr !== "/") {
            path = pathStr + "/"
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
}

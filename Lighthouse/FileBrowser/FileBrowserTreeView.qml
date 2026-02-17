/*
 * SPDX-FileCopyrightText: Copyright (C) 2025 kalaksi@users.noreply.github.com
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import Qt.labs.qmlmodels
import QtQml.Models

Item {
    id: root

    property var columnWidthProvider: null

    property int indentWidth: 20
    property int rowHeight: 28
    property int arrowWidth: 20
    property string rootPath: "/"
    property bool hideFiles: false
    property bool hideDirectories: false
    property bool enableDirectoryNavigation: false
    /// When set, used as Image source for directory rows. When empty, a generic folder symbol is shown.
    property string directoryIconSource: ""
    /// Meant for read-only access.
    property var selectedPaths: []
    property bool singleSelection: false

    property var _cache: ({})
    property var _expandedDirs: ({})
    property int _maxColumns: 8
    property int sortColumnIndex: 0
    property bool sortAscending: true
    // For multi-selection.
    property int _anchorRow: -1

    signal directoryExpanded(string path, bool is_cached)
    signal directoryActivated(string path)
    signal selectionChanged(var paths)
    signal renamed(string fullPath, string newName)

    property alias tableView: tableView
    property Menu contextMenu: null

    onRootPathChanged: refreshView()
    onHideDirectoriesChanged: refreshView()
    onHideFilesChanged: refreshView()
    onSortColumnIndexChanged: refreshView()
    onSortAscendingChanged: refreshView()

    TableView {
        id: tableView
        anchors.fill: parent
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        onWidthChanged: forceLayout()
        columnWidthProvider: root.columnWidthProvider
            ? (column) => root.columnWidthProvider(column, tableView.width)
            : undefined
        rowHeightProvider: function(row) {
            return root.rowHeight
        }
        selectionBehavior: TableView.SelectRows
        selectionMode: root.singleSelection ? TableView.SingleSelection : TableView.ExtendedSelection
        editTriggers: TableView.NoEditTriggers

        model: TableModel {
            id: tableModel

            TableModelColumn { display: "name" }
            TableModelColumn { display: "column-0" }
            TableModelColumn { display: "column-1" }
            TableModelColumn { display: "column-2" }
            TableModelColumn { display: "column-3" }
            TableModelColumn { display: "column-4" }
            TableModelColumn { display: "column-5" }
            TableModelColumn { display: "column-6" }
            TableModelColumn { display: "column-7" }
        }

        selectionModel: ItemSelectionModel {
            onSelectionChanged: {
                root.selectedPaths = root.getSelectedPaths()
                if (root.enableDirectoryNavigation
                    && root.selectedPaths.length === 1
                    && root.selectedPaths[0].endsWith("/")) {

                    let isCached = root._cache[root.selectedPaths[0]] !== undefined
                    root.directoryExpanded(root.selectedPaths[0], isCached)
                }
                root.selectionChanged(root.selectedPaths)
            }
        }

        ScrollBar.vertical: ScrollBar {
            active: true
        }

        delegate: TableViewDelegate {
            id: viewDelegate

            property string fullPath: {
                if (viewDelegate.row >= 0 && viewDelegate.row < tableModel.rowCount && tableModel.rows) {
                    let rowData = tableModel.rows[viewDelegate.row]
                    return rowData && rowData.fullPath ? String(rowData.fullPath) : ""
                }
                return ""
            }
            
            property string name: {
                if (viewDelegate.row >= 0 && viewDelegate.row < tableModel.rowCount && tableModel.rows) {
                    let rowData = tableModel.rows[viewDelegate.row]
                    return rowData && rowData.name ? String(rowData.name) : ""
                }
                return ""
            }
            property string fileType: {
                if (viewDelegate.row >= 0 && viewDelegate.row < tableModel.rowCount && tableModel.rows) {
                    let rowData = tableModel.rows[viewDelegate.row]
                    return rowData && rowData.fileType ? String(rowData.fileType) : ""
                }
                return ""
            }
            property string columnValue: {
                if (viewDelegate.column <= 0 || viewDelegate.row < 0 || viewDelegate.row >= tableModel.rowCount ||
                    !tableModel.rows) {
                    return ""
                }
                let rowData = tableModel.rows[viewDelegate.row]
                let key = "column-" + (viewDelegate.column - 1)
                return rowData && rowData[key] !== undefined ? String(rowData[key]) : ""
            }

            // To override default background that sometimes leaves a extraneous border after unselecting.
            background: Rectangle {
                color: viewDelegate.selected ? viewDelegate.palette.highlight
                    : (viewDelegate.row % 2 === 0 ? viewDelegate.palette.base
                                                   : viewDelegate.palette.alternateBase)
                border.width: 0
            }

            contentItem: Item {
                anchors.fill: parent

                // TableView doesn't seem to update ItemSelectionModel properly with custom delegate,
                // so have to implement selection manually.
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: function(mouse) {
                        if (mouse.button === Qt.RightButton) {
                            if (root.contextMenu) root.contextMenu.popup()
                            return
                        }
                        let rowIndex = tableView.model.index(viewDelegate.row, 0)
                        if (root.singleSelection) {
                            tableView.selectionModel.select(
                                rowIndex,
                                ItemSelectionModel.ClearAndSelect | ItemSelectionModel.Current |
                                    ItemSelectionModel.Rows
                            )
                        }
                        else {
                            if (mouse.modifiers & Qt.ShiftModifier) {
                                let anchor = root._anchorRow >= 0 ? root._anchorRow : viewDelegate.row
                                let top = Math.min(anchor, viewDelegate.row)
                                let bottom = Math.max(anchor, viewDelegate.row)
                                tableView.selectionModel.clearSelection()
                                for (let r = top; r <= bottom; r++) {
                                    tableView.selectionModel.select(
                                        tableView.model.index(r, 0),
                                        ItemSelectionModel.Select | ItemSelectionModel.Rows
                                    )
                                }
                                tableView.selectionModel.setCurrentIndex(
                                    rowIndex, ItemSelectionModel.Current
                                )
                            }
                            else if (mouse.modifiers & Qt.ControlModifier) {
                                tableView.selectionModel.select(
                                    rowIndex,
                                    ItemSelectionModel.Toggle | ItemSelectionModel.Rows
                                )
                                tableView.selectionModel.setCurrentIndex(
                                    rowIndex, ItemSelectionModel.Current
                                )
                                root._anchorRow = viewDelegate.row
                            }
                            else {
                                if (viewDelegate.selected && tableView.selectionModel.selectedRows(0).length === 1) {
                                    tableView.selectionModel.clearSelection()
                                }
                                else {
                                    tableView.selectionModel.select(
                                        rowIndex,
                                        ItemSelectionModel.ClearAndSelect | ItemSelectionModel.Current |
                                            ItemSelectionModel.Rows
                                    )
                                    root._anchorRow = viewDelegate.row
                                }
                            }
                        }
                    }
                    onDoubleClicked: function(mouse) {
                        if (mouse.button === Qt.LeftButton && !root.enableDirectoryNavigation
                            && viewDelegate.fileType === "d") {
                            root.directoryActivated(viewDelegate.fullPath)
                        }
                    }
                }

                Row {
                    id: nameColumn
                    visible: viewDelegate.column === 0
                    height: parent.height
                    anchors.left: parent.left
                    anchors.right: parent.right
                    spacing: 4

                    Item {
                        id: arrowIndentArea
                        property int depth: root.enableDirectoryNavigation ? (viewDelegate.fullPath.split("/").length - 1) : 0

                        width: root.arrowWidth + (arrowIndentArea.depth * root.indentWidth)
                        height: parent.height

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: (arrowIndentArea.depth * root.indentWidth)
                            anchors.verticalCenter: parent.verticalCenter
                            width: root.arrowWidth
                            visible: viewDelegate.fileType === "d" && root.enableDirectoryNavigation
                            text: root._expandedDirs[viewDelegate.fullPath] === true ? "▼" : "▶"
                            color: viewDelegate.selected ? viewDelegate.palette.highlightedText : viewDelegate.palette.buttonText
                            verticalAlignment: Text.AlignVCenter

                            MouseArea {
                                anchors.fill: parent
                                propagateComposedEvents: false
                                onClicked: root.toggleDirectory(viewDelegate.fullPath)
                            }
                        }
                    }


                    Button {
                        id: directoryIconButton
                        anchors.verticalCenter: parent.verticalCenter
                        visible: viewDelegate.fileType === "d"
                        width: 22
                        height: 22
                        flat: true
                        display: AbstractButton.IconOnly
                        icon.source: root.directoryIconSource
                        icon.name: root.directoryIconSource === "" ? "folder" : ""
                        icon.width: 22
                        icon.height: 22
                    }

                    Label {
                        width: parent.width - arrowIndentArea.width - directoryIconButton.width - parent.spacing
                        height: parent.height
                        text: viewDelegate.name
                        elide: Text.ElideRight
                        color: viewDelegate.selected ? viewDelegate.palette.highlightedText : viewDelegate.palette.buttonText
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                Label {
                    visible: viewDelegate.column > 0
                    anchors.fill: parent
                    text: viewDelegate.columnValue
                    elide: Text.ElideRight
                    color: viewDelegate.selected ? viewDelegate.palette.highlightedText : viewDelegate.palette.buttonText
                }
            }

            TableView.editDelegate: TextField {
                anchors.fill: parent
                text: viewDelegate.name
                color: palette.text
                verticalAlignment: Text.AlignVCenter

                Component.onCompleted: selectAll()

                TableView.onCommit: {
                    let newName = text.trim()
                    if (newName.length > 0 && newName.indexOf("/") === -1) {
                        root.renamed(root.getPathAtRow(viewDelegate.row), newName)
                    }
                    TableView.view.closeEditor()
                }

                Keys.onEscapePressed: TableView.view.closeEditor()

                onActiveFocusChanged: {
                    if (!activeFocus) {
                        TableView.view.closeEditor()
                    }
                }
            }
        }
    }

    function startRename() {
        let selected = tableView.selectionModel.selectedRows(0)
        if (selected.length === 1) {
            let row = selected[0].row
            tableView.selectionModel.setCurrentIndex(
                tableView.model.index(row, 0), ItemSelectionModel.Current)
            tableView.edit(tableView.index(row, 0))
        }
    }

    function refreshView() {
        tableView.closeEditor()
        tableView.selectionModel.clearSelection()
        root._anchorRow = -1
        tableModel.rows = root._buildFlatList(root.rootPath)
    }

    function getSelectedPaths() {
        return tableView.selectionModel
            .selectedRows(0)
            .map(row => root.getPathAtRow(row.row))
    }

    function toggleDirectory(normalizedPath) {
        let isCurrentlyExpanded = root._expandedDirs[normalizedPath] === true
        let isCached = root._cache[normalizedPath] !== undefined

        if (isCurrentlyExpanded) {
            root._expandedDirs[normalizedPath] = false
        }
        else {
            root._expandedDirs[normalizedPath] = true
            root.directoryExpanded(normalizedPath, isCached)
        }

        if (isCached) {
            root.refreshView()
        }
    }

    function getPathAtRow(row) {
        // If row is invalid, intentionally fail hard instead of returning empty string.
        return tableModel.rows[row].fullPath;
    }

    function selectPath(normalizedPath) {
        for (let r = 0; r < tableModel.rowCount; r++) {
            if (root.getPathAtRow(r) === normalizedPath) {
                tableView.selectionModel.select(
                    tableView.model.index(r, 0),
                    ItemSelectionModel.ClearAndSelect | ItemSelectionModel.Current | ItemSelectionModel.Rows
                )
                return
            }
        }
    }

    /// Inserts new directory contents to the table without re-rendering the entire table.
    /// This way selection is also preserved.
    function insertDirectoryContent(dirPath, fileEntries) {
        let rowIndex = -1

        if (dirPath === root.rootPath) {
            rowIndex = 0
        }
        else {
            let normalizedPath = root._normalizeDirectoryPath(dirPath)
            for (let r = 0; r < tableModel.rowCount; r++) {
                if (root.getPathAtRow(r) === normalizedPath) {
                    rowIndex = r + 1
                    break
                }
            }
        }

        if (rowIndex < 0) {
            console.error(`Row index not found for path ${dirPath}`)
            return
        }

        let sortedEntries = root._sortEntries(fileEntries)
        for (let i = 0; i < sortedEntries.length; i++) {
            let entry = sortedEntries[i]

            if (root.hideFiles && entry.fileType !== "d") {
                continue
            }
            if (root.hideDirectories && entry.fileType === "d") {
                continue
            }

            tableModel.insertRow(rowIndex + i, entry)
        }
    }

    function _sortEntries(entries) {
        let key = root.sortColumnIndex === 0 ? "name" : "column-" + (root.sortColumnIndex - 1)
        return [...entries].sort(function(a, b) {
            if (a.fileType === "d" && b.fileType !== "d") {
                return -1
            }
            else if (a.fileType !== "d" && b.fileType === "d") {
                return 1
            }
            let aVal = a[key] !== undefined ? String(a[key]) : ""
            let bVal = b[key] !== undefined ? String(b[key]) : ""
            return root.sortAscending ? aVal.localeCompare(bVal) : bVal.localeCompare(aVal)
        })
    }

    function _buildFlatList(normalizedDirPath, depth = 0) {
        let result = []
        let entries = root._cache[normalizedDirPath]
        if (!entries) {
            return result
        }
        let sortedEntries = root._sortEntries(entries)

        for (let entry of sortedEntries) {
            if (root.hideFiles && entry.fileType !== "d") {
                continue
            }
            if (root.hideDirectories && entry.fileType === "d") {
                continue
            }

            result.push(entry)

            let isExpanded = root._expandedDirs[entry.fullPath] === true
            if (entry.fileType === "d" && isExpanded) {
                let children = root._buildFlatList(entry.fullPath, depth + 1)
                result.push(...children)
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
}


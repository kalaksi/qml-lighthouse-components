/*
 * SPDX-FileCopyrightText: Copyright (C) 2025 kalaksi@users.noreply.github.com
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls

Item {
    id: root
    height: headerView.height

    required property var syncView
    property var columnHeaders: ["Column 1", "Column 2"]
    property int rowHeight: 28
    property color headerColor: "transparent"
    property color headerBorderColor: palette.mid
    property int _maxColumns: 8
    property int sortColumnIndex: -1
    property bool sortAscending: true
    property var _headerModel: root._buildHeaderModel()

    signal headerClicked(int columnIndex)

    HorizontalHeaderView {
        id: headerView
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: root.rowHeight
        syncView: root.syncView
        model: root._headerModel
        movableColumns: false
        interactive: false
        rowHeightProvider: function(row) { return root.rowHeight }
        delegate: Rectangle {
            id: cellRoot
            required property int row
            color: root.headerColor

            Rectangle {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 1
                color: root.headerBorderColor
            }

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 1
                color: root.headerBorderColor
            }

            Rectangle {
                anchors.fill: parent
                color: palette.highlight
                opacity: hoverArea.containsMouse ? 0.15 : 0
            }

            Row {
                anchors.fill: parent
                anchors.leftMargin: 6
                anchors.rightMargin: 1
                spacing: 4

                Label {
                    width: parent.width - (sortIndicator.visible ? sortIndicator.width + parent.spacing : 0)
                    height: parent.height
                    text: (cellRoot.row >= 0 && cellRoot.row < root._headerModel.length
                        && root._headerModel[cellRoot.row].display !== undefined)
                        ? root._headerModel[cellRoot.row].display
                        : ""
                    color: palette.buttonText
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }

                Label {
                    id: sortIndicator
                    visible: root.sortColumnIndex === cellRoot.row
                    height: parent.height
                    text: root.sortAscending ? "▲" : "▼"
                    color: palette.buttonText
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: Math.max(6, root.rowHeight - 10)
                }
            }

            MouseArea {
                id: hoverArea
                anchors.fill: parent
                anchors.leftMargin: 6
                anchors.rightMargin: 2
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton
                onClicked: function(mouse) {
                    if (mouse.button === Qt.LeftButton) {
                        root.headerClicked(cellRoot.row)
                    }
                }
            }
        }
    }

    function _buildHeaderModel() {
        var a = [{ display: "Name" }]
        for (let i = 0; i < columnHeaders.length; i++) {
            a.push({ display: columnHeaders[i] })
        }
        while (a.length < 1 + _maxColumns) {
            a.push({ display: "" })
        }
        return a
    }
}

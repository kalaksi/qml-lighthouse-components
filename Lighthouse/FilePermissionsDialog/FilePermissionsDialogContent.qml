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

    property string contextLabel: ""
    property string contextText: ""
    property string permissions: ""
    property string owner: ""
    property string group: ""

    property int contentMargin: 12
    property int sectionSpacing: 16
    property int rowSpacing: 6
    property int marginTop: 0
    property int marginBottom: 0
    property int comboMinWidth: 180
    property int fontSize: 0

    readonly property bool canAccept: ownerPermCombo.currentIndex >= 0 &&
        groupPermCombo.currentIndex >= 0 &&
        othersPermCombo.currentIndex >= 0

    readonly property string resultOwnerRwx: ownerPermCombo.currentIndex >= 0 ?
        root._permissionOptions[ownerPermCombo.currentIndex].value : undefined
    readonly property string resultGroupRwx: groupPermCombo.currentIndex >= 0 ?
        root._permissionOptions[groupPermCombo.currentIndex].value : undefined
    readonly property string resultOthersRwx: othersPermCombo.currentIndex >= 0 ?
        root._permissionOptions[othersPermCombo.currentIndex].value : undefined
    readonly property string resultOwner: ownerField.text.trim()
    readonly property string resultGroup: groupField.text.trim()

    readonly property var _permissionOptions: [
        { label: "No access", value: "---" },
        { label: "Execute only", value: "--x" },
        { label: "Write only", value: "-w-" },
        { label: "Write & execute", value: "-wx" },
        { label: "Read only", value: "r--" },
        { label: "Read & execute", value: "r-x" },
        { label: "Read & write", value: "rw-" },
        { label: "Read, write & execute", value: "rwx" }
    ]

    readonly property bool _showContext: root.contextLabel.length > 0 || root.contextText.length > 0

    implicitWidth: contentColumn.implicitWidth + root.contentMargin * 2
    implicitHeight: contentColumn.implicitHeight + root.marginTop + root.marginBottom

    onPermissionsChanged: _updateFromProps()
    onOwnerChanged: _updateFromProps()
    onGroupChanged: _updateFromProps()
    Component.onCompleted: _updateFromProps()

    function _updateFromProps() {
        function _tripletAt(str, start) {
            if (start + 2 >= str.length)
                return "---"
            return str.substring(start, start + 3)
        }

        function _indexForTriplet(triplet) {
            for (let i = 0; i < root._permissionOptions.length; i++) {
                if (root._permissionOptions[i].value === triplet)
                    return i
            }
            return 0
        }

        if (root.permissions.length >= 9) {
            let start = root.permissions.length === 10 ? 1 : 0
            ownerPermCombo.currentIndex =
                _indexForTriplet(_tripletAt(root.permissions, start))
            groupPermCombo.currentIndex =
                _indexForTriplet(_tripletAt(root.permissions, start + 3))
            othersPermCombo.currentIndex =
                _indexForTriplet(_tripletAt(root.permissions, start + 6))
            ownerField.text = root.owner
            groupField.text = root.group
        }
        else {
            ownerPermCombo.currentIndex = -1
            groupPermCombo.currentIndex = -1
            othersPermCombo.currentIndex = -1
            ownerField.text = ""
            groupField.text = ""
        }
    }

    ColumnLayout {
        id: contentColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: root.contentMargin
        anchors.rightMargin: root.contentMargin
        anchors.topMargin: root.marginTop
        anchors.bottomMargin: root.marginBottom
        spacing: root.sectionSpacing

        ColumnLayout {
            visible: root._showContext
            spacing: root.rowSpacing

            Layout.fillWidth: true

            Label {
                text: root.contextLabel
                font.bold: true
            }

            Label {
                Layout.fillWidth: true
                text: root.contextText
                wrapMode: Text.Wrap
                elide: Text.ElideMiddle
            }
        }

        Label {
            text: "Permissions"
            font.bold: true
            Layout.topMargin: root._showContext ? root.sectionSpacing : 0
        }

        GridLayout {
            columns: 2
            rowSpacing: root.rowSpacing
            columnSpacing: root.rowSpacing * 3

            Label {
                text: "Owner"
            }
            ComboBox {
                id: ownerPermCombo
                model: root._permissionOptions
                textRole: "label"
                font.pointSize: root.fontSize > 0 ? root.fontSize : undefined
                delegate: ItemDelegate {
                    text: modelData.label
                    font.pointSize: root.fontSize > 0 ? root.fontSize : undefined
                }
                Layout.minimumWidth: root.comboMinWidth
            }

            Label {
                text: "Group"
            }
            ComboBox {
                id: groupPermCombo
                model: root._permissionOptions
                textRole: "label"
                font.pointSize: root.fontSize > 0 ? root.fontSize : undefined
                delegate: ItemDelegate {
                    text: modelData.label
                    font.pointSize: root.fontSize > 0 ? root.fontSize : undefined
                }
                Layout.minimumWidth: root.comboMinWidth
            }

            Label {
                text: "Others"
            }
            ComboBox {
                id: othersPermCombo
                model: root._permissionOptions
                textRole: "label"
                font.pointSize: root.fontSize > 0 ? root.fontSize : undefined
                delegate: ItemDelegate {
                    text: modelData.label
                    font.pointSize: root.fontSize > 0 ? root.fontSize : undefined
                }
                Layout.minimumWidth: root.comboMinWidth
            }
        }

        Label {
            text: "Ownership"
            font.bold: true
            Layout.topMargin: root.sectionSpacing
        }

        GridLayout {
            columns: 2
            rowSpacing: root.rowSpacing
            columnSpacing: root.rowSpacing * 3

            Label {
                text: "Owner"
            }
            TextField {
                id: ownerField
                font.pointSize: root.fontSize > 0 ? root.fontSize : undefined
                Layout.minimumWidth: root.comboMinWidth
            }

            Label {
                text: "Group"
            }
            TextField {
                id: groupField
                font.pointSize: root.fontSize > 0 ? root.fontSize : undefined
                Layout.minimumWidth: root.comboMinWidth
            }
        }
    }
}

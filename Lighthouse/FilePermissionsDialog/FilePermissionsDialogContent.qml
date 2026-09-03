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
    property string warningText: ""
    property color warningTextColor: "#555555"

    property int contentMargin: 12
    property int sectionSpacing: 16
    property int rowSpacing: 6
    property int marginTop: 0
    property int marginBottom: 0
    property int comboMinWidth: 180
    property int fontSize: 0
    property int optionSpacing: 12
    property real optionOctalOpacity: 0.6
    property bool showOctal: true
    property bool showSpecialBits: false
    property int tooltipDelay: 800

    property string _initialMode: ""

    readonly property bool canAccept: ownerPermissionsComboBox.currentIndex >= 0 &&
        groupPermissionsComboBox.currentIndex >= 0 &&
        othersPermissionsComboBox.currentIndex >= 0

    readonly property string resultMode: root.canAccept ? root._modeFromCurrentValues() : ""
    readonly property string resultOwner: ownerField.text.trim()
    readonly property string resultGroup: groupField.text.trim()
    readonly property string changedOwner:
        root.resultOwner.length > 0 && root.resultOwner !== root.owner ? root.resultOwner : ""
    readonly property string changedGroup:
        root.resultGroup.length > 0 && root.resultGroup !== root.group ? root.resultGroup : ""
    readonly property bool hasChanges: root.resultMode !== root._initialMode ||
        root.changedOwner.length > 0 || root.changedGroup.length > 0

    readonly property var _permissionOptions: [
        { octal: "0", label: "No access", value: "---" },
        { octal: "1", label: "Execute only", value: "--x" },
        { octal: "2", label: "Write only", value: "-w-" },
        { octal: "3", label: "Write & execute", value: "-wx" },
        { octal: "4", label: "Read only", value: "r--" },
        { octal: "5", label: "Read & execute", value: "r-x" },
        { octal: "6", label: "Read & write", value: "rw-" },
        { octal: "7", label: "Read, write & execute", value: "rwx" }
    ]

    readonly property bool _showContext: root.contextLabel.length > 0 || root.contextText.length > 0

    implicitWidth: contentColumn.implicitWidth + root.contentMargin * 2
    implicitHeight: contentColumn.implicitHeight + root.marginTop + root.marginBottom

    onPermissionsChanged: _updateFromProps()
    onOwnerChanged: _updateFromProps()
    onGroupChanged: _updateFromProps()
    Component.onCompleted: _updateFromProps()

    function _normalizeTriplet(triplet) {
        if (triplet.length !== 3) {
            return "---"
        }

        let execute = triplet.charAt(2)
        if (execute === "s" || execute === "t") {
            execute = "x"
        }
        else if (execute === "S" || execute === "T") {
            execute = "-"
        }

        return triplet.substring(0, 2) + execute
    }

    function _modeFromCurrentValues() {
        let specialBits = (setuidCheckBox.checked ? 4 : 0) +
            (setgidCheckBox.checked ? 2 : 0) +
            (stickyCheckBox.checked ? 1 : 0)
        return specialBits.toString() +
            root._permissionOptions[ownerPermissionsComboBox.currentIndex].octal +
            root._permissionOptions[groupPermissionsComboBox.currentIndex].octal +
            root._permissionOptions[othersPermissionsComboBox.currentIndex].octal
    }

    function _updateFromProps() {
        function _tripletAt(str, start) {
            if (start + 2 >= str.length) {
                return "---"
            }
            return root._normalizeTriplet(str.substring(start, start + 3))
        }

        function _indexForTriplet(triplet) {
            for (let i = 0; i < root._permissionOptions.length; i++) {
                if (root._permissionOptions[i].value === triplet) {
                    return i
                }
            }
            return 0
        }

        if (root.permissions.length >= 9) {
            // `ls -l` modes contain a leading file-type character and can have a
            // trailing ACL/security-context marker (`+` or `.`).
            let start = root.permissions.length >= 10 ? 1 : 0
            ownerPermissionsComboBox.currentIndex =
                _indexForTriplet(_tripletAt(root.permissions, start))
            groupPermissionsComboBox.currentIndex =
                _indexForTriplet(_tripletAt(root.permissions, start + 3))
            othersPermissionsComboBox.currentIndex =
                _indexForTriplet(_tripletAt(root.permissions, start + 6))
            let ownerExecute = root.permissions.charAt(start + 2)
            let groupExecute = root.permissions.charAt(start + 5)
            let othersExecute = root.permissions.charAt(start + 8)
            setuidCheckBox.checked = ownerExecute === "s" || ownerExecute === "S"
            setgidCheckBox.checked = groupExecute === "s" || groupExecute === "S"
            stickyCheckBox.checked = othersExecute === "t" || othersExecute === "T"
            root._initialMode = root._modeFromCurrentValues()
            ownerField.text = root.owner
            groupField.text = root.group
        }
        else {
            ownerPermissionsComboBox.currentIndex = -1
            groupPermissionsComboBox.currentIndex = -1
            othersPermissionsComboBox.currentIndex = -1
            setuidCheckBox.checked = false
            setgidCheckBox.checked = false
            stickyCheckBox.checked = false
            root._initialMode = ""
            ownerField.text = ""
            groupField.text = ""
        }
    }

    component PermissionOptionDelegate: ItemDelegate {
        id: optionDelegate

        required property var modelData

        width: parent ? parent.width : implicitWidth
        text: modelData.label
        font.pointSize: root.fontSize > 0 ? root.fontSize : undefined

        contentItem: RowLayout {
            spacing: root.optionSpacing

            Label {
                visible: root.showOctal
                text: optionDelegate.modelData.octal
                opacity: root.optionOctalOpacity
                font: optionDelegate.font
                color: optionDelegate.highlighted ?
                    optionDelegate.palette.highlightedText : optionDelegate.palette.text
            }

            Label {
                Layout.fillWidth: true
                text: optionDelegate.modelData.label
                font: optionDelegate.font
                color: optionDelegate.highlighted ?
                    optionDelegate.palette.highlightedText : optionDelegate.palette.text
            }
        }
    }

    ColumnLayout {
        id: contentColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
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
                id: contextTextLabel

                Layout.preferredWidth: Math.max(permissionsGrid.implicitWidth, ownershipGrid.implicitWidth)
                Layout.maximumWidth: Layout.preferredWidth
                text: root.contextText
                wrapMode: Text.NoWrap
                elide: Text.ElideMiddle

                ToolTip.visible: contextHoverArea.containsMouse && contextTextLabel.truncated
                ToolTip.delay: root.tooltipDelay
                ToolTip.text: root.contextText

                MouseArea {
                    id: contextHoverArea
                    anchors.fill: parent
                    acceptedButtons: Qt.NoButton
                    hoverEnabled: true
                }
            }
        }

        Label {
            text: "Permissions"
            font.bold: true
            Layout.topMargin: root._showContext ? root.sectionSpacing : 0
        }

        GridLayout {
            id: permissionsGrid
            columns: 2
            rowSpacing: root.rowSpacing
            columnSpacing: root.rowSpacing * 3

            Label {
                text: "Owner"
            }
            ComboBox {
                id: ownerPermissionsComboBox
                model: root._permissionOptions
                textRole: "label"
                displayText: currentIndex >= 0 ?
                    (root.showOctal ? model[currentIndex].octal + "  " : "") +
                        model[currentIndex].label : ""
                font.pointSize: root.fontSize > 0 ? root.fontSize : undefined
                delegate: PermissionOptionDelegate {}
                Layout.minimumWidth: root.comboMinWidth
            }

            Label {
                text: "Group"
            }
            ComboBox {
                id: groupPermissionsComboBox
                model: root._permissionOptions
                textRole: "label"
                displayText: currentIndex >= 0 ?
                    (root.showOctal ? model[currentIndex].octal + "  " : "") +
                        model[currentIndex].label : ""
                font.pointSize: root.fontSize > 0 ? root.fontSize : undefined
                delegate: PermissionOptionDelegate {}
                Layout.minimumWidth: root.comboMinWidth
            }

            Label {
                text: "Others"
            }
            ComboBox {
                id: othersPermissionsComboBox
                model: root._permissionOptions
                textRole: "label"
                displayText: currentIndex >= 0 ?
                    (root.showOctal ? model[currentIndex].octal + "  " : "") +
                        model[currentIndex].label : ""
                font.pointSize: root.fontSize > 0 ? root.fontSize : undefined
                delegate: PermissionOptionDelegate {}
                Layout.minimumWidth: root.comboMinWidth
            }

            Item {
                visible: root.showSpecialBits
            }

            RowLayout {
                visible: root.showSpecialBits
                spacing: root.optionSpacing

                CheckBox {
                    id: setuidCheckBox
                    text: "Setuid"
                }

                CheckBox {
                    id: setgidCheckBox
                    text: "Setgid"
                }

                CheckBox {
                    id: stickyCheckBox
                    text: "Sticky"
                }
            }
        }

        Label {
            text: "Ownership"
            font.bold: true
            Layout.topMargin: root.sectionSpacing
        }

        GridLayout {
            id: ownershipGrid
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

        Item {
            visible: root.warningText.length > 0
            Layout.fillHeight: true
            Layout.minimumHeight: root.sectionSpacing * 2
        }

        Label {
            visible: root.warningText.length > 0
            Layout.preferredWidth: Math.max(permissionsGrid.implicitWidth, ownershipGrid.implicitWidth)
            Layout.maximumWidth: Layout.preferredWidth
            text: root.warningText
            color: root.warningTextColor
            wrapMode: Text.Wrap
        }
    }
}

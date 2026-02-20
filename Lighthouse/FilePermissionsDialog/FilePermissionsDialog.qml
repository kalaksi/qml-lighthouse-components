/*
 * SPDX-FileCopyrightText: Copyright (C) 2025 kalaksi@users.noreply.github.com
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls

Dialog {
    id: root

    property alias contextLabel: permissionsContent.contextLabel
    property alias contextText: permissionsContent.contextText
    property alias permissions: permissionsContent.permissions
    property alias owner: permissionsContent.owner
    property alias group: permissionsContent.group
    property alias contentMargin: permissionsContent.contentMargin
    property alias sectionSpacing: permissionsContent.sectionSpacing
    property alias rowSpacing: permissionsContent.rowSpacing
    property alias marginTop: permissionsContent.marginTop
    property alias marginBottom: permissionsContent.marginBottom
    property alias comboMinWidth: permissionsContent.comboMinWidth
    property alias fontSize: permissionsContent.fontSize

    signal applied(string ownerRwx, string groupRwx, string othersRwx, string newOwner, string newGroup)

    title: "Permissions and ownership"
    modal: true
    implicitWidth: permissionsContent.implicitWidth
    implicitHeight: permissionsContent.implicitHeight
    standardButtons: Dialog.Ok | Dialog.Cancel

    onOpened: {
        permissionsContent._updateFromProps()
        root.standardButton(Dialog.Ok).enabled = permissionsContent.canAccept
    }

    Connections {
        target: permissionsContent
        function onCanAcceptChanged() {
            root.standardButton(Dialog.Ok).enabled = permissionsContent.canAccept
            _updateOkButton()
        }
    }

    contentItem: FilePermissionsDialogContent {
        id: permissionsContent
    }

    onAccepted: {
        if (permissionsContent.canAccept)
            root.applied(
                permissionsContent.resultOwnerRwx,
                permissionsContent.resultGroupRwx,
                permissionsContent.resultOthersRwx,
                permissionsContent.resultOwner,
                permissionsContent.resultGroup
            )
    }
}

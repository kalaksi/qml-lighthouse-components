/*
 * SPDX-FileCopyrightText: Copyright (C) 2026 kalaksi@users.noreply.github.com
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

pragma ComponentBehavior: Bound
import QtQuick


/// Shell that defers heavy content creation and destruction.
Item {
    id: root

    /// When true, deferred content is created (if not yet loaded) and contentActivated is
    /// emitted. When false, contentDeactivated is emitted. Loaded content stays mounted
    /// regardless of active.
    property bool active: false

    /// Delay before constructing content so the shell can paint first (milliseconds).
    property int createDelay: 16

    /// Delay before destroying discarded content (milliseconds).
    property int destroyDelay: 100

    /// Optional loading indicator shown while content is being created. Null by default.
    property Component loadingIndicator: null

    /// Must be `function(Item shell)`. Creates content parented to this item.
    property var contentFactory: null

    readonly property bool loaded: root._content !== null
    readonly property Item content: root._content

    property Item _content: null
    property bool _discarded: false

    signal contentLoaded()
    signal contentActivated(Item content)
    signal contentDeactivated(Item content)
    signal contentClosing(Item content)

    onActiveChanged: root._handleActiveChanged()

    Loader {
        anchors.centerIn: parent
        active: root.loadingIndicator !== null && !root.loaded && createTimer.running
        sourceComponent: root.loadingIndicator
    }

    Timer {
        id: createTimer
        interval: root.createDelay
        repeat: false
        onTriggered: root._performLoad()
    }

    Timer {
        id: closeTimer
        interval: root.destroyDelay
        repeat: false
        onTriggered: {
            if (root.content !== null) {
                root.contentClosing(root.content)
            }
            root.destroy(root.destroyDelay)
        }
    }

    /// Set content immediately (eager load).
    function setContent(item) {
        if (root._discarded || item === null || item === undefined) {
            return
        }
        root._cancelPendingLoad()
        root._content = item
        root._adoptContent(item)
        if (root.active) {
            root.contentActivated(root._content)
        }
        root.contentLoaded()
    }

    function _scheduleLoad() {
        if (root._discarded || root.loaded || root.contentFactory === null) {
            return
        }
        createTimer.restart()
    }

    function _cancelPendingLoad() {
        createTimer.stop()
    }

    /// Detach from the layout immediately and destroy content asynchronously.
    function discard() {
        if (root._discarded) {
            return
        }
        root._discarded = true
        root._cancelPendingLoad()
        if (root.loaded) {
            root.contentDeactivated(root._content)
        }
        root.visible = false
        root.parent = null
        closeTimer.start()
    }

    function _handleActiveChanged() {
        if (root._discarded) {
            return
        }
        if (root.active) {
            if (!root.loaded && root.contentFactory !== null) {
                root._scheduleLoad()
            }
            else if (root.loaded) {
                root.contentActivated(root._content)
            }
        }
        else if (root.loaded) {
            root.contentDeactivated(root._content)
        }
    }

    function _performLoad() {
        if (root._discarded || !root.active || root.loaded || root.contentFactory === null) {
            return
        }
        const item = root.contentFactory(root)
        if (item === null || item === undefined || root._discarded || root.loaded) {
            return
        }
        root._content = item
        root._adoptContent(item)
        if (root.active) {
            root.contentActivated(root._content)
        }
        root.contentLoaded()
    }

    function _adoptContent(item) {
        if (item.parent !== root) {
            item.parent = root
        }
        if (item.anchors !== undefined) {
            item.anchors.fill = root
        }
    }
}

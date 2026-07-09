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
    property int _loadGeneration: 0
    property bool _discarded: false
    property bool _loadScheduled: false
    property var _destroyQueue: []

    signal contentLoaded()
    signal contentActivated(Item content)
    signal contentDeactivated(Item content)
    signal contentClosing(Item content)

    onActiveChanged: root._handleActiveChanged()

    Loader {
        anchors.centerIn: parent
        active: root.loadingIndicator !== null && !root.loaded && root._loadScheduled
        sourceComponent: root.loadingIndicator
    }

    Timer {
        id: createTimer
        interval: root.createDelay
        repeat: false
        onTriggered: {
            const generation = root._loadGeneration
            root._performLoad(generation)
        }
    }

    Item {
        id: destroyGraveyard
        visible: false
    }

    Timer {
        id: destroyTimer
        interval: root.destroyDelay
        repeat: true
        onTriggered: {
            if (root._destroyQueue.length === 0) {
                stop()
                return
            }

            const entry = root._destroyQueue.shift()
            if (entry === null || entry === undefined) {
                return
            }

            if (entry.phase === "close") {
                if (entry.content !== null) {
                    root.contentClosing(entry.content)
                }

                entry.phase = "destroy"
                root._destroyQueue.push(entry)
                return
            }

            if (entry.shell !== null && entry.shell !== undefined) {
                entry.shell.destroy()
            }

            if (destroyGraveyard.parent !== null && destroyGraveyard.children.length === 0) {
                destroyGraveyard.destroy()
            }
        }
    }

    /// Set content immediately (eager load).
    function setContent(item) {
        if (root._discarded || item === null || item === undefined) {
            return
        }
        root.cancelPendingLoad()
        root._content = item
        root._adoptContent(item)
        root._loadScheduled = false
        if (root.active) {
            root.contentActivated(root._content)
        }
        root.contentLoaded()
    }

    /// Schedule deferred content creation.
    function scheduleLoad() {
        if (root._discarded || root.loaded || root.contentFactory === null) {
            return
        }
        root._loadScheduled = true
        root._loadGeneration++
        createTimer.restart()
    }

    /// Create content immediately if active and not yet loaded.
    function load() {
        if (root._discarded || root.loaded || root.contentFactory === null || !root.active) {
            return
        }
        root.cancelPendingLoad()
        const generation = ++root._loadGeneration
        root._performLoad(generation)
    }

    function cancelPendingLoad() {
        root._loadScheduled = false
        createTimer.stop()
        root._loadGeneration++
    }

    /// Detach from the layout immediately and destroy content asynchronously.
    function discard() {
        if (root._discarded) {
            return
        }
        root._discarded = true
        root.cancelPendingLoad()
        if (root.loaded) {
            root.contentDeactivated(root._content)
        }
        root.visible = false
        const layoutParent = root.parent
        if (layoutParent !== null) {
            destroyGraveyard.parent = layoutParent
            root.parent = destroyGraveyard
        }
        root._destroyQueue.push({
            "phase": "close",
            "content": root._content,
            "shell": root,
        })
        destroyTimer.start()
    }

    function _handleActiveChanged() {
        if (root._discarded) {
            return
        }
        if (root.active) {
            if (!root.loaded && root.contentFactory !== null) {
                root.scheduleLoad()
            }
            else if (root.loaded) {
                root.contentActivated(root._content)
            }
        }
        else if (root.loaded) {
            root.contentDeactivated(root._content)
        }
    }

    function _performLoad(generation) {
        if (root._discarded || generation !== root._loadGeneration || !root.active || root.loaded) {
            return
        }
        const item = root.contentFactory(root)
        if (item === null || item === undefined || generation !== root._loadGeneration) {
            return
        }
        root._content = item
        root._adoptContent(item)
        root._loadScheduled = false
        root.contentActivated(root._content)
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

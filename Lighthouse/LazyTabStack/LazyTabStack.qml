/*
 * SPDX-FileCopyrightText: Copyright (C) 2026 kalaksi@users.noreply.github.com
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts

import Lighthouse.LazyContent 1.0


/// Stack of tabs backed by LazyContent shells. Does not include a tab bar.
StackLayout {
    id: root

    property int createDelay: 16
    property int destroyDelay: 100
    property Component loadingIndicator: null

    readonly property var tabTitles: root._tabTitles
    readonly property Item currentContent: root._currentContent

    property var _tabTitles: []
    property Item _currentContent: null
    property var _tabEntries: []
    property bool _syncBlocked: false

    signal contentActivated(Item content)
    signal contentDeactivated(Item content)
    signal contentClosing(Item content)

    onCurrentIndexChanged: {
        if (!root._syncBlocked) {
            root._syncActiveTab()
        }
    }

    Component {
        id: lazyContentComponent

        LazyContent {
            createDelay: root.createDelay
            destroyDelay: root.destroyDelay
            loadingIndicator: root.loadingIndicator

            onContentActivated: function(content) {
                root.contentActivated(content)
            }
            onContentDeactivated: function(content) {
                root.contentDeactivated(content)
            }
            onContentClosing: function(content) {
                root.contentClosing(content)
            }
            onContentLoaded: root._updateCurrentContent()
        }
    }

    function deactivateAll() {
        for (const entry of root._tabEntries) {
            entry.lazyContent.active = false
        }
    }

    function addTab(title, contentItem, options = {}) {
        const lazyContent = lazyContentComponent.createObject(root)
        root._tabEntries.push({
            "title": title,
            "canClose": options.canClose ?? true,
            "lazyContent": lazyContent,
        })
        lazyContent.setContent(contentItem)
        root._updateTabTitles()
        if (options.select ?? true) {
            root.selectTab(root._tabEntries.length - 1)
        }
        return root._tabEntries.length - 1
    }

    function addLazyTab(title, contentFactory, options = {}) {
        const lazyContent = lazyContentComponent.createObject(root, {
            contentFactory: contentFactory,
        })
        root._tabEntries.push({
            "title": title,
            "canClose": options.canClose ?? true,
            "lazyContent": lazyContent,
        })
        root._updateTabTitles()
        if (options.select ?? true) {
            root.selectTab(root._tabEntries.length - 1)
        }
        return root._tabEntries.length - 1
    }

    function closeTab(index) {
        if (index < 0 || index >= root._tabEntries.length) {
            return false
        }
        const entry = root._tabEntries[index]
        if (!entry.canClose) {
            return false
        }

        const oldCurrentIndex = root.currentIndex
        // Keep the logical entries and StackLayout children consistent while
        // removing the shell. Reparenting the shell changes currentIndex
        // synchronously, so defer lifecycle synchronization until both sides
        // have been updated.
        root._syncBlocked = true
        root._tabEntries.splice(index, 1)
        entry.lazyContent.discard()

        const tabCount = root._tabEntries.length
        let targetIndex = -1
        if (tabCount > 0) {
            if (index === oldCurrentIndex) {
                targetIndex = Math.min(index, tabCount - 1)
            }
            else {
                targetIndex = index < oldCurrentIndex ? oldCurrentIndex - 1 : oldCurrentIndex
            }
        }
        root.currentIndex = targetIndex
        root._syncBlocked = false
        root._syncActiveTab()
        root._updateTabTitles()
        return true
    }

    function closeTabByContent(item) {
        const index = root.indexOfContent(item)
        if (index < 0) {
            return false
        }
        return root.closeTab(index)
    }

    function contentAt(index) {
        if (index < 0 || index >= root._tabEntries.length) {
            return null
        }
        return root._tabEntries[index].lazyContent.content
    }

    function indexOfContent(item) {
        for (const [i, entry] of root._tabEntries.entries()) {
            if (entry.lazyContent.content === item) {
                return i
            }
        }
        return -1
    }

    function selectTab(index) {
        if (index < 0 || index >= root._tabEntries.length) {
            return
        }
        root.currentIndex = index
        root._syncActiveTab()
    }

    function _updateCurrentContent() {
        root._currentContent = root.contentAt(root.currentIndex)
    }

    function _updateTabTitles() {
        root._tabTitles = root._tabEntries.map(entry => entry.title)
    }

    function _syncActiveTab() {
        for (const [i, entry] of root._tabEntries.entries()) {
            entry.lazyContent.active = (i === root.currentIndex)
        }
        root._updateCurrentContent()
    }
}

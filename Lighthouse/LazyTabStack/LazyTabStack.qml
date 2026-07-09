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

    property var tabTitles: []
    property int _contentRevision: 0

    readonly property var currentContent: {
        void root._contentRevision
        return root.contentAt(root.currentIndex)
    }

    property var _tabEntries: []

    signal tabsChanged()
    signal tabSelected(int index)
    signal contentActivated(Item content)
    signal contentDeactivated(Item content)
    signal contentClosing(Item content)

    onCurrentIndexChanged: root._syncActiveTab()

    Component {
        id: lazyContentComponent

        LazyContent {}
    }

    function activateTab(index) {
        if (index < 0 || index >= root._tabEntries.length) {
            return
        }
        if (root.currentIndex !== index) {
            root.currentIndex = index
        }
        root._syncActiveTab()
        root.tabSelected(index)
    }

    function deactivateAll() {
        for (const entry of root._tabEntries) {
            entry.lazyContent.active = false
        }
    }

    function addTab(title, contentItem, selectTab = true, canClose = true) {
        const lazyContent = lazyContentComponent.createObject(root, root._lazyContentProperties())
        root._connectLazyContent(lazyContent)
        root._tabEntries.push({
            "title": title,
            "canClose": canClose,
            "lazyContent": lazyContent,
        })
        lazyContent.setContent(contentItem)
        if (selectTab) {
            root.activateTab(root._tabEntries.length - 1)
        }
        root._notifyTabsChanged()
        return root._tabEntries.length - 1
    }

    function addLazyTab(title, contentFactory, selectTab = true, canClose = true) {
        const props = root._lazyContentProperties()
        props.contentFactory = contentFactory
        const lazyContent = lazyContentComponent.createObject(root, props)
        root._connectLazyContent(lazyContent)
        root._tabEntries.push({
            "title": title,
            "canClose": canClose,
            "lazyContent": lazyContent,
        })
        if (selectTab) {
            root.activateTab(root._tabEntries.length - 1)
        }
        root._notifyTabsChanged()
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

        entry.lazyContent.discard()
        root._tabEntries.splice(index, 1)
        root._notifyTabsChanged()

        const tabCount = root._tabEntries.length
        if (tabCount > 0) {
            root.activateTab(Math.min(index, tabCount - 1))
        }
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
        void root._contentRevision
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
        root.activateTab(index)
    }

    function _lazyContentProperties() {
        return {
            active: false,
            createDelay: root.createDelay,
            destroyDelay: root.destroyDelay,
            loadingIndicator: root.loadingIndicator,
        }
    }

    function _connectLazyContent(lazyContent) {
        lazyContent.contentActivated.connect(function(content) {
            root.contentActivated(content)
        })
        lazyContent.contentDeactivated.connect(function(content) {
            root.contentDeactivated(content)
        })
        lazyContent.contentClosing.connect(function(content) {
            root.contentClosing(content)
        })
        lazyContent.contentLoaded.connect(function() {
            for (const entry of root._tabEntries) {
                if (entry.lazyContent === lazyContent) {
                    root._contentRevision++
                    break
                }
            }
        })
    }

    function _notifyTabsChanged() {
        root.tabTitles = root._tabEntries.map(entry => entry.title)
        root.tabsChanged()
    }

    function _syncActiveTab() {
        for (const [i, entry] of root._tabEntries.entries()) {
            entry.lazyContent.active = (i === root.currentIndex)
        }
    }
}

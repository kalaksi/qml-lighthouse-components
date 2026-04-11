/*
 * SPDX-FileCopyrightText: Copyright (c) 2026 kalaksi@users.noreply.github.com
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import QtQuick.Controls
import QtWebEngine
import QtWebChannel

Item {
    id: root

    property string content: ""
    property string mode: "text"
    property string theme: ""
    property color defaultBackgroundColor: "transparent"
    property bool _editorReady: false

    signal editorContentChanged(string newContent)
    signal editorReady()

    // Currently only emitted in Vim mode.
    signal writeRequested()
    // Currently only emitted in Vim mode.
    signal quitRequested(bool writeChanges, bool discardUnsaved, bool writeOnlyIfModified)

    onContentChanged: {
        root.setContent(root.content)
    }

    onModeChanged: {
        root.setMode(root.mode)
    }

    onThemeChanged: {
        root.setTheme(root.theme)
    }


    WebChannel {
        id: channel
        registeredObjects: [bridge]
    }

    QtObject {
        id: bridge
        WebChannel.id: "bridge"

        function contentChanged(content) {
            root.editorContentChanged(content)
        }

        function editorReady() {
            // console.log("Editor is now ready");
            root._editorReady = true

            root.setMode(root.mode)
            root.setTheme(root.theme)
            root.setContent(root.content)

            root.editorReady()
        }

        function writeRequested() {
            root.writeRequested()
        }

        function quitRequested(writeChanges, discardUnsaved, writeOnlyIfModified) {
            root.quitRequested(writeChanges, discardUnsaved, writeOnlyIfModified)
        }
    }

    WebEngineView {
        id: webView
        anchors.fill: parent
        backgroundColor: root.defaultBackgroundColor
        webChannel: channel
        url: Qt.resolvedUrl("ace-editor.html")
    }

    function focusEditor() {
        webView.forceActiveFocus()
        if (!root._editorReady) {
            return
        }
        webView.runJavaScript(`
            if (window.editor && typeof window.editor.focus === 'function') {
                window.editor.focus();
            }
        `)
    }

    function setContent(content) {
        if (!root._editorReady) {
            return
        }

        webView.runJavaScript(`
            window.editor.setValue(${JSON.stringify(content)});
            window.editor.clearSelection();
        `)
    }

    function resetCursor() {
        if (!root._editorReady) {
            return false
        }

        // Move cursor to the top of the document.
        webView.runJavaScript(`
            (function() {
                if (!window.editor) {
                    return;
                }
                window.editor.clearSelection();
                if (window.editor.navigateFileStart) {
                    window.editor.navigateFileStart();
                } else {
                    window.editor.selection.moveTo(0, 0);
                }
            })();
        `)

        // Not sure if always executed in proper order.
        focusEditor()
    }

    function getContent(callback) {
        if (!root._editorReady) {
            return
        }

        webView.runJavaScript(
            `(function() { return window.editor ? window.editor.getValue() : ""; })();`,
            function(result) {
                if (callback) {
                    callback(result)
                }
            }
        )
    }

    function setMode(mode) {
        if (!root._editorReady || !mode) {
            return
        }

        webView.runJavaScript(`window.editor.session.setMode("ace/mode/${mode}");`)
    }

    function setTheme(theme) {
        if (!root._editorReady || !theme) {
            return
        }

        webView.runJavaScript(`window.editor.setTheme("ace/theme/${theme}");`)
    }

    /// Set Ace Editor options.
    function setEditorOption(optionName, value) {
        if (!root._editorReady) {
            return
        }

        let optionNameString = JSON.stringify(optionName)
        let valueString = JSON.stringify(value)
        webView.runJavaScript(`window.editor.setOption(${optionNameString}, ${valueString});`)
    }

    function getEditorOption(optionName) {
        if (!root._editorReady) {
            return
        }

        let optionNameString = JSON.stringify(optionName)
        webView.runJavaScript(`return window.editor.getOption(${optionNameString});`)
    }

    function callEditorFunction(functionName, ...args) {
        if (!root._editorReady) {
            return
        }

        let argsString = args.map(arg => JSON.stringify(arg)).join(", ")

        webView.runJavaScript(`
            if (typeof window.editor.${functionName} === 'function') {
                window.editor.${functionName}(${argsString});
            }
            else {
                throw new Error("Editor function '${functionName}' not found");
            }
        `)
    }

    function showVimNotification(message, textColor) {
        if (!root._editorReady) {
            return
        }

        let messageString = JSON.stringify(message)
        let colorString = JSON.stringify(textColor ? textColor : "#ff6666")
        webView.runJavaScript(`
            (function() {
                if (!window.editor || !window.editor.state || !window.editor.state.cm) {
                    return;
                }
                var cm = window.editor.state.cm;
                var pre = document.createElement("div");
                pre.style.color = ` + colorString + `;
                pre.style.whiteSpace = "pre";
                pre.textContent = ` + messageString + `;
                if (cm.openNotification) {
                    cm.openNotification(pre, {bottom: true, duration: 5000});
                }
            })();
        `)
    }

    function setRendererOption(optionName, value) {
        if (!root._editorReady) {
            return
        }

        let optionNameString = JSON.stringify(optionName)
        let valueString = JSON.stringify(value)
        webView.runJavaScript(`window.editor.renderer.setOption(${optionNameString}, ${valueString});`)
    }

    function getRendererOption(optionName) {
        if (!root._editorReady) {
            return
        }

        let optionNameString = JSON.stringify(optionName)
        webView.runJavaScript(`return window.editor.renderer.getOption(${optionNameString});`)
    }
}

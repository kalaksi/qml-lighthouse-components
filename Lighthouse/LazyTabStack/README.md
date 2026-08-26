# Lighthouse.LazyTabStack

Tab stack backed by `LazyContent`. Does not include a tab bar.

## Usage

```qml
import Lighthouse.LazyTabStack 1.0

LazyTabStack {
    id: tabs
    anchors.fill: parent
    loadingIndicator: MySpinnerComponent  // optional

    onContentActivated: function(content) {
        content.startUpdates()
    }

    onCurrentIndexChanged: {
        myTabBar.setCurrentIndex(currentIndex)
    }

    Component.onCompleted: {
        tabs.addTab("Overview", overviewView.createObject(null))
        tabs.addLazyTab("Logs", function(shell) {
            return logView.createObject(shell, { anchors.fill: shell })
        })
    }
}
```

## API Reference

### Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `currentIndex` | `int` | | Index of the visible tab. |
| `createDelay` | `int` | `16` | Passed to each tab shell. |
| `destroyDelay` | `int` | `100` | Passed to each tab shell. |
| `loadingIndicator` | `Component` | `null` | Passed to each tab shell. Null shows nothing. |
| `tabTitles` | `var` (read-only array) | `[]` | Title string for each tab. |
| `currentContent` | `var` (read-only) | | Content item of the current tab. Updates when lazy content loads. |

### Functions

#### `addTab(title, content, options)`

Add an eagerly created tab.

- **title**: Tab title shown in an external tab bar.
- **content**: Content item; reparented into a new shell via `setContent()`.
- **options.select** (optional, default `true`): Select the new tab after adding.
- **options.canClose** (optional, default `true`): Whether `closeTab()` may remove this tab.

Returns the new tab index.

#### `addLazyTab(title, contentFactory, options)`

Add a lazily created tab.

- **title**: Tab title shown in an external tab bar.
- **contentFactory**: Must be `function(Item shell): Item`. Passed to the tab shell.
- **options.select** (optional, default `true`): Select the new tab after adding.
- **options.canClose** (optional, default `true`): Whether `closeTab()` may remove this tab.

Returns the new tab index.

#### `deactivateAll()`

Set every tab shell inactive without unloading content.

#### `closeTab(index)`

Close the tab at `index` if `canClose` is true. Destroys content asynchronously.

Returns `true` if the tab was closed.

#### `closeTabByContent(item)`

Close the tab containing `item`.

Returns `true` if a matching tab was closed.

#### `contentAt(index)`

Returns the content item at `index`, or `null`.

#### `indexOfContent(item)`

Returns the index of the tab containing `item`, or `-1`.

#### `selectTab(index)`

Show the tab at `index` and set its shell active.

### Signals

#### `contentActivated(Item content)`

Forwarded from a tab shell when it becomes active.

- **content**: The loaded content item.

#### `contentDeactivated(Item content)`

Forwarded from a tab shell when it becomes inactive.

- **content**: The loaded content item.

#### `contentClosing(Item content)`

Forwarded from a tab shell before its content is destroyed.

- **content**: The loaded content item.

## License

GPL-3.0-or-later. See [LICENSE](LICENSE) in this directory.

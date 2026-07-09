# Lighthouse.LazyContent

Lazy load of Item with optional loading indicator.

- Defers heavy UI construction until `active` becomes true.
- Loaded content stays mounted when `active` becomes false.
- Lifecycle signals for activation, deactivation, and closing.
- Discarding reparents off-screen and destroys asynchronously.

## Usage

```qml
import Lighthouse.LazyContent 1.0

LazyContent {
    id: panel
    anchors.fill: parent
    active: drawer.open
    loadingIndicator: MySpinnerComponent  // optional; null shows nothing

    contentFactory: function(shell) {
        return heavyView.createObject(shell, { anchors.fill: shell })
    }

    onContentActivated: function(content) {
        content.startUpdates()
    }
    onContentDeactivated: function(content) {
        content.stopUpdates()
    }
    onContentClosing: function(content) {
        content.cleanup()
    }
}
```

## API Reference

### Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `active` | `bool` | `false` | When true, creates content if needed and emits `contentActivated`. When false, emits `contentDeactivated` only. |
| `createDelay` | `int` | `16` | Milliseconds to wait before constructing content so the shell can paint first. |
| `destroyDelay` | `int` | `100` | Milliseconds between teardown steps when discarding. |
| `loadingIndicator` | `Component` | `null` | Optional component shown while content is being created. Null shows nothing. |
| `contentFactory` | `var` | `null` | Must be `function(Item shell): Item`. Creates content parented to the shell. |
| `loaded` | `bool` (read-only) | | True once content exists. |
| `content` | `Item` (read-only) | | Reference to the created content item. |

### Functions

#### `setContent(item)`

Eagerly set content. The item is reparented into the shell. Emits `contentLoaded`, and `contentActivated` if `active` is true.

#### `load()`

Create content immediately if `active` is true and content is not yet loaded.

#### `scheduleLoad()`

Schedule deferred content creation after `createDelay`.

#### `discard()`

Detach from the layout immediately and destroy content asynchronously. Emits `contentDeactivated`, then `contentClosing` before teardown.

### Signals

#### `contentLoaded()`

Emitted once content exists, whether loaded eagerly via `setContent()` or lazily via `contentFactory`.

#### `contentActivated(Item content)`

Emitted when `active` becomes true and content exists.

- **content**: The loaded content item.

#### `contentDeactivated(Item content)`

Emitted when `active` becomes false and content exists.

- **content**: The loaded content item.

#### `contentClosing(Item content)`

Emitted before content is destroyed during `discard()`. Not emitted if discard happens before content was created.

- **content**: The loaded content item.

## License

GPL-3.0-or-later. See [LICENSE](LICENSE) in this directory.

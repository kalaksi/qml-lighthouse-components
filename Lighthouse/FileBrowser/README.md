# Lighthouse.FileBrowser

Pure QML tree-style file browser with configurable columns.

- Tree-style directory navigation with expand/collapse.
- **Split view**: optional directory tree (left) and file list (right); selection in the tree drives the file list.
- Customizable columns with configurable headers and widths.
- Works with any data source that provides file/directory information.
- Caching of directory contents for efficient navigation.
- Pure QML/JavaScript implementation - easy to include with no additional dependencies.

## Usage

### Integration Example

```qml
import Lighthouse.FileBrowser 1.0

Item {
    FileBrowser {
        id: fileBrowser
        anchors.fill: parent
        directorySeparator: "/"
        columnHeaders: ["Size", "Date", "Permissions"]
        columnWidths: [100, 120, 100]

        onDirectoryExpanded: function(directoryPath, isCached) {
            if (!isCached) {
                // Not in cache, so get data from backend.
                let files = SomeBackend.listFiles(directoryPath)
                let newEntries = files.map(entry =>
                    fileBrowser.buildEntry(
                        directoryPath,
                        entry.name,
                        entry.type,
                        [entry.size, entry.date, entry.permissions]
                    )
                )
                fileBrowser.openDirectory(directoryPath, newEntries)
            }
            else {
                fileBrowser.openDirectory(directoryPath)
            }
        }
    }
}
```

## API Reference

### Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `directorySeparator` | `string` | required | Path separator (e.g. `"/"`). |
| `directoryTreeRootPath` | `string` | `"/"` | Root path for the directory tree when using split view. |
| `rootPath` | `string` | same as `directoryTreeRootPath` | Current root path (single-view mode). |
| `useSplitView` | `bool` | `false` | Show directory tree and file list side by side. |
| `columnHeaders` | `var` (array) | `[]` | Column header strings. |
| `columnWidths` | `var` (array) | `[0.4]` | Column width factors or values. |
| `indentWidth` | `int` | `20` | Indentation width for nested directories. |
| `rowHeight` | `int` | `28` | Height of each row in pixels. |
| `arrowWidth` | `int` | `20` | Width of the expand/collapse arrow. |
| `nameColumnWidth` | `int` | `200` | Width of the name column. |
| `headerColor` | `color` | `palette.alternateBase` | Background color of the header row. |
| `contextMenu` | `Menu` | `null` | Context menu shown on right-click. |
| `hideDirectories` | `bool` | `false` | Hide directories in the file list (split view). |
| `directoryIconSource` | `string` | `""` | Icon for directory rows; empty uses default. |
| `dimmedPaths` | `var` (array) | `[]` | Paths shown with reduced opacity. |
| `selectedDirectory` | `string` (read-only) | | Currently selected directory path in the tree (split view). |
| `selectedFiles` | `var` (read-only) | | Currently selected file paths in the file list. |

### Functions

#### `openInitialDirectory(dirPath)`

Opens the browser at the given path; expands the tree to that path and loads directory contents as needed. Use when starting the browser or navigating from outside.

#### `openDirectory(dirPath, fileEntries)`

Opens and displays a directory. In split view, also refreshes the file list when new content is loaded.

- **Parameters:**
  - `dirPath` (string): The directory path to open.
  - `fileEntries` (array, optional): Entry objects from `buildEntry()`. If omitted, uses cached data.

#### `buildEntry(directory, name, fileType, columnData)`

Builds entries for `openDirectory()`.

The `fileType` parameter accepts:
- `"d"` - Directory
- `"f"` - Regular file
- `"l"` - Symbolic link
- `"c"` - Character device
- `"b"` - Block device
- `"p"` - Named pipe (FIFO)
- `"s"` - Socket

Only directory type is mandatory; other types mainly affect appearance.

#### `refreshView()`

Rebuilds the display from cached data. When using the directory tree, the current selection is preserved if that path is still in the tree after the rebuild.

#### `toggleDirectory(path)`

Programmatically toggle directory expand/collapse state.

#### `clearCache()`

Clears all cached directory data and resets the view.

### Signals

#### `directoryExpanded(string path, bool isCached)`

Emitted when a directory is expanded (e.g. by clicking the arrow or selecting the row).

- **path**: The directory path that was expanded.
- **isCached**: Whether the directory data is already cached.

#### `renamed(string fullPath, string newName)`

Emitted after a successful rename in the UI.

## Limitations

- Only tested on Linux.
- Maximum of 8 data columns (in addition to the name column).

## License

GPL-3.0-or-later. See [LICENSE](LICENSE) in this directory.

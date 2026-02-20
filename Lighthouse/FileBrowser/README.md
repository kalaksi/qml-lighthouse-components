# Lighthouse.FileBrowser

Pure QML tree-style file browser with configurable columns.

- Tree-style directory navigation with expand/collapse.
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
        columnHeaders: ["Size", "Date", "Permissions"]
        columnWidths: [100, 120, 100]
        
        onDirectoryExpanded: function(directoryPath, isCached) {
            if (!isCached) {
                // Not in cache, so get data from backend.
                let files = SomeBackend.ListFiles();
                let newEntries = files.map(entry => 
                    fileBrowser.buildEntry(
                        directoryPath,
                        entry.name,
                        entry.type,
                        [entry.size, entry.date, entry.permissions]
                    )
                )

                fileBrowser.openDirectory(path, newEntries)
            }
            else {
                // Relying on cached data.
                fileBrowser.openDirectory(path)
            }
        }
    }
}
```

## API Reference

### Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `columnHeaders` | `var` (array) | `["Column 1", "Column 2"]` | Array of column header strings |
| `columnWidths` | `var` (array) | `[200, 200]` | Array of column widths in pixels |
| `indentWidth` | `int` | `20` | Indentation width for nested directories |
| `rowHeight` | `int` | `28` | Height of each row in pixels |
| `arrowWidth` | `int` | `20` | Width of the arrow indicator |
| `nameColumnWidth` | `int` | `200` | Width of the name column |
| `headerColor` | `color` | `palette.alternateBase` | Background color of the header row |

### Functions

#### `openDirectory(dirPath, fileEntries)`

Opens and displays a directory in the browser.

- **Parameters:**
  - `dirPath` (string): The directory path to open
  - `fileEntries` (array, optional): Array of entry objects created with `buildEntry()`. If omitted, uses cached data.

#### `buildEntry(directory, name, fileType, columnData)`

Builds entries that are passed to openDirectory().

The `fileType` parameter accepts:
- `"d"` - Directory
- `"f"` - Regular file
- `"l"` - Symbolic link
- `"c"` - Character device
- `"b"` - Block device
- `"p"` - Named pipe (FIFO)
- `"s"` - Socket

Only directory-type is mandatory. Otherwise, type mostly changes the looks.

#### `refreshView()`

Refreshes the display with current cached data.

#### `toggleDirectory(path)`

Programmatically toggle directory expansion state.

- **Parameters:**
  - `path` (string): Directory path to toggle

#### `clearCache()`

Clears all cached directory data and resets the view.

### Signals

#### `directoryExpanded(string path, bool isCached)`

Emitted when a directory is expanded by user interaction.

- **Parameters:**
  - `path` (string): The directory path that was expanded
  - `isCached` (bool): Whether the directory data is already cached

## Limitations

- Only tested on Linux.
- Currently can use maximum of 8 data columns (in addition to the name column)

## License

GPL-3.0-or-later. See [LICENSE](LICENSE) in this directory.

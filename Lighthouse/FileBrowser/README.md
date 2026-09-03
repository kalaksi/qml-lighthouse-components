# Lighthouse.FileBrowser

Pure QML tree-style file browser with configurable columns.

- Tree-style directory navigation with expand/collapse.
- **Split view**: optional directory tree (left) and file list (right); selection in the tree drives the file list. Expanding via the arrow only reveals child directories in the tree — it does not select or open that directory in the file list.
- Customizable columns with configurable headers and widths.
- Works with any data source that provides file/directory information.
- Caching of directory contents for efficient navigation.
- Split-view navigation history (back/forward, including mouse buttons) and an optional file-list filter bar.
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
| `headerBorderColor` | `color` | `palette.mid` | Border color of the header row. |
| `sortColumnIndex` | `int` | `0` | Column currently used for sorting (name column is `0`). |
| `sortAscending` | `bool` | `true` | Sort direction; clicking the same header toggles this. |
| `contextMenu` | `Menu` | `null` | Context menu shown on right-click. |
| `splitHandleGap` | `int` | `4` | Extra space beside the directory tree so the split handle does not overlap its scrollbar. |
| `hideDirectories` | `bool` | `false` | Hide directories in the file list (split view). |
| `directoryIconSource` | `string` | `""` | Icon for directory rows; empty uses default. |
| `dimmedPaths` | `var` (array) | `[]` | Paths shown with reduced opacity. |
| `enableShortcuts` | `bool` | `false` | When true (split view), Find opens the file-list filter bar and Cancel closes it. |
| `tooltipDelay` | `int` | `800` | Milliseconds before truncated-name tooltips appear. |
| `verticalScrollBar` | `Component` | `null` | Optional vertical scrollbar for all tree views (single and split). |
| `selectedDirectory` | `string` (read-only) | | Currently selected directory path in the tree (split view). |
| `selectedFiles` | `var` (read-only) | | Currently selected paths in the file list (includes directories). |
| `selectedFilesOnly` | `var` (read-only) | | `selectedFiles` with directory paths removed. |
| `hasSingleSelection` | `bool` (read-only) | | True when exactly one row is selected in the active view. |
| `canNavigateBack` | `bool` (read-only) | | True when split-view history can go back. |
| `canNavigateForward` | `bool` (read-only) | | True when split-view history can go forward. |

### Functions

#### `openInitialDirectory(dirPath)`

Opens the browser at the given path; expands the tree to that path and loads directory contents as needed. Use when starting the browser or navigating from outside.

#### `openDirectory(dirPath, fileEntries)`

Opens a directory (caches contents and expands it in the tree). In split view, the file list is updated only when `dirPath` is the selected directory or the target of `openInitialDirectory`/`navigateToDirectory` — not for expand-only via the tree arrow.

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

#### `openFilterBar()` / `closeFilterBar()`

Show or hide the file-list name filter (split view). `openFilterBar()` also focuses the filter field.

#### `toggleDirectory(path)`

Programmatically toggle directory expand/collapse state.

#### `clearCache()`

Clears all cached directory data and resets the view.

#### `startRenameForSelected()`

Begin in-place rename of the current selection.

#### `selectFilePath(path)`

Select the given path in the file list (split view) or the single tree.

#### `getCellValue(path, columnIndex)`

Return the displayed value for `path` at `columnIndex`, or `undefined` if the path is not in the current view.

#### `navigateToDirectory(dirPath)`

Navigate to `dirPath` (expands the tree and loads contents as needed). Records history in split view. Mouse back/forward buttons call `navigateBack()` / `navigateForward()`.

#### `navigateBack()` / `navigateForward()`

Move through split-view directory history.

#### `navigationError(path)`

Call from the host when a directory listing failed. Clears pending expand/navigation for that path. Returns `true` if the failure was a history step (the browser retries the previous/next history entry; the host should not treat it as a user-facing error).

### Signals

#### `directoryExpanded(string path, bool isCached)`

Emitted when a directory is expanded (e.g. by clicking the arrow or selecting the row). In split view, selecting a row also opens it in the file list; expanding via the arrow only loads children into the tree.

- **path**: The directory path that was expanded.
- **isCached**: Whether the directory data is already cached.

#### `renamed(string fullPath, string newName)`

Emitted after a rename is committed in the UI.

- **fullPath**: The entry's original full path.
- **newName**: The new name entered by the user.

**Contract:** the handler must apply the rename and then trigger a refresh (re-list the
directory and call `openDirectory()`/`refreshView()`). The renamed entry is then automatically
re-selected, and scrolled into view, on the next refresh that contains it.

## Limitations

- Only tested on Linux.
- Maximum of 8 data columns (in addition to the name column).

## License

GPL-3.0-or-later. See [LICENSE](LICENSE) in this directory.

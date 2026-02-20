# Lighthouse QML components

QML components used in [Lightkeeper](https://github.com/kalaksi/lightkeeper) and other projects.

## Components

- **Lighthouse.AceEditor** – QML wrapper for the [Ace](https://ace.c9.io/) code editor (WebView-based).
- **Lighthouse.FileBrowser** – Pure QML tree-style file browser with configurable columns.
- **Lighthouse.FilePermissionsDialog** – Dialog for editing Unix file permissions and ownership.

See the `Lighthouse/` directory. Each module has its own QML files and `qmldir`.
  
Add this repository as a QML import path (e.g. the repo root or the directory that contains `Lighthouse/`).

```qml
import Lighthouse.AceEditor 1.0
import Lighthouse.FileBrowser 1.0
import Lighthouse.FilePermissionsDialog 1.0
```

# Component: Ace editor

This is a QML module wrapper for the Ace code editor (https://ace.c9.io/). It provides a convenient way to integrate the Ace editor into QML-based projects.

NOTE: Project is still in development.

## Getting started

Git submodule is used to get the JavaScript sources for Ace editor. Here are the steps:
```
git clone --recursive <repo-url>
cd qml-lighthouse-ace-editor

# Or if you have already repo cloned:
# git submodule update --init --recursive

# One way to include only necessary files:
cd Lighthouse/AceEditor/ace-builds
git sparse-checkout init --no-cone
git sparse-checkout set /LICENSE src-min-noconflict
```

## Usage

```qml
import Lighthouse.AceEditor 1.0

AceEditor {
    content: "your code here"
    mode: "javascript"
    theme: "tomorrow_night"
    defaultBackgroundColor: "#1d1f21"
    
    onEditorContentChanged: function(newContent) {
        // Handle content changes
    }
    
    onEditorReady: {
        // Editor is now fully initialized and ready.
        // Before this, API could be unavailable.
    }
}
```

### Properties

- **`content: string`** - Text content of the editor
- **`mode: string`** - Syntax highlighting mode (e.g., "javascript", "python", "text"). Default: "text"
- **`theme: string`** - Ace editor theme (e.g., "tomorrow_night", "monokai", "github"). Default: ""
- **`defaultBackgroundColor: color`** - Background color for the WebView. Default: "transparent"

### Signals

- **`editorContentChanged(string newContent)`** - Emitted when the editor content changes
- **`editorReady()`** - Emitted when the editor is fully initialized and ready to use

### Functions

- **`setContent(string content)`** - Set the editor content
- **`getContent(function callback)`** - Get the editor content
- **`setMode(string mode)`** - Set the syntax highlighting mode
- **`setTheme(string theme)`** - Set the Ace editor theme
- **`setEditorOption(string optionName, var value)`** - Set an Ace editor option
- **`getEditorOption(string optionName)`** - Get an Ace editor option
- **`setRendererOption(string optionName, var value)`** - Set an Ace renderer option
- **`getRendererOption(string optionName)`** - Get an Ace renderer option
- **`callEditorFunction(string functionName, ...args)`** - Call any Ace editor function

### Example: Setting Editor Options

```qml
AceEditor {
    id: editor
    
    onEditorReady: {
        editor.setEditorOption("fontSize", 14)
        editor.setEditorOption("wrap", true)
        editor.setRendererOption("showPrintMargin", false)
    }
}
```


AceEditor embeds [Ace editor](https://github.com/ajaxorg/ace-builds) as a **git submodule**. After cloning this repo, run:

```bash
git submodule update --init --recursive
```

To keep the ace-builds checkout small (only the files needed at runtime), use sparse-checkout inside the submodule:

```bash
cd Lighthouse/AceEditor/ace-builds
git sparse-checkout init --no-cone
git sparse-checkout set LICENSE src-min-noconflict
```

# Component: File browser
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
                // Not in cache, so get data from backend and build browser entries after receiving.
                let newData = SomeBackend.GetFiles();
            }
            else {
                // Relying on cached data.
                fileBrowser.openDirectory(path)
            }
        }
    }

    Connection {
        target: SomeBackend

        function onFilesReceived(files) {
            let browserEntries = files.map(entry => 
                fileBrowser.buildEntry(
                    directoryPath,
                    entry.name,
                    entry.type,
                    [entry.size, entry.date, entry.permissions]
                )
            )

            fileBrowser.openDirectory(path, browserEntries)
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

## Technical Details

# Licenses
Copyright © 2026 kalaksi@users.noreply.github.com.  

Modules are licensed independently, see their respective subdirs.  
Here's a summary:  
- FileBrowser: GPL-3.0-or-later
- FilePermissionsDialog: GPL-3.0-or-later
- AceEditor: BSD-3-Clause



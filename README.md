# Lighthouse QML components

Pure QML components used in [Lightkeeper](https://github.com/kalaksi/lightkeeper) and other projects.

Add this repository as a QML import path (e.g. the repo root or the directory that contains `Lighthouse/`).

```qml
import Lighthouse.AceEditor 1.0
import Lighthouse.FileBrowser 1.0
import Lighthouse.FilePermissionsDialog 1.0
import Lighthouse.LazyContent 1.0
import Lighthouse.LazyTabStack 1.0
```

## Components

- **[Lighthouse.AceEditor](Lighthouse/AceEditor/README.md)** – Wrapper for the [Ace](https://ace.c9.io/) code editor (WebView-based).
- **[Lighthouse.FileBrowser](Lighthouse/FileBrowser/README.md)** – Tree-style file browser with configurable columns; optional split view (directory tree + file list).
- **[Lighthouse.FilePermissionsDialog](Lighthouse/FilePermissionsDialog/README.md)** – Dialog for editing Unix file permissions and ownership.
- **[Lighthouse.LazyContent](Lighthouse/LazyContent/README.md)** – Deferred content shell with optional loading indicator and non-blocking teardown.
- **[Lighthouse.LazyTabStack](Lighthouse/LazyTabStack/README.md)** – Tab stack backed by LazyContent shells (no tab bar).

See the `Lighthouse/` directory. Each module has its own QML files and `qmldir`.

## Licenses

Copyright © 2026 kalaksi@users.noreply.github.com.

Modules are licensed independently, see their respective subdirs. Summary:

- FileBrowser: GPL-3.0-or-later
- FilePermissionsDialog: GPL-3.0-or-later
- LazyContent: GPL-3.0-or-later
- LazyTabStack: GPL-3.0-or-later
- AceEditor: BSD-3-Clause

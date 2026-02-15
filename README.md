# Lighthouse QML components

QML components used in [Lightkeeper](https://github.com/kalaksi/lightkeeper) and other projects.

## Modules

- **Lighthouse.AceEditor** – QML wrapper for the [Ace](https://ace.c9.io/) code editor (WebView-based).
- **Lighthouse.FileBrowser** – Pure QML tree-style file browser with configurable columns.

See the `Lighthouse/` directory. Each module has its own QML files and `qmldir`.

## Usage

Add this repository as a QML import path (e.g. the repo root or the directory that contains `Lighthouse/`).

```qml
import Lighthouse.AceEditor 1.0
import Lighthouse.FileBrowser 1.0
```

## Ace editor (ace-builds)

AceEditor embeds [ace-builds](https://github.com/ajaxorg/ace-builds) as a **git submodule**. After cloning this repo, run:

```bash
git submodule update --init --recursive
```

To keep the ace-builds checkout small (only the files needed at runtime), use sparse-checkout inside the submodule:

```bash
cd Lighthouse/AceEditor/ace-builds
git sparse-checkout init --no-cone
git sparse-checkout set LICENSE src-min-noconflict
```

## License

- FileBrowser: GPL-3.0-or-later (see root LICENSE).
- AceEditor: BSD-3-Clause (see `Lighthouse/AceEditor/LICENSE`).

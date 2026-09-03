# Lighthouse.FilePermissionsDialog

Dialog and content component for editing Unix file permissions (owner/group/others rwx, optional special bits) and ownership (owner/group names).

Use **FilePermissionsDialog** for a ready-made Qt Quick Controls dialog, or **FilePermissionsDialogContent** to embed the form in your own dialog (e.g. with custom styling).

The form accepts `ls -l`-style permission strings (9 or 10 characters, including `s`/`S`/`t`/`T` for setuid/setgid/sticky). On apply it returns a 4-digit octal mode (`0755`, `2755`, …) and owner/group names only when they changed.

## Usage

### Full dialog

```qml
import Lighthouse.FilePermissionsDialog 1.0

FilePermissionsDialog {
    id: permissionsDialog
    contextLabel: "Path"
    contextText: "/path/to/file"
    permissions: "rwxr-xr--"
    owner: "user"
    group: "group"
    showSpecialBits: true
    onApplied: function(mode, changedOwner, changedGroup) {
        // Apply chmod with `mode` (e.g. "0755").
        // `changedOwner` / `changedGroup` are empty when unchanged.
    }
}
permissionsDialog.open()
```

### Content only (custom dialog)

```qml
import Lighthouse.FilePermissionsDialog 1.0

Dialog {
    contentItem: FilePermissionsDialogContent {
        id: content
        contextLabel: "Path"
        contextText: path
        permissions: permissions
        owner: owner
        group: group
        showSpecialBits: true
    }
    standardButtons: Dialog.Ok | Dialog.Cancel
    onAccepted: {
        if (content.canAccept && content.hasChanges)
            doApply(content.resultMode, content.changedOwner, content.changedGroup)
    }
}
```

## API (FilePermissionsDialog)

- **Inputs** (aliased to content): `contextLabel`, `contextText`, `permissions`, `owner`, `group`, `warningText`, `warningTextColor`
- **Options**: `showOctal` (default `true`), `showSpecialBits` (default `false`), `tooltipDelay` (default `800`)
- **Styling**: `contentMargin`, `sectionSpacing`, `rowSpacing`, `marginTop`, `marginBottom`, `comboMinWidth`, `fontSize`, `optionSpacing`, `optionOctalOpacity`
- **Signal** `applied(string mode, string changedOwner, string changedGroup)` — emitted on OK only when the form is valid and something changed. `mode` is a 4-digit octal string including special bits (`0`–`7` in the first digit). `changedOwner` / `changedGroup` are empty strings when those fields were left unchanged.

## API (FilePermissionsDialogContent)

- **Inputs**: `contextLabel`, `contextText`, `permissions` (9- or 10-character `ls -l` string; leading file-type character is stripped when present), `owner`, `group`, `warningText`, `warningTextColor`, plus the options and styling properties above
- **Read-only**: `canAccept`, `hasChanges`, `resultMode`, `resultOwner`, `resultGroup`, `changedOwner`, `changedGroup`
- **Function**: `_updateFromProps()` — call when opening or when input properties change to sync the form (also runs automatically when `permissions` / `owner` / `group` change)

Long `contextText` is elided in the middle; the full path is shown in a tooltip when truncated.

## License

GPL-3.0-or-later. See [LICENSE](LICENSE) in this directory.

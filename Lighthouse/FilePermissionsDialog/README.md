# Lighthouse.FilePermissionsDialog

Dialog and content component for editing Unix file permissions (owner/group/others rwx) and ownership (owner/group names).

Use **FilePermissionsDialog** for a ready-made Qt Quick Controls dialog, or **FilePermissionsDialogContent** to embed the form in your own dialog (e.g. with custom styling).

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
    onApplied: function(ownerRwx, groupRwx, othersRwx, newOwner, newGroup) {
        // Apply chmod/chown
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
    }
    standardButtons: Dialog.Ok | Dialog.Cancel
    onAccepted: {
        if (content.canAccept)
            doApply(content.resultOwnerRwx, content.resultGroupRwx,
                content.resultOthersRwx, content.resultOwner, content.resultGroup)
    }
}
```

## API (FilePermissionsDialog)

- **Properties** (aliased to content): `contextLabel`, `contextText`, `permissions`, `owner`, `group`, plus styling: `contentMargin`, `sectionSpacing`, `rowSpacing`, `marginTop`, `marginBottom`, `comboMinWidth`, `fontSize`
- **Signal** `applied(string ownerRwx, string groupRwx, string othersRwx, string newOwner, string newGroup)`

## API (FilePermissionsDialogContent)

- **Inputs**: `contextLabel`, `contextText`, `permissions` (9- or 10-character string), `owner`, `group`, and optional styling properties
- **Read-only**: `canAccept`, `resultOwnerRwx`, `resultGroupRwx`, `resultOthersRwx`, `resultOwner`, `resultGroup`
- **Function**: `_updateFromProps()` – call when opening or when input properties change to sync the form

## License

GPL-3.0-or-later. See [LICENSE](LICENSE) in this directory.

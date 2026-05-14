# Windows 11 context menu behavior

Windows 11 introduced a modern compact context menu. Classic shell registry entries may appear under **Show more options** instead of the first-level menu.

This project uses classic per-user registry entries because they are:

- Easy to inspect
- Easy to uninstall
- No-admin by default
- Safer than shipping a native Explorer shell extension

A first-level Windows 11 shell extension would require a different architecture and is intentionally outside the scope of this project.

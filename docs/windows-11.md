# Windows 11 context menu behavior

Windows 11 uses a newer compact context menu. Classic registry-based context-menu entries often appear under **Show more options**.

This project intentionally uses the classic shell registry integration because it is:

- transparent
- reversible
- compatible with Windows 10
- simple to audit
- safe to install per user

A native top-level Windows 11 menu extension would require a different implementation model and more maintenance complexity.

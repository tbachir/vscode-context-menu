# Security Policy

## Supported usage

This project is a small Windows registry helper for Visual Studio Code context-menu entries.

Supported target:

- Windows 10 and Windows 11
- Current-user registry installation
- Visual Studio Code installed locally

## Reporting a security issue

Please open a private security advisory on GitHub if the repository is hosted there, or contact the maintainer through the repository profile.

Do not publish exploit details in a public issue before the issue has been reviewed.

## Design constraints

The project intentionally avoids:

- remote downloads during installation
- telemetry
- background services
- bundled binaries
- administrator requirements for the default install path

# Omarchy Quattro Plugin Starter

A small, working Omarchy Shell plugin repository you can use as the starting
point for a real plugin. The included example is a configurable bar widget that
uses Omarchy's shared UI components, follows the active theme, supports
horizontal and vertical bars, and runs a user-configured command when clicked.

> This repository is a starter, not a marketplace submission yet. Confirm the
> permanent plugin ID and replace the example identity before publishing.

## What is included

- A schema-version 1 `manifest.json` at the repository root
- A theme-native `bar-widget` entry point in `BarWidget.qml`
- Editable settings for label, tooltip, click command, accent state, and margin
- Local validation and tests in `scripts/check`
- A safe local-development symlink helper in `scripts/link-local`
- GitHub Actions validation on pushes and pull requests
- Development and marketplace publishing guides under `docs/`

No external runtime dependencies are required beyond Omarchy Quattro and the
packages it ships. Plugins execute unsandboxed inside the long-running
`omarchy-shell` process, so users should review plugin code before enabling it.

## Quick start

First, replace the starter identity as described in [CONTRIBUTING.md](CONTRIBUTING.md).
Then validate the repository:

```bash
./scripts/check
```

On a machine running Omarchy Quattro, link this checkout into the plugin
directory and enable it:

```bash
./scripts/link-local
omarchy plugin enable io.github.vuhuy.starter-widget --section right
```

Saving a file below the linked checkout should trigger a hot reload. To force
one:

```bash
omarchy-shell shell rescanPlugins
```

Remove the development link safely with Omarchy's own command:

```bash
omarchy plugin remove io.github.vuhuy.starter-widget
```

Omarchy detects that the installed plugin is a symlink and removes only the
link; it does not delete this checkout.

## Install from GitHub

Once this is pushed to its own public GitHub repository, users install and
enable it with:

```bash
omarchy plugin add https://github.com/YOUR_GITHUB_NAME/YOUR_REPOSITORY.git
omarchy plugin enable io.github.vuhuy.starter-widget --section right
```

Update or remove it with:

```bash
omarchy plugin update io.github.vuhuy.starter-widget
omarchy plugin remove io.github.vuhuy.starter-widget
```

The installer clones files, validates the manifest, and changes enabled state.
This starter has no install hooks, does not use `sudo`, and does not overwrite
user configuration.

## Make it yours

The manifest may declare one or more kinds: `bar-widget`, `bar`, `panel`,
`overlay`, `menu`, or `service`. Each kind needs its matching entry-point key.
See [docs/development.md](docs/development.md) for the mapping, configuration
model, and recommended workflow.

When the plugin is ready, follow [docs/publishing.md](docs/publishing.md). The
marketplace expects one plugin per public GitHub repository, a root manifest,
README and license, safe installation/removal, and optionally a root
`preview.png` (or another supported preview image format).

## License

[MIT](LICENSE)


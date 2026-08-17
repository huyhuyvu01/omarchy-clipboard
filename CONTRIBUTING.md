# Contributing

This repository is a starter for one Omarchy Quattro plugin. Keep the root
`manifest.json`, README, license, and every declared QML entry point together;
the Omarchy installer clones the whole repository into the user's plugin
directory.

## Development loop

1. Run `./scripts/check`.
2. On Omarchy Quattro, run `./scripts/link-local` once and enable the plugin.
3. Edit the QML. Installed plugin files are watched and reload automatically.
4. Force discovery with `omarchy-shell shell rescanPlugins` when changing the
   manifest or if a reload is missed.

Use two-space indentation. Prefer Omarchy's shared `qs.Commons` theme tokens
and `qs.Ui` components over hard-coded colors or dimensions.

## Changing the starter identity

Before turning this starter into a real plugin, change all of these together:

- `id`, `name`, `author`, `description`, and `version` in `manifest.json`
- `moduleName` in `BarWidget.qml`
- the title, description, install commands, and removal commands in `README.md`
- expected identity values in `tests/test_plugin.py`
- the copyright holder in `LICENSE`

Choose the ID carefully. Marketplace IDs are permanent and globally unique.
A lowercase reverse-domain name such as `io.github.handle.plugin-name` is the
recommended shape; the `omarchy.*` namespace is reserved.

## Pull requests

Keep changes focused, explain user-visible behavior, and include the output of
`./scripts/check`. For visual changes, attach an Omarchy screenshot and verify
both horizontal and vertical bar layouts.


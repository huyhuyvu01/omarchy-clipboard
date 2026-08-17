# Omarchy plugin development

This guide reflects the Omarchy `quattro` branch and marketplace documentation
reviewed on 13 August 2026.

## Repository contract

Omarchy installs a third-party plugin by cloning its Git repository into
`~/.config/omarchy/plugins/<plugin-id>/`. The repository root must contain
`manifest.json`; every declared entry point is a relative path inside that
repository. Entry-point paths cannot be absolute, contain `..`, or be symlinks.

The manifest kind-to-entry-point mapping is fixed:

| Kind | Entry-point key | Use |
| --- | --- | --- |
| `bar-widget` | `barWidget` | Component placed in a bar section |
| `bar` | `bar` | Full replacement for the active bar |
| `panel` | `panel` | Floating or summoned window |
| `overlay` | `overlay` | Full-screen surface |
| `menu` | `menu` | Summoned menu surface |
| `service` | `service` | Headless singleton |

Only one full `bar` plugin is active at a time. Panels, overlays, and menus load
when summoned unless the manifest sets `keepLoaded: true`. Services load at
startup after they are enabled.

## Bar-widget interface

The example extends `BarWidget` from `qs.Ui`. The host injects:

- `bar`: the active bar host and its theme-aware helpers
- `moduleName`: the canonical manifest ID
- `settings`: the widget's inline entry from `shell.json`

`BarWidget.setting(name, fallback)` reads per-instance settings safely. The bar
also provides helpers such as `run(command)`, `shellQuote(value)`,
`showTooltip(target, text)`, and `hideTooltip(target)`.

Settings live directly on the bar-layout entry; there is no nested `config`
object. For example:

```json
{
  "id": "io.github.vuhuy.starter-widget",
  "label": "Ship it",
  "command": "omarchy-launch-terminal"
}
```

Defaults and editor fields are advertised with `barWidget.defaults` and
`barWidget.schema` in the manifest. The starter shows `string`, `boolean`, and
`integer` fields.

## Local workflow

1. Customize the permanent identity listed in `CONTRIBUTING.md`.
2. Run `./scripts/check` after manifest or QML changes.
3. Run `./scripts/link-local` on Omarchy Quattro.
4. Enable and place the widget with `omarchy plugin enable <id> --section right`.
5. Edit normally; the plugin directory watcher reloads local changes.
6. Inspect discovery with `omarchy-shell shell listPlugins`.
7. Force a full disable, unlink, relink, rescan, and enable cycle with
   `./scripts/link-local --reload` if needed.

The official compatibility check is:

```bash
omarchy plugin validate .
```

`scripts/check` runs that automatically against a clean staging of publishable
files when the `omarchy` command is present, and uses the repository's portable
Python validator everywhere else (including GitHub Actions). Staging keeps
ignored editor or agent metadata out of the official symlink check.

## Configuration and IPC

Enabled third-party widgets are entries in `bar.layout.left`, `center`, or
`right` within `~/.config/omarchy/shell.json`. Other third-party plugin kinds
are entries in the top-level `plugins` array. Use Omarchy's commands to mutate
this file instead of rewriting user configuration yourself.

The shell IPC can summon or call enabled plugins:

```bash
omarchy-shell shell summon <id> '{}'
omarchy-shell shell hide <id>
omarchy-shell shell toggle <id> '{}'
omarchy-shell shell call <id> <method> <argument>
```

Summoned menu, panel, and overlay roots should expose `open(payloadJson)` and
`close()` lifecycle functions. Add an IPC target only when a plugin needs a
stable command surface beyond the shell's generic lifecycle routing.

## Design guidelines

- Use `qs.Commons` theme tokens and `qs.Ui` components.
- Scale geometry through shared style values instead of hard-coded colors and
  panel dimensions.
- Test horizontal and vertical bar orientations.
- Avoid install hooks, privileged commands, and implicit configuration writes.
- Document every external command or package the plugin calls.
- Treat plugin code as trusted desktop code: it runs unsandboxed.

## Primary references

- [Official Omarchy Shell reference](https://github.com/basecamp/omarchy/blob/quattro/docs/omarchy-shell.md)
- [First-party plugin examples](https://github.com/basecamp/omarchy/tree/quattro/shell/plugins)
- [Quickshell documentation](https://quickshell.org/docs/)

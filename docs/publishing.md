# Publishing checklist

Omarchy Plugins is an independent community marketplace. Its automated checks
validate repository structure and Quattro compatibility; listing approval is
not a security review.

## Before pushing

- [ ] Use one plugin per repository.
- [ ] Choose a permanent, globally unique lowercase ID outside `omarchy.*`.
- [ ] Update every identity location listed in `CONTRIBUTING.md`.
- [ ] Set a meaningful semantic version in `manifest.json`.
- [ ] Run `./scripts/check` and, on Omarchy, `omarchy plugin validate .`.
- [ ] Test install, enable, update, disable, and removal paths.
- [ ] Document all external runtime dependencies.
- [ ] Confirm the plugin does not overwrite user configuration implicitly.
- [ ] Verify the repository is public on GitHub.

## Required repository files

- Root `manifest.json`
- Root README with install and removal instructions
- Root license file
- Every QML file referenced by `entryPoints`

An optional root preview may be named `preview.png`, `preview.jpg`,
`preview.jpeg`, `preview.webp`, or `preview.avif`. The marketplace optimizes it
automatically. Inputs are limited to 50 MB and 40 megapixels.

## Listing metadata

Choose exactly one category:

- `Appearance`
- `Desktop`
- `Developer Tools`
- `Hardware`
- `Productivity`
- `System`
- `Widgets`
- `Other`

Choose one to three supported tags: `ai`, `bar`, `hyprland`, `launcher`,
`media`, `power-management`, `quickshell`, `security`, `system`, or
`workspaces`. A bar-widget starter would normally use category `Widgets` and
tags `bar, quickshell`.

## Submit

Use the marketplace issue form at
[omarchyplugins.com/publish.html](https://omarchyplugins.com/publish.html), or
follow its [CLI/AI submission guide](https://github.com/HANCORE-linux/omarchy-plugin-marketplace/blob/main/SUBMISSION.md).

The submission asks for the public repository root URL, category, tags,
optional maintainer notes, and five ownership/safety confirmations. Review and
approve those confirmations yourself before an agent creates an issue on your
behalf. A maintainer must approve the plugin after automated validation passes.


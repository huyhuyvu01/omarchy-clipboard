#!/usr/bin/env python3
"""Portable preflight checks for an Omarchy Quattro plugin repository."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path
from typing import Any


KIND_ENTRY_POINTS = {
    "bar": "bar",
    "bar-widget": "barWidget",
    "menu": "menu",
    "overlay": "overlay",
    "panel": "panel",
    "service": "service",
}
REQUIRED_FIELDS = (
    "id",
    "name",
    "version",
    "author",
    "description",
    "kinds",
    "entryPoints",
)
STRING_FIELDS = ("id", "name", "version", "author", "description")
ID_PATTERN = re.compile(r"^[a-z0-9][a-z0-9._-]*$")
LOCAL_TOOL_DIRS = {".agents", ".claude", ".codex", ".git"}


class ManifestError(ValueError):
    """Raised when the repository is not publishable as an Omarchy plugin."""


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ManifestError(message)


def load_manifest(plugin_dir: Path) -> dict[str, Any]:
    manifest_path = plugin_dir / "manifest.json"
    require(manifest_path.is_file(), f"missing root manifest: {manifest_path}")

    try:
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise ManifestError(f"manifest.json is not valid JSON: {error}") from error

    require(isinstance(manifest, dict), "manifest.json must contain an object")
    return manifest


def validate_identity(manifest: dict[str, Any]) -> None:
    for field in REQUIRED_FIELDS:
        require(field in manifest, f"manifest missing required field '{field}'")

    for field in STRING_FIELDS:
        value = manifest[field]
        require(isinstance(value, str) and value.strip(), f"'{field}' must be a non-empty string")

    plugin_id = manifest["id"]
    require(ID_PATTERN.fullmatch(plugin_id) is not None, f"invalid lowercase plugin id '{plugin_id}'")
    require(".." not in plugin_id, "plugin id may not contain '..'")
    require(not plugin_id.startswith("omarchy."), "the 'omarchy.*' namespace is reserved")
    require("." in plugin_id, "use a globally namespaced id such as io.github.handle.plugin")
    require(len(manifest["version"]) <= 64, "version must be at most 64 characters")


def validate_entry_points(plugin_dir: Path, manifest: dict[str, Any]) -> None:
    kinds = manifest["kinds"]
    require(isinstance(kinds, list) and kinds, "'kinds' must be a non-empty array")
    require(all(isinstance(kind, str) for kind in kinds), "every plugin kind must be a string")
    require(len(kinds) == len(set(kinds)), "plugin kinds must not contain duplicates")

    unknown = sorted(set(kinds) - set(KIND_ENTRY_POINTS))
    require(not unknown, f"unsupported plugin kinds: {', '.join(unknown)}")

    entry_points = manifest["entryPoints"]
    require(isinstance(entry_points, dict), "'entryPoints' must be an object")

    for kind in kinds:
        key = KIND_ENTRY_POINTS[kind]
        require(key in entry_points, f"kind '{kind}' requires entryPoints.{key}")

    for key, relative_value in entry_points.items():
        require(isinstance(relative_value, str) and relative_value, f"entry point '{key}' must be a path string")
        require("\n" not in relative_value, f"entry point '{key}' may not contain a newline")
        require(not Path(relative_value).is_absolute(), f"entry point '{key}' must be relative")
        require(".." not in relative_value, f"entry point '{key}' may not contain '..'")

        entry_path = plugin_dir / relative_value
        require(entry_path.is_file(), f"entry point file not found: {relative_value}")
        require(not entry_path.is_symlink(), f"entry point may not be a symlink: {relative_value}")


def validate_bar_widget(manifest: dict[str, Any]) -> None:
    metadata = manifest.get("barWidget")
    if metadata is None:
        return

    require(isinstance(metadata, dict), "'barWidget' must be an object")
    section = metadata.get("defaultSection")
    if section is not None:
        require(section in {"left", "center", "right"}, "barWidget.defaultSection must be left, center, or right")

    schema = metadata.get("schema", [])
    require(isinstance(schema, list), "barWidget.schema must be an array")
    schema_keys: list[str] = []
    for index, field in enumerate(schema):
        require(isinstance(field, dict), f"barWidget.schema[{index}] must be an object")
        require(isinstance(field.get("key"), str) and field["key"], f"barWidget.schema[{index}] needs a key")
        require(isinstance(field.get("type"), str) and field["type"], f"barWidget.schema[{index}] needs a type")
        schema_keys.append(field["key"])
    require(len(schema_keys) == len(set(schema_keys)), "barWidget.schema keys must be unique")


def validate_repository_files(plugin_dir: Path) -> None:
    readmes = [plugin_dir / "README.md", plugin_dir / "README"]
    licenses = [plugin_dir / name for name in ("LICENSE", "LICENSE.md", "COPYING")]
    require(any(path.is_file() for path in readmes), "missing root README")
    require(any(path.is_file() for path in licenses), "missing root license file")

    for path in plugin_dir.rglob("*"):
        try:
            relative = path.relative_to(plugin_dir)
        except ValueError:
            continue
        # These folders are ignored workspace tooling, not files that ship in
        # the GitHub repository or land in a user's Omarchy plugin checkout.
        if relative.parts and relative.parts[0] in LOCAL_TOOL_DIRS:
            continue
        require(not path.is_symlink(), f"symlinks are not allowed inside a plugin: {relative}")


def validate(plugin_dir: Path) -> dict[str, Any]:
    plugin_dir = plugin_dir.resolve()
    require(plugin_dir.is_dir(), f"plugin folder not found: {plugin_dir}")
    manifest = load_manifest(plugin_dir)
    require(manifest.get("schemaVersion") == 1, "schemaVersion must be the JSON number 1")
    validate_identity(manifest)
    validate_entry_points(plugin_dir, manifest)
    validate_bar_widget(manifest)
    validate_repository_files(plugin_dir)
    return manifest


def main(argv: list[str]) -> int:
    plugin_dir = Path(argv[1]) if len(argv) > 1 else Path.cwd()
    try:
        manifest = validate(plugin_dir)
    except ManifestError as error:
        print(f"validate_manifest: {error}", file=sys.stderr)
        return 1

    print(f"validated {manifest['id']} ({', '.join(manifest['kinds'])})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))

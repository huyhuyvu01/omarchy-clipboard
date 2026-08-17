import json
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


class ClipboardPluginTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.manifest = json.loads((ROOT / "manifest.json").read_text(encoding="utf-8"))
        cls.widget_qml = (ROOT / "BarWidget.qml").read_text(encoding="utf-8")
        cls.panel_qml = (ROOT / "Panel.qml").read_text(encoding="utf-8")

    def test_qml_identity_matches_manifest(self):
        identity = f'moduleName: "{self.manifest["id"]}"'
        self.assertIn(identity, self.widget_qml)
        self.assertIn(identity, self.panel_qml)

    def test_widget_opens_panel_on_left_click(self):
        self.assertIn("mouseButton === Qt.LeftButton", self.widget_qml)
        self.assertIn("root.toggle()", self.widget_qml)
        self.assertIn('source: Qt.resolvedUrl("Panel.qml")', self.widget_qml)

    def test_panel_uses_omarchy_clipboard_storage_and_helpers(self):
        self.assertIn("clipboard-history.json", self.panel_qml)
        self.assertIn("omarchy-clipboard-paste-text", self.panel_qml)
        self.assertIn("omarchy-clipboard-paste-file", self.panel_qml)
        self.assertIn("omarchy-clipboard-open", self.panel_qml)
        self.assertNotIn("wl-paste", self.panel_qml)

    def test_manifest_defaults_are_used_by_qml(self):
        qml = self.widget_qml + self.panel_qml
        defaults = self.manifest["barWidget"]["defaults"]
        for key in defaults:
            self.assertIn(f'setting("{key}"', qml)

    def test_manifest_schema_covers_defaults(self):
        metadata = self.manifest["barWidget"]
        schema_keys = {field["key"] for field in metadata["schema"]}
        self.assertEqual(set(metadata["defaults"]), schema_keys)


if __name__ == "__main__":
    unittest.main()

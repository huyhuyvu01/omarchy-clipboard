import json
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


class StarterPluginTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.manifest = json.loads((ROOT / "manifest.json").read_text(encoding="utf-8"))
        cls.qml = (ROOT / "BarWidget.qml").read_text(encoding="utf-8")

    def test_qml_identity_matches_manifest(self):
        self.assertIn(f'moduleName: "{self.manifest["id"]}"', self.qml)

    def test_manifest_defaults_are_used_by_qml(self):
        defaults = self.manifest["barWidget"]["defaults"]
        for key in defaults:
            self.assertIn(f'setting("{key}"', self.qml)

    def test_manifest_schema_covers_defaults(self):
        metadata = self.manifest["barWidget"]
        schema_keys = {field["key"] for field in metadata["schema"]}
        self.assertEqual(set(metadata["defaults"]), schema_keys)


if __name__ == "__main__":
    unittest.main()


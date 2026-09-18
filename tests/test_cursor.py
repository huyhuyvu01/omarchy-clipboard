import importlib.util
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("cursor_context", ROOT / "scripts/cursor-context.py")
context = importlib.util.module_from_spec(spec)
spec.loader.exec_module(context)


class CursorContextTests(unittest.TestCase):
  def test_negative_monitor_origin_and_original_window(self):
    monitors = [{"name": "left", "x": -1920, "y": 200,
                 "width": 1920, "height": 1080, "scale": 1}]
    self.assertEqual(context.cursor_context({"address": "0x123"}, {"x": -100, "y": 300}, monitors),
                     {"screen": "left", "x": 1820, "y": 100, "address": "0x123"})

  def test_scaled_rotated_monitor_uses_logical_bounds(self):
    monitors = [{"name": "portrait", "x": 0, "y": 0,
                 "width": 3840, "height": 2160, "scale": 2, "transform": 1}]
    self.assertEqual(context.cursor_context({}, {"x": 1079, "y": 1919}, monitors)["screen"], "portrait")
    with self.assertRaises(ValueError):
      context.cursor_context({}, {"x": 1080, "y": 100}, monitors)

  def test_shared_edge_selects_next_monitor(self):
    monitors = [{"name": "left", "x": -1920, "y": 0, "width": 1920, "height": 1080},
                {"name": "right", "x": 0, "y": 0, "width": 1920, "height": 1080}]
    self.assertEqual(context.cursor_context({}, {"x": 0, "y": 0}, monitors)["screen"], "right")


class PasteDestinationTests(unittest.TestCase):
  def run_paste(self, actual_address):
    with tempfile.TemporaryDirectory() as tmp:
      directory = Path(tmp)
      hyprctl = directory / "hyprctl"
      hyprctl.write_text('#!/bin/bash\nif [[ $1 == dispatch ]]; then\n'
                         '  printf "%s\\n" "$@" > "$CALL_LOG"\n'
                         'else\n  printf \'{"address":"%s"}\\n\' "$ACTUAL_ADDRESS"\nfi\n')
      hyprctl.chmod(0o755)
      marker = directory / "pasted"
      env = dict(os.environ, PATH=tmp + os.pathsep + os.environ["PATH"],
                 ACTUAL_ADDRESS=actual_address, CALL_LOG=str(directory / "calls"))
      result = subprocess.run(["bash", str(ROOT / "scripts/paste-to-window"), "0x123",
                               "touch", str(marker)], env=env, capture_output=True)
      return result.returncode, marker.exists(), (directory / "calls").read_text()

  def test_refocuses_original_window_before_pasting(self):
    code, pasted, calls = self.run_paste("0x123")
    self.assertEqual(code, 0)
    self.assertTrue(pasted)
    self.assertEqual(calls, 'dispatch\nhl.dsp.focus({ window = "address:0x123" })\n')

  def test_closed_destination_does_not_paste_into_another_window(self):
    code, pasted, _ = self.run_paste("0x456")
    self.assertNotEqual(code, 0)
    self.assertFalse(pasted)

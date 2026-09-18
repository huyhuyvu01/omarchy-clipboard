"""Capture the paste destination and cursor in monitor-local logical coordinates."""

import json
import subprocess


def query(name):
  return json.loads(subprocess.check_output(["hyprctl", "-j", name], text=True))


def cursor_context(window, cursor, monitors):
  for monitor in monitors:
    width, height = monitor["width"], monitor["height"]
    if monitor.get("transform", 0) % 2:
      width, height = height, width
    scale = monitor.get("scale", 1)
    x, y = cursor["x"] - monitor["x"], cursor["y"] - monitor["y"]
    if 0 <= x < width / scale and 0 <= y < height / scale:
      return {"screen": monitor["name"], "x": x, "y": y,
              "address": window.get("address", "")}
  raise ValueError("Cursor is outside the available monitors")


if __name__ == "__main__":
  print(json.dumps(cursor_context(query("activewindow"), query("cursorpos"), query("monitors"))))

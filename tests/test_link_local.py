import json
import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
PLUGIN_ID = json.loads((ROOT / "manifest.json").read_text(encoding="utf-8"))["id"]


class LinkLocalTests(unittest.TestCase):
    def run_link_local(self, checkout, home, bin_dir, *arguments):
        env = os.environ.copy()
        env["HOME"] = str(home)
        env["XDG_CONFIG_HOME"] = str(home / ".config")
        env["PATH"] = f"{bin_dir}:{env['PATH']}"
        env["LINK_LOCAL_LOG"] = str(home / "commands.log")
        return subprocess.run(
            [checkout / "scripts" / "link-local", *arguments],
            cwd=checkout,
            env=env,
            text=True,
            capture_output=True,
            check=False,
        )

    def test_reload_disables_unlinks_relinks_and_enables(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            home = Path(temporary_directory)
            checkout = home / "checkout"
            (checkout / "scripts").mkdir(parents=True)
            shutil.copy2(ROOT / "scripts" / "link-local", checkout / "scripts" / "link-local")
            shutil.copy2(ROOT / "manifest.json", checkout / "manifest.json")
            check = checkout / "scripts" / "check"
            check.write_text("#!/bin/bash\nexit 0\n", encoding="utf-8")
            check.chmod(0o755)

            target = home / ".config" / "omarchy" / "plugins" / PLUGIN_ID
            target.parent.mkdir(parents=True)
            target.symlink_to(checkout)

            bin_dir = home / "bin"
            bin_dir.mkdir()
            for command in ("omarchy", "omarchy-shell"):
                executable = bin_dir / command
                executable.write_text(
                    "#!/bin/bash\n"
                    'printf "%s %s\\n" "$(basename "$0")" "$*" >> "$LINK_LOCAL_LOG"\n'
                    'if [[ $(basename "$0") == omarchy && ${1:-} == plugin '
                    '&& ${2:-} == remove ]]; then\n'
                    '  unlink "$XDG_CONFIG_HOME/omarchy/plugins/$3"\n'
                    "fi\n",
                    encoding="utf-8",
                )
                executable.chmod(0o755)

            result = self.run_link_local(checkout, home, bin_dir, "--reload")

            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertTrue(target.is_symlink())
            self.assertEqual(target.resolve(), checkout.resolve())
            self.assertEqual(
                (home / "commands.log").read_text(encoding="utf-8").splitlines(),
                [
                    f"omarchy plugin disable {PLUGIN_ID}",
                    f"omarchy plugin remove {PLUGIN_ID} --yes",
                    "omarchy-shell shell rescanPlugins",
                    f"omarchy plugin enable {PLUGIN_ID}",
                ],
            )


if __name__ == "__main__":
    unittest.main()

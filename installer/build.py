"""Build on the target OS, after installing PyInstaller."""
from pathlib import Path
import subprocess
import sys

root = Path(__file__).resolve().parent
subprocess.run([sys.executable, str(root/'prepare_build.py')], check=True)
sep = ';' if sys.platform == 'win32' else ':'
args = [sys.executable, '-m', 'PyInstaller', '--clean', '--noconfirm', '--onefile',
        '--windowed', '--name', 'PGM-Installer', '--paths', str(root),
        '--distpath', str(root / 'dist'), '--workpath', str(root / 'build'),
        '--specpath', str(root / 'build'),
        '--add-data', str(root / 'preparer-variantes.py') + sep + '.',
        '--add-data', str(root / 'presets') + sep + 'presets',
        '--hidden-import', 'argparse', '--hidden-import', 'stat', '--hidden-import', 'shutil']
if sys.platform == 'linux':
    args += ['--hidden-import', 'fcntl', '--hidden-import', 'csv', '--hidden-import', 'uuid', '--hidden-import', 'struct', '--hidden-import', 'linux_upgrade', '--add-data', str(root / 'traduction-linux') + sep + 'traduction-linux']
if (root / 'traduction-windows').exists():
    args += ['--add-data', str(root / 'traduction-windows') + sep + 'traduction-windows']
subprocess.run(args + [str(root / 'app.py')], check=True, cwd=root)

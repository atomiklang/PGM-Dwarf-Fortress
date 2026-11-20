"""Smoke-test the frozen application and create end-user downloads."""
import hashlib
import os
from pathlib import Path
import platform
import shutil
import subprocess
import tarfile
from core import VERSION
from smoke_gui import run as smoke_test
root = Path(__file__).resolve().parent
release = root / 'release'
release.mkdir(exist_ok=True)
windows = platform.system() == 'Windows'
exe = root / 'dist' / ('PGM-Installer.exe' if windows else 'PGM-Installer')
command = [str(exe), '--smoke-test']
smoke_test(command)
name = f'PGM-Installer-Windows-{VERSION}.exe' if windows else f'PGM-Installer-Linux-{VERSION}.bin'
target = release / name
shutil.copy2(exe, target)
if not windows:
    target.chmod(0o755)
    with tarfile.open(release / f'PGM-Installer-Linux-{VERSION}.tar.gz', 'w:gz') as archive:
        archive.add(target, arcname='PGM-Installer')
        archive.add(root / 'LISEZMOI.txt', arcname='LISEZMOI.txt')
filename = 'SHA256SUMS-Windows.txt' if windows else 'SHA256SUMS-Linux.txt'
(release / filename).write_text(''.join(hashlib.sha256(p.read_bytes()).hexdigest() + '  ' + p.name + '\n'
                                       for p in sorted(release.iterdir()) if p.is_file() and not p.name.startswith('SHA256SUMS')), encoding='utf-8')

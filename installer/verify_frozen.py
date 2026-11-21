"""Verify actual bundled data, not just the source folder used for a build."""
from pathlib import Path
import hashlib,json,sys
from PyInstaller.archive.readers import CArchiveReader
root=Path(__file__).resolve().parent
exe=Path(sys.argv[1]) if len(sys.argv)>1 else root/'dist'/('PGM-Installer.exe' if sys.platform == 'win32' else 'PGM-Installer')
receipt=json.loads((root/'BUNDLE.json').read_text())
reader=CArchiveReader(str(exe))
for name,expected in receipt['files'].items():
    if sys.platform == 'win32' and name.startswith('traduction-linux/'):
        continue
    data=reader.extract(str(Path(name)))
    if hashlib.sha256(data).hexdigest()!=expected:raise ValueError('Bundled data mismatch: '+name)
print('Frozen executable matches all',sum(not (sys.platform == 'win32' and n.startswith('traduction-linux/')) for n in receipt['files']),'bundled data files.')

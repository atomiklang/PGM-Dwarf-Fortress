"""Fetch immutable beta payloads, verifying pinned SHA-256 before extraction."""
import hashlib
import io
from pathlib import Path, PurePosixPath
import urllib.request
import zipfile
ROOT = Path(__file__).resolve().parent
PACKAGES = [
    ('PGM-Linux-0.1.0-beta.3.zip', '39076070a871c20dd044721b0149210664494d6f90f0c22df2d0a8a1efc1b9de', 'linux'),
    ('PGM-Installation-0.1.0-beta.3.zip', 'c4a28e0984c6ade1922e0163a951b034ae2cdbecc716003aa03cd558c7286914', 'common'),
]

def main():
    for name, expected, kind in PACKAGES:
        url = 'https://github.com/atomiklang/PGM-Dwarf-Fortress/releases/download/v0.1.0-beta.3/' + name
        with urllib.request.urlopen(url, timeout=60) as response:
            data = response.read(64 * 1024 * 1024)
        if hashlib.sha256(data).hexdigest() != expected:
            raise ValueError('Invalid pinned package: ' + name)
        with zipfile.ZipFile(io.BytesIO(data)) as archive:
            total = 0
            for entry in archive.infolist():
                parts = PurePosixPath(entry.filename).parts
                if entry.is_dir():
                    continue
                if not parts or '..' in parts or PurePosixPath(entry.filename).is_absolute() or '\\' in entry.filename:
                    raise ValueError('Unsafe archive path')
                if kind == 'linux':
                    if parts[0] != 'PGM-Linux-0.1.0-beta.3':
                        raise ValueError('Unexpected archive root')
                    target = ROOT / 'traduction-linux' / Path(*parts[1:])
                elif entry.filename == 'preparer-variantes.py' or entry.filename.startswith('presets/'):
                    target = ROOT / Path(*parts)
                else:
                    continue
                total += entry.file_size
                if total > 64 * 1024 * 1024 or ((entry.external_attr >> 16) & 0o170000) == 0o120000:
                    raise ValueError('Unsafe archive entry')
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_bytes(archive.read(entry))
if __name__ == '__main__':
    main()

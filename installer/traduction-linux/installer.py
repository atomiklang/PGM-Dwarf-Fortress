#!/usr/bin/env python3
"""Install the PGM Linux translation using DFHack's existing hook chainloader."""
import argparse
import csv
import fcntl
import hashlib
import io
import json
import os
from pathlib import Path
import re
import struct
import sys
import tempfile
import uuid

ROOT = Path(__file__).resolve().parent
STATE_DIR = '.pgm-linux-install'
BEGIN = '# BEGIN PGM LINUX TRANSLATION'
END = '# END PGM LINUX TRANSLATION'
SIGNATURES = {
    0x14138e0: bytes.fromhex('41554c8d6f10415455534883ec084c892f4885f6'),
    0x1d2aa10: bytes.fromhex('f30f1efa4157415641554154'),
    0x83bed0: bytes.fromhex('f30f1efa41554989f541544989fc'),
    0xb0a1e0: bytes.fromhex('f30f1efa415641554989f54154'),
}

PAYLOAD_FILES = {
    'libdfhooks_traducfr.so',
    'traducfr/dictionnaire.csv', 'traducfr/corrections_fr.csv',
    'traducfr/modeles.txt', 'traducfr/reglages.txt',
    'dfhack-config/scripts/traducfr-dfhack.lua',
    'dfhack-config/scripts/traducfr-fps.lua',
}
MANAGED_FILES = PAYLOAD_FILES | {
    'libdfhooks.so', 'dfhooks_dfhack.ini', 'dfhack-config/init/dfhack.init',
}


def read_manifest():
    manifest = json.loads((ROOT / 'payload-sha256.json').read_text())
    if not isinstance(manifest, dict) or set(manifest) != PAYLOAD_FILES:
        raise ValueError('Unexpected files in the payload manifest.')
    for name, value in manifest.items():
        if not isinstance(value, str) or not re.fullmatch(r'[0-9a-f]{64}', value):
            raise ValueError(f'Invalid payload digest: {name}')
        checked_target(ROOT / 'payload', name)
    return manifest


def read_state(game):
    path = checked_target(game, STATE_DIR + '/state.json')
    state = json.loads(path.read_text())
    validate_state(state)
    return state


def validate_state(state):
    if not isinstance(state, dict) or state.get('phase') not in ('installing', 'installed'):
        raise ValueError('Invalid installation state.')
    if not isinstance(state.get('backup'), str) or not re.fullmatch(r'[0-9a-f]{32}', state['backup']):
        raise ValueError('Invalid backup identifier.')
    files = state.get('files')
    if not isinstance(files, dict) or set(files) != MANAGED_FILES:
        raise ValueError('Unexpected files in installation state.')
    for name, record in files.items():
        if not isinstance(record, dict):
            raise ValueError(f'Invalid state for {name}')
        for key in ('original', 'installed'):
            value = record.get(key)
            if key == 'original' and value is None:
                continue
            if not isinstance(value, str) or not re.fullmatch(r'[0-9a-f]{64}', value):
                raise ValueError(f'Invalid digest in state for {name}')
        mode = record.get('mode')
        if type(mode) is not int or not 0 <= mode <= 0o777:
            raise ValueError(f'Invalid mode in state for {name}')


def digest(data):
    return hashlib.sha256(data).hexdigest()


def elf_header(path):
    with path.open('rb') as file:
        head = file.read(64)
    if len(head) < 64 or head[:6] != b'\x7fELF\x02\x01' or struct.unpack_from('<H', head, 18)[0] != 62:
        raise ValueError(f'Expected a Linux x86-64 ELF file: {path}')
    return head


def check_game(game):
    exe = game / 'dwarfort'
    if not exe.exists() and (game / 'Dwarf Fortress.exe').exists():
        raise ValueError('Steam currently has the Windows game. Select the native Linux version before installing this package.')
    head = elf_header(exe)
    if struct.unpack_from('<H', head, 16)[0] != 2:
        raise ValueError('This hook requires the fixed-address Linux 53.17 executable.')
    phoff = struct.unpack_from('<Q', head, 32)[0]
    size, count = struct.unpack_from('<HH', head, 54)
    if size < 56 or count > 256:
        raise ValueError('Unsupported ELF program headers.')
    segments = []
    with exe.open('rb') as file:
        for index in range(count):
            file.seek(phoff + index * size)
            record = file.read(56)
            if len(record) != 56:
                raise ValueError('Incomplete ELF program headers.')
            kind, flags, offset, address, _, length, _, _ = struct.unpack('<IIQQQQQQ', record)
            if kind == 1 and flags & 1:
                segments.append((offset, address, length))
        for address, expected in SIGNATURES.items():
            segment = next((s for s in segments if s[1] <= address and address + len(expected) <= s[1] + s[2]), None)
            if segment is None:
                raise ValueError('The game executable does not match the supported Linux build.')
            file.seek(segment[0] + address - segment[1])
            if file.read(len(expected)) != expected:
                raise ValueError(f'Unsupported game build at 0x{address:x}. No installation performed.')
    if not (game / 'libg_src_lib.so').is_file():
        raise ValueError('Missing Linux graphics library libg_src_lib.so.')
    check_not_running(game)
    if (game / 'libdfhooks_dfint.so').exists():
        raise ValueError('An existing DFint hook requires manual configuration before installing PGM.')
    return exe


def check_not_running(game):
    for process in Path('/proc').iterdir():
        if process.name.isdigit():
            try:
                if (process / 'exe').resolve() == (game / 'dwarfort').resolve():
                    raise ValueError('Close Dwarf Fortress before modifying the translation.')
            except (OSError, RuntimeError):
                pass

def checked_target(game, relative):
    relative = Path(relative)
    if relative.is_absolute() or not relative.parts or '..' in relative.parts:
        raise ValueError(f'Invalid relative path: {relative}')
    target = game / relative
    current = game
    for component in relative.parts:
        current = current / component
        if current.is_symlink():
            raise ValueError(f'Preserve the existing symbolic link before installing: {current}')
    if not target.resolve().is_relative_to(game.resolve()):
        raise ValueError(f'Target escapes the game directory: {target}')
    if target.exists() and not target.is_file():
        raise ValueError(f'Expected a regular file: {target}')
    return target


def atomic_write(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    descriptor, temporary = tempfile.mkstemp(prefix='.pgm-', dir=path.parent)
    try:
        with os.fdopen(descriptor, 'wb') as file:
            file.write(data)
            file.flush()
            os.fsync(file.fileno())
        os.replace(temporary, path)
    finally:
        Path(temporary).unlink(missing_ok=True)


def save_state(game, state):
    atomic_write(checked_target(game, STATE_DIR + '/state.json'), json.dumps(state, indent=2).encode())


def make_plan(game, dfhack):
    check_game(game)
    for ini in game.glob('*dfhooks*.ini'):
        if 'libdfhooks_traducfr.so' in ini.read_text(errors='replace'):
            raise ValueError(f'Existing PGM hook indirection would load the library twice: {ini}')
    payload = ROOT / 'payload'
    manifest = read_manifest()
    files = {}
    for name, expected in manifest.items():
        data = (payload / name).read_bytes()
        if digest(data) != expected:
            raise ValueError(f'Damaged package file: {name}')
        files[name] = data
    dictionary = files['traducfr/dictionnaire.csv'].decode('cp850')
    if len(list(csv.reader(io.StringIO(dictionary)))) < 1000:
        raise ValueError('Translation dictionary is incomplete.')
    candidates = [dfhack] if dfhack else [game, game.parent / 'DFHack']
    loader = next((root / 'libdfhooks.so' for root in candidates if root and (root / 'libdfhooks.so').is_file()), None)
    if loader is None:
        raise ValueError('Install DFHack Linux first, or supply --dfhack /path/to/DFHack.')
    elf_header(loader)
    loader_data = loader.read_bytes()
    if b'libdfhooks_' not in loader_data:
        raise ValueError('The installed libdfhooks.so is not the expected chainloader.')
    if (game / 'libdfhooks.so').exists() and (game / 'libdfhooks.so').read_bytes() != loader_data:
        raise ValueError('An existing different hook loader requires manual configuration.')
    files['libdfhooks.so'] = loader_data
    hack_roots = [game, dfhack, game.parent / 'DFHack']
    hack = next((root / 'hack/libdfhooks_dfhack.so' for root in hack_roots if root and (root / 'hack/libdfhooks_dfhack.so').is_file()), None)
    if hack is None:
        raise ValueError('DFHack Linux library missing. Supply --dfhack /path/to/DFHack.')
    elf_header(hack)
    files['dfhooks_dfhack.ini'] = (str(hack.resolve()) + '\n').encode()
    init = checked_target(game, 'dfhack-config/init/dfhack.init')
    data = init.read_bytes() if init.exists() else b''
    if BEGIN.encode() in data or END.encode() in data:
        raise ValueError('Existing PGM initialization block found without a matching installation state.')
    # Reuse an existing standalone initialization line when upgrading the local setup.
    lines = data.splitlines()
    if not any(line.strip() == b'traducfr-dfhack' for line in lines):
        data += (b'\n' if data and not data.endswith(b'\n') else b'')
        data += (BEGIN + '\ntraducfr-dfhack\n' + END + '\n').encode()
    files['dfhack-config/init/dfhack.init'] = data
    for name in files:
        checked_target(game, name)
    return files


def restore(game, state):
    validate_state(state)
    backup = game / STATE_DIR / 'backups' / state['backup']
    for name, record in state['files'].items():
        path = checked_target(game, name)
        current = digest(path.read_bytes()) if path.exists() else None
        if current not in (record['original'], record['installed']):
            raise ValueError(f'File modified since installation. Preserve it before restoring: {path}')
        if record['original'] is not None:
            original = checked_target(game, str((backup / name).relative_to(game))).read_bytes()
            if digest(original) != record['original']:
                raise ValueError(f'Invalid backup: {name}')
    for name, record in reversed(list(state['files'].items())):
        path = checked_target(game, name)
        if record['original'] is None:
            path.unlink(missing_ok=True)
        else:
            atomic_write(path, checked_target(game, str((backup / name).relative_to(game))).read_bytes())
            path.chmod(record['mode'])
    (game / STATE_DIR / 'state.json').unlink()
    print('Previous files restored. Backups retained in', backup)


def install(game, dfhack):
    state_file = checked_target(game, STATE_DIR + '/state.json')
    if state_file.exists():
        state = read_state(game)
        if state['phase'] != 'installed':
            raise ValueError('An interrupted installation exists. Run uninstall to restore it first.')
        plan = make_plan_without_init(game, dfhack)
        if all(checked_target(game, name).exists() and digest(checked_target(game, name).read_bytes()) == digest(data) for name, data in plan.items()):
            print('PGM Linux translation is already installed and matches this package.')
            return
        raise ValueError('An installation already exists. Uninstall it before upgrading.')
    files = make_plan(game, dfhack)
    token = uuid.uuid4().hex
    backup = game / STATE_DIR / 'backups' / token
    state = {'phase': 'installing', 'backup': token, 'files': {}}
    for name, data in files.items():
        target = checked_target(game, name)
        original = target.read_bytes() if target.exists() else None
        mode = target.stat().st_mode & 0o777 if target.exists() else 0o644
        if original is not None:
            atomic_write(checked_target(game, str((backup / name).relative_to(game))), original)
        state['files'][name] = {'original': digest(original) if original is not None else None, 'installed': digest(data), 'mode': mode}
    save_state(game, state)
    try:
        for name, data in files.items():
            target = checked_target(game, name)
            atomic_write(target, data)
            target.chmod(state['files'][name]['mode'])
        state['phase'] = 'installed'
        save_state(game, state)
    except Exception:
        restore(game, state)
        raise
    print('Installed PGM Linux translation. Launch the game through Steam with DFHack.')
    print('F12 or Ctrl+Alt+F (or the DFHack command traduction-switch) switches FR/EN. Check traducfr/traducfr.log after startup.')


def make_plan_without_init(game, dfhack):
    # The installed block already belongs to this package. Validate all other files.
    state = read_state(game)
    check_game(game)
    manifest = read_manifest()
    files = {name: (ROOT / 'payload' / name).read_bytes() for name in manifest}
    for name, data in files.items():
        if digest(data) != manifest[name]:
            raise ValueError(f'Damaged package file: {name}')
    for name, record in state['files'].items():
        if name not in files:
            path = checked_target(game, name)
            if not path.exists() or digest(path.read_bytes()) != record['installed']:
                raise ValueError(f'Installed file has changed: {name}')
    return files


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=['check', 'install', 'uninstall', 'status'])
    parser.add_argument('--game', required=True, type=Path)
    parser.add_argument('--dfhack', type=Path)
    args = parser.parse_args()
    game = args.game.expanduser().resolve()
    if args.dfhack:
        args.dfhack = args.dfhack.expanduser().resolve()
    if os.geteuid() == 0:
        raise ValueError('Run this installer as the game owner, without sudo.')
    if sys.platform != 'linux':
        raise ValueError('This installer is for Linux native Dwarf Fortress.')
    if args.action in ('install', 'uninstall'):
        lock_path = checked_target(game, STATE_DIR + '/install.lock')
        lock_path.parent.mkdir(parents=True, exist_ok=True)
        descriptor = os.open(lock_path, os.O_CREAT | os.O_RDWR | os.O_NOFOLLOW, 0o600)
        lock = os.fdopen(descriptor, 'a')
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
    if args.action == 'install':
        install(game, args.dfhack)
    elif args.action == 'check':
        files = (make_plan_without_init(game, args.dfhack)
                 if (game / STATE_DIR / 'state.json').exists()
                 else make_plan(game, args.dfhack))
        print('Linux build and package verified.', len(files), 'files ready. No game files changed.')
    elif args.action == 'status':
        path = checked_target(game, STATE_DIR + '/state.json')
        print(json.dumps(read_state(game), indent=2) if path.exists() else 'PGM Linux translation is not managed by this installer.')
    else:
        check_not_running(game)
        path = checked_target(game, STATE_DIR + '/state.json')
        if not path.exists():
            print('No installation to restore.')
            return
        restore(game, read_state(game))


if __name__ == '__main__':
    try:
        main()
    except (OSError, ValueError, KeyError) as error:
        print('PGM:', error, file=sys.stderr)
        sys.exit(1)

"""Optional DFHack feature; no downloads, process launch, or writes at import.

Call inspect before presenting the option. install/uninstall require a caller's
process check (raise or return False when running/unknown). Roots are explicit;
hack_root is DFHack's hack directory, which may be outside the game directory.
"""
import hashlib
import json
import os
from pathlib import Path
import shutil
import tempfile

COMMON = (
    'dfhack-config/scripts/gui/worldmap-zoom.lua',
    'dfhack-config/scripts/worldmap-zoom.lua',
    'hack/lua/plugins/worldmap-zoom-render.lua',
    'hack/lua/worldmap-zoom/camera.lua',
    'hack/lua/worldmap-zoom/context.lua',
    'hack/lua/worldmap-zoom/gesture.lua',
    'hack/lua/worldmap-zoom/input.lua',
    'hack/lua/worldmap-zoom/ui.lua',
    'dfhack-config/scripts/pgm-worldmap-auto.lua',
    'dfhack-config/init/dfhack.pgm-worldmap-auto.init',
    'hack/lua/pgm/boucle.lua',
)
STATE = '.pgm-worldmap-navigation'
CONTRACT = Path(__file__).with_name('installation-contract.json')


class Refused(ValueError):
    pass


def digest(data):
    return hashlib.sha256(data).hexdigest()


def safe(path):
    """Reject links at every existing component, including dangling links."""
    path = Path(os.path.abspath(path))
    for item in (path, *path.parents):
        try:
            attributes = item.lstat()
        except FileNotFoundError:
            continue
        if item.is_symlink() or getattr(attributes, 'st_file_attributes', 0) & 0x400:
            raise Refused('Symbolic link or Windows reparse point refused: ' + str(item))
    return path


def read(path):
    path = safe(path)
    if not path.is_file() or path.stat().st_nlink != 1:
        raise Refused('Expected a regular, unshared file: ' + str(path))
    return path.read_bytes()


def contract(platform):
    data = json.loads(read(CONTRACT))
    if platform not in ('linux', 'windows'):
        raise Refused('Explicit platform linux/windows required')
    selected = data['platforms'][platform]
    if not selected['available']:
        raise Refused('Windows plugin unavailable; Linux fallback forbidden')
    expected = set(COMMON) | {'hack/plugins/worldmap-zoom-render.plug.' + ('so' if platform == 'linux' else 'dll')}
    if set(selected['files']) != expected:
        raise Refused('Payload allowlist mismatch')
    for name, entry in selected['files'].items():
        expected_source = 'output/' + Path(name).name if name.endswith(('.so', '.dll')) else 'source/' + name
        if entry['source'] != expected_source:
            raise Refused('Payload source path outside allowlist')
    return selected


def roots(game_root, hack_root):
    game, hack = safe(game_root), safe(hack_root)
    if not game.is_dir() or not hack.is_dir() or game == hack:
        raise Refused('Existing distinct game and hack directories required')
    return game, hack


def target(game, hack, relative):
    return safe(hack / relative[5:] if relative.startswith('hack/') else game / relative)


def inspect(game_root, hack_root, platform='linux', payload_root=None):
    """Read-only preflight. Hashes pin the tested runtime; no ABI promise inferred."""
    selected = contract(platform)
    game, hack = roots(game_root, hack_root)
    for name, checksum in selected['runtime'].items():
        if digest(read(target(game, hack, name))) != checksum:
            raise Refused('Unknown game/DFHack runtime: ' + name)
    payload = Path(payload_root) if payload_root is not None else Path(__file__).parent.parent
    blobs = {}
    for name, entry in selected['files'].items():
        blob = read(safe(payload) / entry['source'])
        if digest(blob) != entry['sha256']:
            raise Refused('Payload hash mismatch: ' + name)
        blobs[name] = blob
    state = safe(game / STATE)
    if state.exists():
        raise Refused('Feature state already exists; uninstall first')
    existing = {}
    for name, entry in selected['files'].items():
        path = target(game, hack, name)
        if path.exists():
            blob = read(path)
            if digest(blob) not in entry['known_existing_sha256']:
                raise Refused('Unknown existing file protected: ' + name)
            existing[name] = blob
        else:
            existing[name] = None
    return {'game': game, 'hack': hack, 'platform': platform,
            'payload': blobs, 'existing': existing}


def closed(callback, game):
    if not callable(callback):
        raise Refused('A game_closed callback is required')
    if callback(game) is False:
        raise Refused('Game running or closure unknown')


def atomic(path, blob):
    path = safe(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, tmp = tempfile.mkstemp(prefix='.pgm-navigation-', dir=path.parent)
    try:
        with os.fdopen(fd, 'wb') as stream:
            stream.write(blob)
        os.replace(tmp, path)
    finally:
        Path(tmp).unlink(missing_ok=True)


def install(game_root, hack_root, *, game_closed, platform='linux', payload_root=None):
    closed(game_closed, safe(game_root))
    plan = inspect(game_root, hack_root, platform, payload_root)
    game, hack = plan['game'], plan['hack']
    state = game / STATE
    state.mkdir()  # Exclusive ownership; never reuse another operation's state.
    changed = []
    try:
        records = {}
        for index, (name, blob) in enumerate(plan['payload'].items()):
            old = plan['existing'][name]
            backup = str(index) + '.bin' if old is not None else None
            if backup:
                (state / backup).write_bytes(old)
            records[name] = {'installed': digest(blob), 'backup': backup,
                             'previous': digest(old) if old is not None else None}
        journal = {'schema': 1, 'platform': platform, 'game': str(game), 'hack': str(hack), 'files': records}
        atomic(state / 'state.json', json.dumps(journal, indent=2).encode())
        for name, blob in plan['payload'].items():
            path = target(game, hack, name)
            old = plan['existing'][name]
            # Recheck immediately before replacement; abort on intervening edits.
            if (read(path) if path.exists() else None) != old:
                raise Refused('Target changed during installation: ' + name)
            changed.append(name)
            atomic(path, blob)
    except Exception:
        for name in reversed(changed):
            path = target(game, hack, name)
            old = plan['existing'][name]
            atomic(path, old) if old is not None else path.unlink(missing_ok=True)
        shutil.rmtree(state)
        raise
    return {'installed': list(plan['payload']), 'state': str(state)}


def uninstall(game_root, hack_root, *, game_closed):
    game, hack = roots(game_root, hack_root)
    closed(game_closed, game)
    state = safe(game / STATE)
    journal = json.loads(read(state / 'state.json'))
    selected = contract(journal['platform'])
    if journal.get('schema') != 1 or journal['game'] != str(game) or journal['hack'] != str(hack) or set(journal['files']) != set(selected['files']):
        raise Refused('Installation state/root mismatch')
    originals, current = {}, {}
    for name, entry in journal['files'].items():
        current[name] = read(target(game, hack, name))
        if entry['installed'] not in selected['files'][name]['known_existing_sha256'] or digest(current[name]) != entry['installed']:
            raise Refused('Modified installed file protected: ' + name)
        backup = entry['backup']
        if backup is None:
            if entry['previous'] is not None:
                raise Refused('Invalid backup record')
            originals[name] = None
        else:
            if backup not in {str(i) + '.bin' for i in range(len(selected['files']))}:
                raise Refused('Invalid backup name')
            originals[name] = read(state / backup)
            checksum = digest(originals[name])
            if checksum != entry['previous'] or checksum not in selected['files'][name]['known_existing_sha256']:
                raise Refused('Backup hash mismatch')
    changed = []
    try:
        for name, blob in originals.items():
            path = target(game, hack, name)
            if read(path) != current[name]:
                raise Refused('Target changed during restoration')
            changed.append(name)
            atomic(path, blob) if blob is not None else path.unlink()
    except Exception:
        for name in reversed(changed):
            atomic(target(game, hack, name), current[name])
        raise
    # Never recursively delete user additions to the state directory.
    for entry in journal['files'].values():
        if entry['backup']:
            (state / entry['backup']).unlink()
    (state / 'state.json').unlink()
    if not any(state.iterdir()):
        state.rmdir()
    return {'restored': list(originals)}

"""PGM animations & speed module: installs pgm-motion (walking + work gestures) and the speed/FPS scripts.
Every replaced file is backed up byte for byte in <game>/.pgm-animations and restored on uninstall.
Refuses symlinks, unknown targets and a running game. No other file is touched."""
from pathlib import Path
import hashlib, json, os, shutil, tempfile

ROOT = Path(__file__).resolve().parent / 'animations'
SCRIPTS = {
    'hack/lua/pgm-fluidity/controller.lua': 'source/hack/lua/pgm-fluidity/controller.lua',
    'dfhack-config/scripts/pgm-fluidity.lua': 'source/dfhack-config/scripts/pgm-fluidity.lua',
    'dfhack-config/scripts/pgm-fluidity-start.lua': 'source/dfhack-config/scripts/pgm-fluidity-start.lua',
    'dfhack-config/init/onMapLoad.pgm-fluidity.init': 'source/dfhack-config/init/onMapLoad.pgm-fluidity.init',
}
STATE = '.pgm-animations'


def digest(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def files_for(system):
    plugin = ('hack/plugins/pgm-motion.plug.dll', 'windows/pgm-motion.plug.dll') if system == 'Windows' \
        else ('hack/plugins/pgm-motion.plug.so', 'linux/pgm-motion.plug.so')
    return dict(SCRIPTS, **{plugin[0]: plugin[1]})


def target(game, hack, relative):
    base, rel = (Path(hack), relative[5:]) if relative.startswith('hack/') else (Path(game), relative)
    dest = (base / rel)
    for p in [dest, *dest.parents]:
        if p.is_symlink():
            raise ValueError('Symbolic link refused: ' + str(p))
        if p == base:
            break
    if not dest.resolve().is_relative_to(base.resolve()):
        raise ValueError('Unsafe target: ' + relative)
    return dest


def _write(dest, data):
    dest.parent.mkdir(parents=True, exist_ok=True)
    fd, tmp = tempfile.mkstemp(prefix='.pgm-', dir=dest.parent)
    try:
        with os.fdopen(fd, 'wb') as f:
            f.write(data)
        os.replace(tmp, dest)
    finally:
        Path(tmp).unlink(missing_ok=True)


def check(game, hack, system):
    out = {}
    for rel, src in files_for(system).items():
        s = ROOT / src
        if not s.is_file():
            raise ValueError('Missing bundled file: ' + src)
        dest = target(game, hack, rel)
        out[rel] = 'up to date' if dest.is_file() and digest(dest) == digest(s) else ('replace' if dest.exists() else 'add')
    return out


def install(game, hack, system, game_closed):
    if game_closed(game) is False:
        raise ValueError('Close Dwarf Fortress first.')
    state = Path(game) / STATE
    journal_path = state / 'journal.json'
    journal = json.loads(journal_path.read_text()) if journal_path.is_file() else {'files': {}}
    state.mkdir(exist_ok=True)
    done = []
    try:
        for i, (rel, src) in enumerate(sorted(files_for(system).items())):
            dest = target(game, hack, rel)
            data = (ROOT / src).read_bytes()
            if rel not in journal['files']:
                backup = None
                if dest.is_file():
                    backup = f'{i}.bin'
                    shutil.copyfile(dest, state / backup)
                journal['files'][rel] = {'backup': backup}
            _write(dest, data)
            if digest(dest) != hashlib.sha256(data).hexdigest():
                raise ValueError('Readback mismatch: ' + rel)
            journal['files'][rel]['installed'] = hashlib.sha256(data).hexdigest()
            done.append(rel)
    finally:
        journal_path.write_text(json.dumps(journal, indent=2) + '\n')
    return done


def uninstall(game, hack, game_closed):
    if game_closed(game) is False:
        raise ValueError('Close Dwarf Fortress first.')
    state = Path(game) / STATE
    journal_path = state / 'journal.json'
    if not journal_path.is_file():
        raise ValueError('Nothing to restore.')
    journal = json.loads(journal_path.read_text())
    for rel, entry in journal['files'].items():
        dest = target(game, hack, rel)
        if dest.is_file() and digest(dest) != entry.get('installed'):
            raise ValueError('File changed since installation, left untouched: ' + rel)
        if entry['backup']:
            _write(dest, (state / entry['backup']).read_bytes())
        else:
            dest.unlink(missing_ok=True)
    shutil.rmtree(state)
    return list(journal['files'])

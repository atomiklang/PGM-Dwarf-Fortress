"""Conservative installation and restoration of the bundled DFHack presets."""
import base64
from contextlib import contextmanager
import hashlib
import json
import os
from pathlib import Path
import tempfile


def digest(data):
    return hashlib.sha256(data).hexdigest()


def target(game, relative):
    path = game
    for part in Path(relative).parts:
        path = path / part
        if path.is_symlink() or getattr(path.lstat() if path.exists() else None, 'st_file_attributes', 0) & 0x400:
            raise ValueError('Lien non pris en charge : ' + str(path))
    if path.exists() and not path.is_file():
        raise ValueError('Fichier attendu : ' + str(path))
    return path


def write(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, temp = tempfile.mkstemp(prefix='.pgm-', dir=path.parent)
    try:
        with os.fdopen(fd, 'wb') as file:
            file.write(data)
            file.flush()
            os.fsync(file.fileno())
        os.replace(temp, path)
    finally:
        Path(temp).unlink(missing_ok=True)


@contextmanager
def locked(game):
    path = target(game, '.pgm-presets.lock')
    try:
        fd = os.open(path, os.O_CREAT | os.O_EXCL | os.O_WRONLY, 0o600)
    except FileExistsError:
        raise ValueError('Une autre opération PGM est en cours. Si elle a été interrompue, conserver le rapport avant de retirer .pgm-presets.lock.')
    try:
        os.close(fd)
        yield
    finally:
        path.unlink(missing_ok=True)


def restore(game):
    game = Path(game)
    with locked(game):
        statefile = target(game, '.pgm-presets-state.json')
        if not statefile.exists():
            return 'Aucun preset à restaurer.'
        state = json.loads(statefile.read_text())
        path = target(game, 'dfhack-config/mod-manager.json')
        current = path.read_bytes() if path.exists() else None
        original = base64.b64decode(state['original'], validate=True) if state['original'] is not None else None
        if state.get('format') != 1 or (original is not None and digest(original) != state['original_hash']):
            raise ValueError('Sauvegarde des presets invalide.')
        if current is not None and digest(current) not in (state['installed_hash'], state['original_hash']):
            raise ValueError('Les presets ont été modifiés depuis l’installation. Ils sont conservés ; fusion manuelle nécessaire.')
        if original is None:
            path.unlink(missing_ok=True)
        else:
            write(path, original)
        statefile.unlink()
    return 'Presets précédents restaurés.'


def install(game, bundled):
    game = Path(game)
    incoming = json.loads(Path(bundled).read_text())
    if not isinstance(incoming, list) or not all(isinstance(p, dict) and isinstance(p.get('name'), str) for p in incoming):
        raise ValueError('Paquet de presets invalide.')
    with locked(game):
        path = target(game, 'dfhack-config/mod-manager.json')
        statefile = target(game, '.pgm-presets-state.json')
        if statefile.exists():
            state = json.loads(statefile.read_text())
            if path.exists() and digest(path.read_bytes()) == state['installed_hash']:
                return 'Presets PGM déjà installés. Les restaurer avant de changer de version.'
            raise ValueError('Installation précédente ou interrompue détectée. Restaurer les presets d’abord.')
        original = path.read_bytes() if path.exists() else None
        current = json.loads(original) if original else []
        if not isinstance(current, list) or not all(isinstance(p, dict) for p in current):
            raise ValueError('Presets existants non reconnus : aucun remplacement.')
        merged = list(current)
        for preset in incoming:
            same = [p for p in current if p.get('name') == preset['name']]
            if same and same != [preset]:
                raise ValueError('Un preset personnel porte déjà le nom ' + preset['name'] + '. Il est conservé.')
            if not same:
                copy = dict(preset)
                # Keep the player's existing default when merging a populated file.
                if current:
                    copy['default'] = False
                merged.append(copy)
        data = json.dumps(merged, ensure_ascii=False, indent=2).encode()
        state = {'format': 1, 'original': base64.b64encode(original).decode() if original is not None else None,
                 'original_hash': digest(original) if original is not None else None, 'installed_hash': digest(data)}
        write(statefile, json.dumps(state).encode())
        try:
            write(path, data)
        except Exception:
            if original is None:
                path.unlink(missing_ok=True)
            else:
                write(path, original)
            statefile.unlink(missing_ok=True)
            raise
    return 'Presets Normal et PGM Full installés. Les presets personnels sont conservés.'

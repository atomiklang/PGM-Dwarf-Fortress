"""PGM installer services. No network code runs at import time."""
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import tempfile
import urllib.parse
import urllib.request

VERSION = '0.1.0-beta.1'
PAYLOAD_VERSION = '0.1.0-beta.3'
REPO = 'atomiklang/PGM-Dwarf-Fortress'
API = f'https://api.github.com/repos/{REPO}/releases'
MAX_DOWNLOAD = 64 * 1024 * 1024


def fetch(url, limit):
    parsed = urllib.parse.urlparse(url)
    if parsed.scheme != 'https' or parsed.hostname not in {'api.github.com', 'github.com'}:
        raise ValueError('Adresse de téléchargement non autorisée.')
    request = urllib.request.Request(url, headers={'User-Agent': 'PGM-Installer', 'Accept': 'application/vnd.github+json'})
    with urllib.request.urlopen(request, timeout=30) as response:
        if urllib.parse.urlparse(response.url).scheme != 'https':
            raise ValueError('Redirection non sécurisée.')
        data = response.read(limit + 1)
    if len(data) > limit:
        raise ValueError('Téléchargement trop volumineux.')
    return data


def release_for(system):
    # Beta releases are prereleases, so /latest would incorrectly omit them.
    releases = json.loads(fetch(API + '?per_page=30', 2 * 1024 * 1024))
    prefix = 'PGM-Installer-Windows-' if system == 'Windows' else 'PGM-Installer-Linux-'
    suffix = '.exe' if system == 'Windows' else '.bin'
    for release in releases:
        if release.get('draft'):
            continue
        for asset in release.get('assets', []):
            name = asset.get('name', '')
            if name.startswith(prefix) and name.endswith(suffix) and Path(name).name == name:
                url = asset.get('browser_download_url', '')
                if not url.startswith(f'https://github.com/{REPO}/releases/download/'):
                    raise ValueError('Le fichier ne provient pas du dépôt PGM.')
                checksum = asset.get('digest', '')
                if not checksum or not checksum.startswith('sha256:') or len(checksum) != 71:
                    raise ValueError('Cette publication ne fournit pas de empreinte SHA-256 exploitable.')
                return {'version': release['tag_name'].removeprefix('installer-v').removeprefix('v'), 'name': name,
                        'url': url, 'digest': checksum[7:], 'page': release['html_url']}
    raise ValueError('Aucun installateur publié pour ce système. Consulte la page des publications PGM.')


def download(asset, folder):
    folder = Path(folder)
    name = asset['name']
    if Path(name).name != name or '/' in name or '\\' in name or name in ('.', '..'):
        raise ValueError('Nom de fichier invalide.')
    target = folder / name
    if target.exists() or target.is_symlink():
        raise ValueError('Ce fichier existe déjà. Choisis un autre dossier ou conserve-le ailleurs.')
    data = fetch(asset['url'], MAX_DOWNLOAD)
    if hashlib.sha256(data).hexdigest() != asset['digest']:
        raise ValueError('Téléchargement endommagé : empreinte SHA-256 différente.')
    fd, temporary = tempfile.mkstemp(prefix='.pgm-', dir=folder)
    try:
        with os.fdopen(fd, 'wb') as handle:
            handle.write(data)
        # Exclusive creation avoids replacing an existing download.
        try:
            with target.open('xb') as handle:
                handle.write(data)
        except FileExistsError:
            raise
        except Exception:
            target.unlink(missing_ok=True)
            raise
        if name.endswith('.bin'):
            target.chmod(0o700)
    finally:
        Path(temporary).unlink(missing_ok=True)
    return target


def linux_engine(root):
    path = Path(root) / 'traduction-linux' / 'installer.py'
    spec = importlib.util.spec_from_file_location('pgm_linux_engine', path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def game_candidates():
    roots = [Path.home() / '.local/share/Steam', Path.home() / '.steam/steam',
             Path.home() / '.var/app/com.valvesoftware.Steam/data/Steam']
    for name in ('PROGRAMFILES(X86)', 'PROGRAMFILES'):
        if os.environ.get(name):
            roots.append(Path(os.environ[name]) / 'Steam')
    return [r / 'steamapps/common/Dwarf Fortress' for r in roots
            if (r / 'steamapps/common/Dwarf Fortress').is_dir()]


def game_closed(game):
    """Refuse to change files while the chosen game is running."""
    game = Path(game).resolve()
    if os.name != 'nt':
        for proc in Path('/proc').iterdir():
            if not proc.name.isdigit():
                continue
            try:
                exe = (proc / 'exe').resolve(strict=True)
            except (OSError, RuntimeError):
                continue
            if exe.parent == game and exe.name in ('dwarfort', 'Dwarf Fortress.exe'):
                raise ValueError('Ferme Dwarf Fortress avant de modifier ses fichiers.')
    else:
        import ctypes
        from ctypes import wintypes
        kernel = ctypes.WinDLL('kernel32', use_last_error=True)
        psapi = ctypes.WinDLL('psapi', use_last_error=True)
        kernel.OpenProcess.argtypes = [wintypes.DWORD, wintypes.BOOL, wintypes.DWORD]
        kernel.OpenProcess.restype = wintypes.HANDLE
        kernel.CloseHandle.argtypes = [wintypes.HANDLE]
        kernel.QueryFullProcessImageNameW.argtypes = [wintypes.HANDLE, wintypes.DWORD, wintypes.LPWSTR, ctypes.POINTER(wintypes.DWORD)]
        pids = (wintypes.DWORD * 16384)()
        used = wintypes.DWORD()
        if not psapi.EnumProcesses(pids, ctypes.sizeof(pids), ctypes.byref(used)) or used.value >= ctypes.sizeof(pids):
            raise ValueError('Impossible de vérifier si le jeu est fermé.')
        for pid in pids[:used.value // ctypes.sizeof(wintypes.DWORD)]:
            handle = kernel.OpenProcess(0x1000, False, pid)
            if not handle:
                continue
            try:
                name = ctypes.create_unicode_buffer(32768)
                size = wintypes.DWORD(len(name))
                if kernel.QueryFullProcessImageNameW(handle, 0, name, ctypes.byref(size)):
                    if Path(name.value).resolve() == game / 'Dwarf Fortress.exe':
                        raise ValueError('Ferme Dwarf Fortress avant de modifier ses fichiers.')
            finally:
                kernel.CloseHandle(handle)

"""Optional map navigation, separate from translation and presets."""
import importlib.util
from pathlib import Path


def context(root, system, game, hack=''):
    if system not in ('Linux', 'Windows'):
        raise ValueError('Map navigation supports Linux and Windows only.')
    if not game:
        raise ValueError('Select your game folder first.')
    path=Path(root)/'navigation/navigation_installer.py'
    spec=importlib.util.spec_from_file_location('pgm_navigation_engine',path)
    engine=importlib.util.module_from_spec(spec);spec.loader.exec_module(engine)
    def selected(value):
        raw=Path(value).expanduser().absolute()
        # Windows junctions must be checked before resolve() removes them.
        # Linux home aliases are canonicalized, but explicit root links refused.
        if system=='Windows':engine.safe(raw)
        elif raw.is_symlink():raise ValueError('Select the actual folder, not a symbolic link.')
        return raw.resolve()
    game=selected(game)
    expected='libdfhack.so' if system=='Linux' else 'dfhack.dll'
    if hack:
        chosen=selected(hack)
        candidates=[chosen, chosen/'hack']
    else:
        candidates=[game/'hack', game.parent/'DFHack/hack']
    found=next((p for p in candidates if (p/expected).is_file()),None)
    if found is None:
        raise ValueError('Select the matching DFHack folder for this operating system.')
    engine.safe(found)
    return engine,game,found.resolve(),system.lower()


def run(root,system,game,hack,action,closed,experimental=False):
    if action not in ('check','install','restore'):
        raise ValueError('Unknown navigation action.')
    if action=='install' and system=='Windows' and not experimental:
        raise ValueError('Enable experimental Windows navigation before installing it.')
    engine,game,hack,platform=context(root,system,game,hack)
    if action=='check':
        result=engine.inspect(game,hack,platform=platform,payload_root=Path(root)/'navigation')
        return f"Navigation files checked ({len(result['payload'])} files). No game files were changed."
    if action=='install':
        engine.install(game,hack,platform=platform,payload_root=Path(root)/'navigation',game_closed=closed)
        return 'Map navigation installed. Open a world map, then run gui/worldmap-zoom in DFHack.'
    engine.uninstall(game,hack,game_closed=closed)
    return 'Previous navigation files restored. Translation and presets were not changed.'

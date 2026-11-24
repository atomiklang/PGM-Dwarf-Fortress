"""Create PGM compatibility variants from the player's installed Workshop files."""
import argparse
import os
import stat
import hashlib
from pathlib import Path
import re
import shutil
import tempfile


def validate_tree(root):
    if root.is_symlink():
        raise ValueError(f'Symbolic links are unsupported: {root}')
    for directory, folders, files in os.walk(root, followlinks=False):
        for path in [Path(directory), *(Path(directory) / name for name in folders + files)]:
            info = path.lstat()
            reparse = getattr(info, 'st_file_attributes', 0) & 0x400
            if stat.S_ISLNK(info.st_mode) or reparse:
                raise ValueError(f'Links and Windows junctions are unsupported: {path}')
            if not (stat.S_ISDIR(info.st_mode) or stat.S_ISREG(info.st_mode)):
                raise ValueError(f'Expected a regular file or directory: {path}')


def contents(root):
    return {
        file.relative_to(root).as_posix(): hashlib.sha256(file.read_bytes()).hexdigest()
        for file in root.rglob('*') if file.is_file()
    }


def prepare(source, output, name, expected_id, version, animals=False):
    validate_tree(source)
    source_info = (source / 'info.txt').read_text(encoding='utf-8-sig')
    if f'[ID:{expected_id}]' not in source_info or f'[NUMERIC_VERSION:{version}]' not in source_info:
        raise ValueError(f'Unsupported source version: {source}')
    output.mkdir(parents=True, exist_ok=True)
    destination = output / name
    if destination.is_symlink():
        raise ValueError(f'Preserve the existing symbolic link: {destination}')
    if destination.exists():
        validate_tree(destination)
    with tempfile.TemporaryDirectory(prefix='.pgm-', dir=output) as temporary:
        staged = Path(temporary) / name
        shutil.copytree(source, staged)
        validate_tree(staged)
        text = re.sub(r'\[ID:[^\]]+\]', f'[ID:{name}]', source_info, count=1)
        # Workshop ownership stays with the original item, not its generated local copy.
        text = re.sub(r'\[STEAM_[^\]]*\]\s*', '', text)
        if animals:
            text = text.replace('[REQUIRES_ID_AFTER_ME:vanilla_creatures_graphics]',
                                '[REQUIRES_ID_AFTER_ME:FANTASTIC_FANTASY_FORTRESS]')
            text = text.replace('[NAME:Accurate Domestic Animal Graphics Compilation]',
                                '[NAME:Accurate Domestic Animals - PGM]')
            text += '\n[CONFLICTS_WITH_ID:accurate_domestic_animal_graphics]\n'
            for filename in ['creature_accurate_muskox.txt', 'creature_bovine_color.txt',
                             'creature_equine_color.txt', 'creature_rodent_color.txt',
                             'creature_ungulate_color.txt', 'creature_wool_color.txt']:
                (staged / 'objects' / filename).unlink()
            (staged / 'preview.png').unlink(missing_ok=True)
            page = staged / 'graphics/tile_page_accurate_domestic_animals_graphics.txt'
            original = page.read_text()
            patched, count = re.subn(r'\[TILE_PAGE:RAM_ICON\]\n\t\[FILE:images/ram_icon.png\]\n\t\[TILE_DIM:32:32\]\n\t\[PAGE_DIM_PIXELS:32:32\]\n', '', original)
            if count != 1:
                raise ValueError('The RAM_ICON definition has changed. Review the adaptation.')
            page.write_text(patched, newline='\n')
        else:
            text = text.replace('[NAME:vanilla-born-normally]', '[NAME:Born Normally (copie locale)]')
        (staged / 'info.txt').write_text(text, encoding='utf-8', newline='\n')
        if destination.exists():
            if contents(destination) != contents(staged):
                raise FileExistsError(f'Existing variant differs. Preserve it and choose a different output folder: {destination}')
            print(f'Already prepared: {destination}')
            return
        staged.rename(destination)
        print(f'Prepared: {destination}')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--workshop', required=True, type=Path, help='Workshop content/975370 directory')
    parser.add_argument('--mods', required=True, type=Path, help='Dwarf Fortress user mods directory')
    args = parser.parse_args()
    prepare(args.workshop / '3635878659', args.mods, 'born_normally_linux', 'vanilla_born_normally', 9)
    prepare(args.workshop / '3072627813', args.mods, 'pgm_accurate_domestic_graphics', 'accurate_domestic_animal_graphics', 105, animals=True)


if __name__ == '__main__':
    main()

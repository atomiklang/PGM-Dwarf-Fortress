"""Prepare from a validated local candidate, or verify the bundled release.
Never replace current presets with those from a historical online archive.
"""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import tempfile

ROOT = Path(__file__).resolve().parent
PAYLOAD_FILES = {'libdfhooks_traducfr.so','traducfr/dictionnaire.csv',
 'traducfr/corrections_fr.csv','traducfr/modeles.txt','traducfr/reglages.txt',
 'dfhack-config/scripts/traducfr-dfhack.lua','dfhack-config/scripts/traducfr-fps.lua'}

LINUX_BUILD_FILES = {'installer.py', 'CREDITS.md', 'README.md', 'VALIDATION.txt',
 'BUILD-INFO.json', 'payload-sha256.json', 'tests/test_installer.py'}

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def verify_engine(candidate):
    manifest = json.loads((candidate/'payload-sha256.json').read_text())
    if set(manifest) != PAYLOAD_FILES:
        raise ValueError('Unexpected payload files')
    for name, expected in manifest.items():
        path = candidate/'payload'/name
        if path.is_symlink() or not path.is_file() or digest(path) != expected:
            raise ValueError('Invalid payload: '+name)
    return manifest

def validate_presets(path):
    presets = json.loads(path.read_text())
    if not isinstance(presets,list):
        raise ValueError('Preset list expected')
    selected = [p for p in presets if p.get('name') in ('Normal','PGM Full')]
    if sorted(p['name'] for p in selected) != ['Normal','PGM Full']:
        raise ValueError('Exactly one Normal and PGM Full preset required')
    for preset in selected:
        mods=preset.get('modlist')
        if not isinstance(mods,list) or not mods or any(not isinstance(m.get('id'),str) or type(m.get('version')) is not int for m in mods):
            raise ValueError('Invalid mod references')
        if len({m['id'] for m in mods}) != len(mods):
            raise ValueError('Duplicate mod IDs')
    return selected

WINDOWS_FILES = {'dfhooks_pgm.dll', 'pgm-hook/profile.bin',
 'traducfr/dictionnaire.csv', 'traducfr/modeles.txt',
 'dfhack-config/scripts/traducfr-dfhack.lua',
 'dfhack-config/scripts/pgm-windows-infobulles.lua'}

def verify_windows(root):
    target=root/'traduction-windows'
    if target.is_symlink():
        raise ValueError('Windows bundle symlink refused')
    if not target.exists():
        return None
    if target.is_symlink():
        raise ValueError('Windows bundle symlink refused')
    manifest=json.loads((target/'payload-sha256.json').read_text())
    actual={p.relative_to(target/'payload').as_posix() for p in (target/'payload').rglob('*') if p.is_file()}
    if actual != WINDOWS_FILES:
        raise ValueError('Windows payload must contain exactly six runtime files')
    if set(manifest)!=WINDOWS_FILES:
        raise ValueError('Unexpected Windows payload files')
    for name,expected in manifest.items():
        path=target/'payload'/name
        if any(p.is_symlink() for p in [path,*path.parents]) or not path.is_file() or digest(path)!=expected:
            raise ValueError('Invalid Windows payload: '+name)
    if not (target/'installer.py').is_file() or (target/'installer.py').is_symlink():
        raise ValueError('Windows installer helper missing')
    proof=json.loads((target/'proof.json').read_text())
    if proof.get('tested_payload')!=manifest or proof.get('experimental') is not True or not (proof.get('proton_test_passed') is True or proof.get('real_gui_test',{}).get('passed') is True):
        raise ValueError('Matching successful experimental Windows proof required')
    return manifest

def freeze_windows_bundle(source, proof, root=ROOT):
    """Freeze final six-file Windows runtime plus matching experimental proof.
    Does not claim Windows native compatibility or build an executable.
    """
    source=Path(source);root=Path(root)
    if source.is_symlink() or any(p.is_symlink() for p in source.rglob('*')):
        raise ValueError('Windows source symlink refused')
    with tempfile.TemporaryDirectory(prefix='pgm-win-',dir=root) as temporary:
        stage=Path(temporary)/'traduction-windows'
        stage.mkdir()
        shutil.copytree(source/'payload',stage/'payload')
        shutil.copy2(source/'installer.py',stage/'installer.py')
        shutil.copy2(source/'payload-sha256.json',stage/'payload-sha256.json')
        shutil.copy2(proof,stage/'proof.json')
        verify_windows(Path(temporary))
        target=root/'traduction-windows'
        if target.exists() or target.is_symlink():
            raise ValueError('Windows bundle already exists; review before replacing')
        stage.rename(target)
    receipt=json.loads((root/'BUNDLE.json').read_text())
    receipt['windows']={'experimental':True,'native_windows_validated':False}
    receipt['files']=bundle_manifest(root)
    (root/'BUNDLE.json').write_text(json.dumps(receipt,indent=2)+'\n')
    return verify_bundle(root)

def bundle_manifest(root):
    files=[root/'preparer-variantes.py',root/'presets/mod-manager.json']
    files += [p for p in (root/'traduction-linux').rglob('*') if p.is_file() and '__pycache__' not in p.parts]
    windows=root/'traduction-windows'
    if windows.exists():
        verify_windows(root)
        files += [p for p in windows.rglob('*') if p.is_file() and '__pycache__' not in p.parts]
    if not files or any(p.is_symlink() for p in files):
        raise ValueError('Unexpected symlink in build bundle')
    return {p.relative_to(root).as_posix():digest(p) for p in sorted(files)}

def verify_bundle(root=ROOT):
    receipt=json.loads((root/'BUNDLE.json').read_text())
    if bundle_manifest(root) != receipt['files']:
        raise ValueError('Build bundle differs from its validated manifest; prepare it again')
    verify_engine(root/'traduction-linux')
    validate_presets(root/'presets/mod-manager.json')
    verify_windows(root)
    return receipt

def prepare(candidate,presets,proof,root=ROOT):
    candidate=Path(candidate);manifest=verify_engine(candidate)
    tested=json.loads(Path(proof).read_text())
    if tested.get('tested_payload') != manifest or not tested.get('stayed_running') or not tested.get('real_gui_test',{}).get('passed'):
        raise ValueError('Candidate lacks a matching successful isolated startup test')
    selected=validate_presets(Path(presets))
    if not (root/'preparer-variantes.py').is_file():
        raise ValueError('Variant generator missing')
    # Validate every input before writing. This changes build sources only.
    with tempfile.TemporaryDirectory(prefix='pgm-bundle-',dir=root) as temporary:
        stage=Path(temporary)/'engine'
        stage.mkdir()
        for name in sorted(LINUX_BUILD_FILES | {'payload/'+name for name in PAYLOAD_FILES}):
            source=candidate/name
            if not source.is_file() or any(p.is_symlink() for p in [source,*source.parents]):
                raise ValueError('Missing or linked required Linux build input: '+name)
            destination=stage/name
            destination.parent.mkdir(parents=True,exist_ok=True)
            shutil.copy2(source,destination)
        verify_engine(stage)
        target=root/'traduction-linux';old=Path(temporary)/'previous'
        if target.is_symlink():raise ValueError('Build target is a symlink')
        if target.exists():target.rename(old)
        try:stage.rename(target)
        except Exception:
            if old.exists():old.rename(target)
            raise
    (root/'presets').mkdir(exist_ok=True)
    (root/'presets/mod-manager.json').write_text(json.dumps(selected,ensure_ascii=False,indent=2)+'\n')
    receipt={'payload_version':candidate.name.removeprefix('PGM-Linux-'),
             'startup_test_passed':True,'files':bundle_manifest(root)}
    if verify_windows(root) is not None:
        receipt['windows']={'experimental':True,'native_windows_validated':False}
    (root/'BUNDLE.json').write_text(json.dumps(receipt,indent=2)+'\n')
    return verify_bundle(root)

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--local-candidate',type=Path)
    parser.add_argument('--presets',type=Path)
    parser.add_argument('--proof',type=Path)
    args=parser.parse_args()
    if args.local_candidate:
        if not args.presets or not args.proof:parser.error('--presets and --proof are required')
        receipt=prepare(args.local_candidate,args.presets,args.proof)
    else:receipt=verify_bundle()
    print('Verified build bundle:',receipt['payload_version'])
if __name__=='__main__':main()

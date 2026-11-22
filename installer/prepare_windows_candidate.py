"""Prepare Windows-only navigation and unchanged translation19 in an isolated checkout."""
from pathlib import Path
import hashlib,importlib.util,io,json,stat,urllib.request,zipfile
ROOT=Path(__file__).resolve().parent
NAV_URL='https://github.com/Huitzilopochtli-98/df-world-map-zoom/releases/download/v1.0.1/WorldMapZoom-1.0.1-windows-x64.zip'
NAV_ZIP_SHA256='fc2a5a1ad7a1db379d2ff49362e65a7b7e07c31adba12e25aee514c7473599af'
NAV_DLL_SHA256='c3717f462c29211a3dfbd961661623bc2c6161fed043a2d2bdabd8daa4e1f52c'
DLL='hack/plugins/worldmap-zoom-render.plug.dll'
def sha(data):return hashlib.sha256(data).hexdigest()
def dll_from_archive(data):
    if len(data)>32*1024*1024 or sha(data)!=NAV_ZIP_SHA256:raise ValueError('Pinned navigation archive mismatch')
    with zipfile.ZipFile(io.BytesIO(data)) as archive:
        entries=archive.infolist()
        names=[e.orig_filename for e in entries]
        if names.count('WorldMapZoom/'+DLL)!=1:raise ValueError('Expected exactly one official DLL')
        entry=next(e for e in entries if e.orig_filename=='WorldMapZoom/'+DLL)
        if stat.S_ISLNK(entry.external_attr>>16) or entry.file_size>32*1024*1024:raise ValueError('Invalid DLL entry')
        dll=archive.read(entry)
    if sha(dll)!=NAV_DLL_SHA256:raise ValueError('Pinned official DLL mismatch')
    return dll

def stage_navigation(dll):
    if sha(dll)!=NAV_DLL_SHA256:raise ValueError('DLL mismatch')
    nav=ROOT/'navigation';path=nav/'installation-contract.json'
    contract=json.loads(path.read_text())
    if contract['platforms']['linux']['available'] is not False:raise ValueError('Windows candidate must disable Linux navigation')
    selected=contract['platforms']['windows']
    if selected['available'] is not True:raise ValueError('Experimental Windows contract required')
    proof=json.loads((nav/'WINDOWS-PROTON-VALIDATION.json').read_text())
    if proof.get('passed') is not True or proof.get('plugin_sha256')!=NAV_DLL_SHA256:raise ValueError('Matching Proton evidence required')
    if any(nav.rglob('*.so')):raise ValueError('Unexpected Linux navigation binary')
    for target,record in selected['files'].items():
        source=nav/record['source']
        if target==DLL:
            if record['sha256']!=NAV_DLL_SHA256:raise ValueError('Contract DLL mismatch')
            source.parent.mkdir(parents=True,exist_ok=True);source.write_bytes(dll)
        if not source.is_file() or source.is_symlink() or sha(source.read_bytes())!=record['sha256']:
            raise ValueError('Navigation source mismatch: '+target)
    return proof

def main():
    # Existing downloader pins the unchanged public data19 archive and verifies BUNDLE.
    # It replaces only its five fixed data names; navigation stays in this checkout.
    import fetch_verified_bundle as fetch
    # Existing fetch verification sees candidate navigation; temporarily suppress only
    # bundle enumeration during the old receipt verification, then verify everything.
    import prepare_build
    original=prepare_build.bundle_manifest
    def old_manifest(root):
        return {k:v for k,v in original(root).items() if not k.startswith('navigation/')}
    prepare_build.bundle_manifest=old_manifest
    try:fetch.main()
    finally:prepare_build.bundle_manifest=original
    with urllib.request.urlopen(urllib.request.Request(NAV_URL,headers={'User-Agent':'PGM-candidate-build'}),timeout=60) as response:
        if not response.url.startswith('https://'):raise ValueError('Unsafe navigation redirect')
        archive=response.read(32*1024*1024+1)
    stage_navigation(dll_from_archive(archive))
    receipt=json.loads((ROOT/'BUNDLE.json').read_text())
    receipt['installer_version']='0.1.0-beta.5'
    receipt['unpublished_candidate']=True
    receipt['navigation']={'experimental':True,'linux_available':False,'windows_native_gameplay_validated':False,'proof':'Proton only'}
    receipt['files']=prepare_build.bundle_manifest(ROOT)
    (ROOT/'BUNDLE.json').write_text(json.dumps(receipt,indent=2)+'\n')
    prepare_build.verify_bundle(ROOT)
    print('Windows candidate bundle verified; no native gameplay claim.')
if __name__=='__main__':main()

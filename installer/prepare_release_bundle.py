"""Assemble exact already-validated payloads; builds no plugin or game files."""
from pathlib import Path
import base64,hashlib,json
ROOT=Path(__file__).resolve().parent
def main():
 import fetch_verified_bundle as fetch
 import prepare_build
 original=prepare_build.bundle_manifest
 prepare_build.bundle_manifest=lambda root:{k:v for k,v in original(root).items() if not k.startswith('navigation/')}
 try:fetch.main()
 finally:prepare_build.bundle_manifest=original
 expected=json.loads((ROOT/'RELEASE-BUNDLE.json').read_text())
 for ext in ['so','dll']:
  rel='navigation/output/worldmap-zoom-render.plug.'+ext
  data=base64.b64decode((ROOT/f'navigation-{ext}.base64').read_text().strip(),validate=True)
  if hashlib.sha256(data).hexdigest()!=expected['files'][rel]:raise ValueError('Pinned plugin mismatch: '+ext)
  dest=ROOT/rel;dest.parent.mkdir(exist_ok=True);dest.write_bytes(data)
 # Includes final Lua, contract, licenses, payload19 and both validated plugins.
 if prepare_build.bundle_manifest(ROOT)!=expected['files']:raise ValueError('Source release data differs from tested bundle')
 (ROOT/'BUNDLE.json').write_bytes((ROOT/'RELEASE-BUNDLE.json').read_bytes())
 prepare_build.verify_bundle(ROOT)
if __name__=='__main__':main()

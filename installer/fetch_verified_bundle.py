"""Build-only download of the pinned, public PGM data archive. Never a game installer."""
from pathlib import Path,PurePosixPath
import hashlib,io,json,shutil,stat,tempfile,urllib.request
ROOT=Path(__file__).resolve().parent
# Filled from the frozen archive before the source commit is published.
URL='https://github.com/atomiklang/PGM-Dwarf-Fortress/releases/download/v0.1.0-beta.19/PGM-Assistant-Data-0.1.0-beta.4.zip'
SHA256='a01432b7c271d75cd0e4a780dad7b32b99b9281382de5fd8e1d5eb8d357684e2'
TOP={'BUNDLE.json','preparer-variantes.py','presets','traduction-linux','traduction-windows'}
def unpack(data,target):
 import zipfile
 if len(data)>32*1024*1024:raise ValueError('Archive too large')
 with zipfile.ZipFile(io.BytesIO(data)) as archive:
  entries=archive.infolist()
  if len(entries)>1000 or sum(e.file_size for e in entries)>64*1024*1024:raise ValueError('Expanded archive too large')
  seen=set()
  for e in entries:
   p=PurePosixPath(e.filename)
   if p.is_absolute() or '..' in p.parts or not p.parts or p.parts[0] not in TOP or '\\' in e.filename or ':' in e.filename:raise ValueError('Unsafe archive path')
   if p.as_posix() in seen or stat.S_ISLNK(e.external_attr>>16):raise ValueError('Duplicate or linked archive path')
   seen.add(p.as_posix())
   if e.is_dir():continue
   dest=target.joinpath(*p.parts);dest.parent.mkdir(parents=True,exist_ok=True);dest.write_bytes(archive.read(e))
def main():
 if len(SHA256)!=64:raise ValueError('Archive not frozen')
 request=urllib.request.Request(URL,headers={'User-Agent':'PGM-verified-build'})
 with urllib.request.urlopen(request,timeout=60) as r:
  if not r.url.startswith('https://'):raise ValueError('Unsafe redirect')
  data=r.read(32*1024*1024+1)
 if hashlib.sha256(data).hexdigest()!=SHA256:raise ValueError('Data archive digest mismatch')
 with tempfile.TemporaryDirectory(prefix='.pgm-build-data-',dir=ROOT) as tmp:
  stage=Path(tmp)/'new';stage.mkdir();unpack(data,stage)
  if {p.name for p in stage.iterdir()}!=TOP:raise ValueError('Incomplete build bundle')
  # These fixed build-data names never point to a player installation.
  for name in TOP:
   target=ROOT/name
   if target.is_symlink():raise ValueError('Linked build data refused')
  old=Path(tmp)/'old';old.mkdir();done=[]
  try:
   for name in sorted(TOP):
    target=ROOT/name
    if target.exists():target.rename(old/name)
    done.append(name);(stage/name).rename(target)
   import prepare_build
   prepare_build.verify_bundle(ROOT)
  except Exception:
   for name in reversed(done):
    target=ROOT/name
    if target.is_dir():shutil.rmtree(target)
    else:target.unlink(missing_ok=True)
    if (old/name).exists():(old/name).rename(target)
   raise
 print('Pinned content19 / experimental Windows19 build data verified.')
if __name__=='__main__':main()

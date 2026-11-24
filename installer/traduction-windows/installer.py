"""Optional experimental Windows hook; never downloads or replaces a loader.
Caller must supply a game_closed() callback backed by its process inspection.
Refuse unknown loaders, DF-FR, links, altered payload and concurrent edits.
"""
from pathlib import Path
import hashlib, json, shutil
EXE='3436f0553d6fa17b25716f8b1f034b52e3d9dc30be7f3ddac67cd0ff731d7b16'
LOADER='2585a38275b461db98f969468a4dc27e6704aeaf70a9c87a9ef5b2bf5aa09dd0'
STATE='pgm-windows19-backup'
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def safe(root, relative):
    root=Path(root).absolute()
    if Path(relative).is_absolute() or '..' in Path(relative).parts: raise ValueError('Invalid relative path')
    p=root/relative
    if p!=root and root not in p.parents: raise ValueError('Path outside game')
    for part in [p,*p.parents]:
        if part.is_symlink() or (part.exists() and (getattr(part.stat(),'st_file_attributes',0)&0x400 or (part.is_file() and part.stat().st_nlink>1))): raise ValueError('Links are unsupported')
        if part==root: break
    return p
def check(game, payload, manifest, game_closed):
    game=Path(game);payload=Path(payload)
    if not callable(game_closed) or not game_closed(): raise ValueError('Game must be closed')
    if sha(safe(game,'Dwarf Fortress.exe'))!=EXE: raise ValueError('Unsupported executable')
    if sha(safe(game,'dfhooks.dll'))!=LOADER: raise ValueError('Verified DFHack loader required; loader is never replaced')
    if safe(game,'dfhooks_dfhack.ini').read_bytes()!=b'hack/dfhooks_dfhack.dll\n': raise ValueError('Unsupported DFHack chain configuration')
    if not safe(game,'hack/dfhooks_dfhack.dll').is_file(): raise ValueError('DFHack is missing')
    for f in game.iterdir():
        n=f.name.lower()
        if n.replace('-','').replace('_','')=='dffr' or 'dfint' in n or n.startswith('dfhooks_chain'): raise ValueError('DF-FR/foreign chain detected')
    hashes=json.loads(Path(manifest).read_text())
    expected={'dfhooks_pgm.dll','pgm-hook/profile.bin','traducfr/dictionnaire.csv','traducfr/modeles.txt','dfhack-config/scripts/traducfr-dfhack.lua','dfhack-config/scripts/pgm-windows-infobulles.lua'}
    if set(hashes)!=expected: raise ValueError('Unexpected payload paths')
    for name,digest in hashes.items():
        if sha(safe(payload,name))!=digest: raise ValueError('Payload checksum mismatch: '+name)
        safe(game,name)
    return hashes

def install(game,payload,manifest,game_closed):
    game=Path(game);payload=Path(payload);hashes=check(game,payload,manifest,game_closed)
    backup=safe(game,STATE)
    if backup.exists(): raise ValueError('Existing installation/backup; uninstall first')
    init='dfhack-config/init/dfhack.init'
    original=safe(game,init).read_bytes() if safe(game,init).exists() else b''
    lines=original.splitlines()
    for command in [b'traducfr-dfhack',b'pgm-windows-infobulles']:
        if command not in lines: lines.append(command)
    data={n:(payload/n).read_bytes() for n in hashes};data[init]=b'\n'.join(lines)+b'\n'
    state={}
    backup.mkdir()
    try:
        for name,content in data.items():
            target=safe(game,name)
            if target.exists() and not target.is_file(): raise ValueError('Target is not file')
            exists=target.exists();saved=backup/'files'/name
            if exists: saved.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(target,saved)
            state[name]={'existed':exists,'original_sha256':sha(saved) if exists else None,'installed_sha256':hashlib.sha256(content).hexdigest()}
        (backup/'state.json').write_text(json.dumps(state,indent=2))
        for name,content in data.items():
            if not game_closed(): raise ValueError('Game opened during install')
            target=safe(game,name);target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(content)
    except BaseException:
        for name,info in state.items():
            target=safe(game,name)
            if info['existed']: shutil.copy2(backup/'files'/name,target)
            else: target.unlink(missing_ok=True)
        shutil.rmtree(backup);raise
    return {'experimental':True,'files':state,'loader_modified':False}

def uninstall(game,game_closed):
    game=Path(game)
    if not callable(game_closed) or not game_closed(): raise ValueError('Game must be closed')
    backup=safe(game,STATE);state=json.loads((backup/'state.json').read_text())
    for name,info in state.items():
        if info['existed'] and sha(safe(backup,'files/'+name))!=info['original_sha256']: raise ValueError('Backup checksum mismatch: '+name)
        if sha(safe(game,name))!=info['installed_sha256']: raise ValueError('File modified since installation: '+name)
    current={name:safe(game,name).read_bytes() for name in state}
    try:
        for name,info in state.items():
            if not game_closed(): raise ValueError('Game opened during uninstall')
            target=safe(game,name)
            if info['existed']: shutil.copy2(safe(backup,'files/'+name),target)
            else: target.unlink()
    except BaseException:
        for name,content in current.items(): safe(game,name).write_bytes(content)
        raise
    shutil.rmtree(backup)

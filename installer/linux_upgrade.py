"""Transactional migration of an existing ten-file Linux installation.
Call while holding the engine installation lock. Original backups are immutable.
"""
import copy
import json

def install(engine, game, dfhack):
    state_path=engine.checked_target(game,engine.STATE_DIR+'/state.json')
    if not state_path.exists():
        return engine.install(game,dfhack)
    state=engine.read_state(game)
    if state['phase']!='installed':
        raise ValueError('Installation interrompue : restaure les fichiers avant de continuer.')
    recovery=engine.checked_target(game,engine.STATE_DIR+'/migration.json')
    if recovery.exists():
        raise ValueError('Migration interrompue. Conserve .pgm-linux-install et demande une restauration avant de continuer.')
    # Retain check_game, closed-game and DFHack integrity checks from the engine.
    plan=engine.make_plan_without_init(game,dfhack)
    previous={}
    for name,record in state['files'].items():
        path=engine.checked_target(game,name)
        if not path.exists() or engine.digest(path.read_bytes())!=record['installed']:
            raise ValueError('Fichier personnel modifié, conservé : '+name)
        previous[name]=path.read_bytes()
        if record['original'] is not None:
            backup=engine.checked_target(game,engine.STATE_DIR+'/backups/'+state['backup']+'/'+name)
            if engine.digest(backup.read_bytes())!=record['original']:
                raise ValueError('Sauvegarde originale endommagée : '+name)
    if not set(plan).issubset(state['files']):
        raise ValueError('Périmètre de migration inconnu.')
    if all(previous[name]==data for name,data in plan.items()):
        return 'Traduction déjà à jour.'
    updated=copy.deepcopy(state)
    # Persistent receipt and previous generation allow manual recovery after power loss.
    generation=engine.uuid.uuid4().hex
    for name,data in previous.items():
        engine.atomic_write(engine.checked_target(game,engine.STATE_DIR+'/migrations/'+generation+'/'+name),data)
    engine.atomic_write(recovery,json.dumps({'previous_state':state,'generation':generation},indent=2).encode())
    try:
        for name,data in plan.items():
            target=engine.checked_target(game,name)
            engine.atomic_write(target,data);target.chmod(state['files'][name]['mode'])
            updated['files'][name]['installed']=engine.digest(data)
        engine.save_state(game,updated)
    except Exception:
        # Keep receipt if rollback itself fails; never claim a completed update.
        for name,data in previous.items():
            target=engine.checked_target(game,name)
            engine.atomic_write(target,data);target.chmod(state['files'][name]['mode'])
        engine.save_state(game,state)
        recovery.unlink()
        raise
    recovery.unlink()
    return 'Traduction mise à jour. Sauvegarde originale conservée pour la désinstallation.'

def run(engine,game,dfhack):
    import fcntl
    import os
    engine.check_game(game)
    lock_path=engine.checked_target(game,engine.STATE_DIR+'/install.lock')
    lock_path.parent.mkdir(parents=True,exist_ok=True)
    descriptor=os.open(lock_path,os.O_CREAT|os.O_RDWR|os.O_NOFOLLOW,0o600)
    with os.fdopen(descriptor,'a') as lock:
        fcntl.flock(lock,fcntl.LOCK_EX|fcntl.LOCK_NB)
        return install(engine,game,dfhack)

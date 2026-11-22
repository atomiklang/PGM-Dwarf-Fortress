import hashlib,json,os,shutil,subprocess,tempfile,unittest
from pathlib import Path
import navigation_bridge as bridge
ROOT=Path(__file__).resolve().parents[1]
sha=lambda b:hashlib.sha256(b).hexdigest()

class NavigationIntegration(unittest.TestCase):
    def test_actual_bridge_install_and_restore(self):
        with tempfile.TemporaryDirectory() as d:
            root=Path(d);nav=root/'navigation';nav.mkdir();game=root/'game';hack=game/'hack';hack.mkdir(parents=True)
            shutil.copy2(ROOT/'navigation/navigation_installer.py',nav/'navigation_installer.py')
            engine,_,_,_=self.engine_fixture(root,game,hack)
            files={}
            for name in (*engine.COMMON,'hack/plugins/worldmap-zoom-render.plug.dll'):
                relative='output/worldmap-zoom-render.plug.dll' if name.endswith('.dll') else 'source/'+name
                p=nav/relative;p.parent.mkdir(parents=True,exist_ok=True);blob=b'fixture payload';p.write_bytes(blob)
                files[name]={'source':relative,'sha256':sha(blob),'known_existing_sha256':[sha(blob)]}
            runtime={}
            for name,blob in [('Dwarf Fortress.exe',b'game'),('hack/dfhack.dll',b'dfhack')]:
                (game/name).write_bytes(blob);runtime[name]=sha(blob)
            (nav/'installation-contract.json').write_text(json.dumps({'platforms':{'windows':{'available':True,'files':files,'runtime':runtime}}}))
            calls=[]
            bridge.run(root,'Windows',str(game),'','install',lambda p:calls.append(p),experimental=True)
            self.assertTrue((hack/'plugins/worldmap-zoom-render.plug.dll').is_file())
            bridge.run(root,'Windows',str(game),'','restore',lambda p:calls.append(p))
            self.assertFalse((hack/'plugins/worldmap-zoom-render.plug.dll').exists());self.assertEqual(len(calls),2)
            self.assertEqual((game/'Dwarf Fortress.exe').read_bytes(),b'game')

    def engine_fixture(self,root,game,hack):
        (hack/'dfhack.dll').write_bytes(b'dfhack')
        return bridge.context(root,'Windows',str(game))

    @unittest.skipUnless(os.name=='nt','Native NTFS junction test')
    def test_junction_refused_before_root_resolution(self):
        with tempfile.TemporaryDirectory() as d:
            root=Path(d);game=root/'actual-game';hack=game/'hack';hack.mkdir(parents=True)
            (hack/'dfhack.dll').write_bytes(b'fixture')
            link=root/'linked-game'
            subprocess.run(['cmd','/c','mklink','/J',str(link),str(game)],check=True,capture_output=True)
            try:
                with self.assertRaisesRegex(ValueError,'reparse'):
                    bridge.context(ROOT,'Windows',str(link))
                engine,_,_,_=bridge.context(ROOT,'Windows',str(game))
                with self.assertRaisesRegex(ValueError,'reparse'):engine.safe(link/'dfhack-config/scripts')
            finally:link.rmdir()

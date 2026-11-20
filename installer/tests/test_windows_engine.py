import importlib.util,tempfile,unittest,json,hashlib
from pathlib import Path
spec=importlib.util.spec_from_file_location('installer',Path(__file__).parents[1]/'traduction-windows/installer.py');m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
class Tests(unittest.TestCase):
 def test_transaction(self):
  with tempfile.TemporaryDirectory() as td:
   game=Path(td)/'game';game.mkdir();payload=Path(__file__).parents[1]/'traduction-windows/payload';manifest=payload.parent/'payload-sha256.json'
   (game/'Dwarf Fortress.exe').write_bytes(b'fake exe');(game/'dfhooks.dll').write_bytes(b'loader');(game/'hack').mkdir();(game/'hack/dfhooks_dfhack.dll').write_bytes(b'dfhack');(game/'dfhooks_dfhack.ini').write_bytes(b'hack/dfhooks_dfhack.dll\n')
   old=(m.EXE,m.LOADER);m.EXE=m.sha(game/'Dwarf Fortress.exe');m.LOADER=m.sha(game/'dfhooks.dll')
   try:
    with self.assertRaises(ValueError):m.check(game,payload,manifest,lambda:False)
    (game/'dffr').mkdir()
    with self.assertRaises(ValueError):m.check(game,payload,manifest,lambda:True)
    (game/'dffr').rmdir();(game/'traducfr').mkdir();(game/'traducfr/dictionnaire.csv').write_bytes(b'original')
    m.install(game,payload,manifest,lambda:True);self.assertEqual((game/'dfhooks.dll').read_bytes(),b'loader')
    installed=(game/'dfhooks_pgm.dll').read_bytes();(game/'dfhooks_pgm.dll').write_bytes(b'edited')
    with self.assertRaises(ValueError):m.uninstall(game,lambda:True)
    (game/'dfhooks_pgm.dll').write_bytes(installed);m.uninstall(game,lambda:True);self.assertEqual((game/'traducfr/dictionnaire.csv').read_bytes(),b'original');self.assertFalse((game/'dfhooks_pgm.dll').exists())
    calls=[True]*3+[False]
    with self.assertRaises(ValueError):m.install(game,payload,manifest,lambda:calls.pop(0) if calls else False)
    self.assertEqual((game/'traducfr/dictionnaire.csv').read_bytes(),b'original');self.assertFalse((game/m.STATE).exists())
    with self.assertRaises(ValueError):m.safe(game,'../outside')
   finally:m.EXE,m.LOADER=old
if __name__=='__main__':unittest.main()

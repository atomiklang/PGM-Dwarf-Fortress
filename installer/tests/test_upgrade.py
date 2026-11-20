import sys
import copy
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch
import core
import linux_upgrade

@unittest.skipUnless(sys.platform == 'linux', 'Linux migration engine')
class Migration(unittest.TestCase):
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory();self.addCleanup(self.temp.cleanup)
        self.game=Path(self.temp.name)
        self.engine=core.linux_engine(Path(__file__).resolve().parents[1])
        self.old={n:('old '+n).encode() for n in sorted(self.engine.MANAGED_FILES)}
        self.new={n:('new '+n).encode() for n in sorted(self.engine.PAYLOAD_FILES)}
        self.original={n:('original '+n).encode() for n in self.old}
        token='a'*32
        state={'phase':'installed','backup':token,'files':{}}
        for n,data in self.old.items():
            p=self.game/n;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(data)
            b=self.game/self.engine.STATE_DIR/'backups'/token/n;b.parent.mkdir(parents=True,exist_ok=True);b.write_bytes(self.original[n])
            state['files'][n]={'original':self.engine.digest(self.original[n]),'installed':self.engine.digest(data),'mode':0o644}
        self.engine.save_state(self.game,state);self.state=copy.deepcopy(state)
        self.addCleanup(patch.stopall)
        patch.object(self.engine,'make_plan_without_init',return_value=self.new).start()
    def apply(self):return linux_upgrade.install(self.engine,self.game,None)
    def test_old_state_migrates_and_original_restores(self):
        self.apply();self.engine.restore(self.game,self.engine.read_state(self.game))
        for n in self.old:self.assertEqual((self.game/n).read_bytes(),self.original[n])
    def test_personal_change_refused(self):
        p=self.game/'traducfr/modeles.txt';p.write_bytes(b'personal')
        with self.assertRaises(ValueError):self.apply()
        self.assertEqual(p.read_bytes(),b'personal');self.assertEqual(self.engine.read_state(self.game),self.state)
    def test_rollback_after_partial_write(self):
        real=self.engine.atomic_write;count=0
        def failing(path,data):
            nonlocal count
            if path.relative_to(self.game).as_posix() in self.old:
                count+=1
                if count==2:raise OSError('injected disk failure')
            return real(path,data)
        with patch.object(self.engine,'atomic_write',side_effect=failing):
            with self.assertRaises(OSError):self.apply()
        for n in self.old:self.assertEqual((self.game/n).read_bytes(),self.old[n])
        self.assertEqual(self.engine.read_state(self.game),self.state)
    def test_identical_reinstall(self):
        self.apply();before=self.engine.read_state(self.game);self.apply()
        self.assertEqual(self.engine.read_state(self.game),before)
    def test_symlink_refused(self):
        p=self.game/'traducfr/modeles.txt';p.unlink();p.symlink_to(self.game/'libdfhooks.so')
        with self.assertRaises(ValueError):self.apply()

import json
from pathlib import Path
import tempfile
import unittest
import pack

class Presets(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.game = self.root / 'game'
        (self.game / 'dfhack-config').mkdir(parents=True)
        self.path = self.game / 'dfhack-config/mod-manager.json'
        self.bundle = self.root / 'presets.json'
        self.bundle.write_text(json.dumps([{'name': 'Normal', 'default': True, 'modlist': []}]))

    def test_roundtrip(self):
        pack.install(self.game, self.bundle)
        self.assertTrue(self.path.exists())
        pack.restore(self.game)
        self.assertFalse(self.path.exists())

    def test_user_presets_preserved(self):
        original = b'[{"name":"Personal","default":true}]'
        self.path.write_bytes(original)
        pack.install(self.game, self.bundle)
        merged = json.loads(self.path.read_text())
        self.assertTrue(merged[0]['default'])
        self.assertFalse(merged[1]['default'])
        pack.restore(self.game)
        self.assertEqual(self.path.read_bytes(), original)

    def test_edited_file_not_overwritten(self):
        pack.install(self.game, self.bundle)
        self.path.write_bytes(b'[{"name":"changed"}]')
        with self.assertRaises(ValueError):
            pack.restore(self.game)
        self.assertEqual(self.path.read_bytes(), b'[{"name":"changed"}]')

    def test_conflicting_name_preserved(self):
        original = b'[{"name":"Normal","custom":true}]'
        self.path.write_bytes(original)
        with self.assertRaises(ValueError):
            pack.install(self.game, self.bundle)
        self.assertEqual(self.path.read_bytes(), original)

    def test_repeat_install(self):
        pack.install(self.game, self.bundle)
        before = self.path.read_bytes()
        pack.install(self.game, self.bundle)
        self.assertEqual(before, self.path.read_bytes())

    def test_existing_lock(self):
        (self.game / '.pgm-presets.lock').write_text('busy')
        with self.assertRaises(ValueError):
            pack.install(self.game, self.bundle)
        self.assertFalse(self.path.exists())

    def test_corrupt_json_preserved(self):
        self.path.write_bytes(b'broken json')
        with self.assertRaises(ValueError):
            pack.install(self.game, self.bundle)
        self.assertEqual(self.path.read_bytes(), b'broken json')

    def test_unexpected_symlink(self):
        elsewhere = self.root / 'elsewhere'
        elsewhere.write_bytes(b'original')
        try:
            self.path.symlink_to(elsewhere)
        except OSError:
            self.skipTest('Symlinks not permitted on this host')
        with self.assertRaises(ValueError):
            pack.install(self.game, self.bundle)
        self.assertEqual(elsewhere.read_bytes(), b'original')

    def test_new_bundle_is_not_falsely_reported_installed(self):
        pack.install(self.game, self.bundle)
        before = self.path.read_bytes()
        self.bundle.write_text(json.dumps([{'name':'Normal','default':True,'modlist':[{'id':'new','version':1}]}]))
        with self.assertRaisesRegex(ValueError, 'autre version'):
            pack.install(self.game, self.bundle)
        self.assertEqual(self.path.read_bytes(), before)
        pack.restore(self.game)
        pack.install(self.game, self.bundle)
        self.assertEqual(json.loads(self.path.read_text())[0]['modlist'][0]['id'], 'new')

import importlib.util
from pathlib import Path
import struct
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('installer', ROOT / 'installer.py')
installer = importlib.util.module_from_spec(spec)
spec.loader.exec_module(installer)


def make_game(root):
    game = root / 'game'
    (game / 'hack').mkdir(parents=True)
    header = bytearray(64)
    header[:6] = b'\x7fELF\x02\x01'
    struct.pack_into('<HH', header, 16, 2, 62)
    struct.pack_into('<Q', header, 32, 64)
    struct.pack_into('<HH', header, 54, 56, 1)
    length = max(address + len(data) for address, data in installer.SIGNATURES.items())
    with (game / 'dwarfort').open('wb') as file:
        file.write(header)
        file.write(struct.pack('<IIQQQQQQ', 1, 5, 0, 0, 0, length, length, 4096))
        for address, data in installer.SIGNATURES.items():
            file.seek(address)
            file.write(data)
    (game / 'libg_src_lib.so').write_bytes(header)
    (game / 'libdfhooks.so').write_bytes(header + b'libdfhooks_')
    (game / 'hack/libdfhooks_dfhack.so').write_bytes(header)
    init = game / 'dfhack-config/init/dfhack.init'
    init.parent.mkdir(parents=True)
    init.write_bytes(b'# previous settings\n')
    return game


class InstallerSecurityTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.game = make_game(self.root)

    def installed_state(self):
        installer.install(self.game, None)
        return installer.read_state(self.game)

    def test_round_trip_and_repeat_install(self):
        original = (self.game / 'dfhack-config/init/dfhack.init').read_bytes()
        state = self.installed_state()
        installer.install(self.game, None)
        installer.restore(self.game, state)
        self.assertEqual((self.game / 'dfhack-config/init/dfhack.init').read_bytes(), original)
        self.assertFalse((self.game / 'libdfhooks_traducfr.so').exists())

    def test_backup_traversal_is_rejected_before_restoring(self):
        state = self.installed_state()
        state['backup'] = '../../outside'
        with self.assertRaises(ValueError):
            installer.restore(self.game, state)
        self.assertTrue((self.game / 'libdfhooks_traducfr.so').exists())

    def test_state_cannot_delete_an_unmanaged_file(self):
        state = self.installed_state()
        victim = self.game / 'personal.txt'
        victim.write_text('preserve this')
        state['files']['personal.txt'] = {'original': None, 'installed': installer.digest(victim.read_bytes()), 'mode': 0o644}
        with self.assertRaises(ValueError):
            installer.restore(self.game, state)
        self.assertEqual(victim.read_text(), 'preserve this')

    def test_backup_symlink_is_rejected(self):
        state = self.installed_state()
        backup = self.game / installer.STATE_DIR / 'backups' / state['backup'] / 'libdfhooks.so'
        outside = self.root / 'outside.so'
        outside.write_bytes(backup.read_bytes())
        backup.unlink()
        backup.symlink_to(outside)
        with self.assertRaises(ValueError):
            installer.restore(self.game, state)

    def test_user_edits_prevent_partial_restore(self):
        state = self.installed_state()
        target = self.game / 'traducfr/reglages.txt'
        target.write_bytes(target.read_bytes() + b'personal=1\n')
        with self.assertRaises(ValueError):
            installer.restore(self.game, state)
        self.assertTrue((self.game / 'libdfhooks_traducfr.so').exists())

    def test_internal_symlink_is_rejected(self):
        (self.game / 'alias').symlink_to(self.game / 'hack', target_is_directory=True)
        with self.assertRaises(ValueError):
            installer.checked_target(self.game, 'alias/test.txt')

    def test_install_write_error_rolls_back(self):
        original = (self.game / 'dfhack-config/init/dfhack.init').read_bytes()
        real_write = installer.atomic_write
        counter = 0
        def failing_write(path, data):
            nonlocal counter
            counter += 1
            if counter == 12:
                raise OSError('injected write failure')
            real_write(path, data)
        installer.atomic_write = failing_write
        try:
            with self.assertRaises(OSError):
                installer.install(self.game, None)
        finally:
            installer.atomic_write = real_write
        self.assertEqual((self.game / 'dfhack-config/init/dfhack.init').read_bytes(), original)
        self.assertFalse((self.game / 'libdfhooks_traducfr.so').exists())

    def test_state_cannot_restore_privileged_file_mode(self):
        state = self.installed_state()
        state['files']['libdfhooks.so']['mode'] = 0o4755
        with self.assertRaises(ValueError):
            installer.restore(self.game, state)

    def test_manifest_cannot_name_external_file(self):
        package = self.root / 'package'
        package.mkdir()
        (package / 'payload-sha256.json').write_text('{"../external": "' + '0' * 64 + '"}')
        previous = installer.ROOT
        installer.ROOT = package
        try:
            with self.assertRaises(ValueError):
                installer.read_manifest()
        finally:
            installer.ROOT = previous

    def test_windows_executable_is_rejected(self):
        (self.game / 'dwarfort').write_bytes(b'MZ' + b'\0' * 100)
        with self.assertRaises(ValueError):
            installer.make_plan(self.game, None)


if __name__ == '__main__':
    unittest.main()

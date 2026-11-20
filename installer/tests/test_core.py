import hashlib
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
import core

class Updates(unittest.TestCase):
    def asset(self):
        data = b'zip content'
        return {'name': 'PGM-Installer-Linux-1.bin', 'browser_download_url':
                f'https://github.com/{core.REPO}/releases/download/v1/file.zip',
                'digest': 'sha256:' + hashlib.sha256(data).hexdigest()}

    def test_prerelease_is_offered(self):
        release = {'draft': False, 'prerelease': True, 'tag_name': 'v1',
                   'assets': [self.asset()], 'html_url': 'https://github.com'}
        with patch('core.fetch', return_value=json.dumps([release]).encode()):
            self.assertEqual(core.release_for('Linux')['version'], '1')

    def test_missing_hash_rejected(self):
        asset = self.asset()
        del asset['digest']
        with patch('core.fetch', return_value=json.dumps([{'assets': [asset]}]).encode()):
            with self.assertRaises(ValueError):
                core.release_for('Linux')

    def test_foreign_asset_rejected(self):
        asset = self.asset()
        asset['browser_download_url'] = 'https://github.com/other/project/file'
        with patch('core.fetch', return_value=json.dumps([{'assets': [asset]}]).encode()):
            with self.assertRaises(ValueError):
                core.release_for('Linux')

    def test_wrong_digest_writes_nothing(self):
        with tempfile.TemporaryDirectory() as directory, patch('core.fetch', return_value=b'bad'):
            with self.assertRaises(ValueError):
                core.download({'name': 'test.zip', 'url': 'unused', 'digest': '0' * 64}, directory)
            self.assertEqual(list(Path(directory).iterdir()), [])

    def test_existing_download_is_preserved(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'test.zip'
            path.write_bytes(b'original')
            with self.assertRaises(ValueError):
                core.download({'name': 'test.zip'}, directory)
            self.assertEqual(path.read_bytes(), b'original')

    def test_verified_download(self):
        with tempfile.TemporaryDirectory() as directory, patch('core.fetch', return_value=b'good'):
            result = core.download({'name': 'test.zip', 'url': 'unused',
                                    'digest': hashlib.sha256(b'good').hexdigest()}, directory)
            self.assertEqual(result.read_bytes(), b'good')

    def test_non_https_rejected(self):
        with self.assertRaises(ValueError):
            core.fetch('http://github.com/file', 10)

    def test_version_order_never_downgrades(self):
        self.assertFalse(core.newer_than('0.1.0-beta.2','0.1.0-beta.3'))
        self.assertFalse(core.newer_than('0.1.0-beta.3','0.1.0-beta.3'))
        self.assertTrue(core.newer_than('0.1.0-beta.10','0.1.0-beta.9'))
        self.assertTrue(core.newer_than('0.1.0','0.1.0-beta.99'))
        self.assertFalse(core.newer_than('0.1.0-beta.99','0.1.0'))
        with self.assertRaises(ValueError):core.newer_than('unknown','0.1.0')

    def test_release_order_does_not_pick_older_publication(self):
        releases=[{'tag_name':'installer-v0.1.0-beta.'+str(n),'assets':[self.asset()],'html_url':'https://github.com'} for n in [2,10,3]]
        with patch('core.fetch',return_value=json.dumps(releases).encode()):
            self.assertEqual(core.release_for('Linux')['version'],'0.1.0-beta.10')

if __name__ == '__main__':
    unittest.main()

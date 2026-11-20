import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
import prepare_build as prepare

class Preparation(unittest.TestCase):
    def setUp(self):
        self.tmp=tempfile.TemporaryDirectory();self.addCleanup(self.tmp.cleanup)
        self.root=Path(self.tmp.name);self.candidate=self.root/'candidate';self.build=self.root/'build';self.build.mkdir()
        (self.build/'preparer-variantes.py').write_text('# test')
        manifest={}
        for rel in prepare.PAYLOAD_FILES:
            p=self.candidate/'payload'/rel;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(rel.encode());manifest[rel]=prepare.digest(p)
        (self.candidate/'payload-sha256.json').write_text(json.dumps(manifest))
        for name in prepare.LINUX_BUILD_FILES - {'payload-sha256.json'}:
            path=self.candidate/name;path.parent.mkdir(parents=True,exist_ok=True);path.write_text('# fixture')
        self.proof=self.root/'proof.json';self.proof.write_text(json.dumps({'tested_payload':manifest,'stayed_running':True,'real_gui_test':{'passed':True}}))
        self.presets=self.root/'presets.json';self.presets.write_text(json.dumps([{'name':n,'modlist':[{'id':'vanilla','version':1}]} for n in ['Normal','PGM Full','personal']]))
    def run_prepare(self):
        return prepare.prepare(self.candidate,self.presets,self.proof,self.build)
    def test_bundle_keeps_only_shared_presets_and_detects_changes(self):
        self.run_prepare();prepare.verify_bundle(self.build)
        p=self.build/'presets/mod-manager.json';self.assertEqual(len(json.loads(p.read_text())),2)
        p.write_text('[]')
        with self.assertRaises(ValueError):prepare.verify_bundle(self.build)
    def test_corrupt_payload_does_not_touch_previous_build(self):
        (self.build/'presets').mkdir();p=self.build/'presets/mod-manager.json';p.write_text('keep me')
        (self.candidate/'payload/libdfhooks_traducfr.so').write_bytes(b'changed')
        with self.assertRaises(ValueError):self.run_prepare()
        self.assertEqual(p.read_text(),'keep me')
    def test_mismatched_startup_proof_rejected(self):
        self.proof.write_text('{}')
        with self.assertRaises(ValueError):self.run_prepare()
        self.assertFalse((self.build/'traduction-linux').exists())
    def test_duplicate_preset_rejected(self):
        self.presets.write_text(json.dumps([{'name':'Normal','modlist':[]}]*2))
        with self.assertRaises(ValueError):self.run_prepare()
    def test_sources_have_no_implicit_network_download(self):
        with self.assertRaises(FileNotFoundError):prepare.verify_bundle(self.build)

    def test_build_uses_explicit_file_allowlist(self):
        (self.candidate/'FLORE.json').write_text('historical private path')
        (self.candidate/'DEPLOYED.json').write_text('historical deployment')
        self.run_prepare()
        actual={p.relative_to(self.build/'traduction-linux').as_posix() for p in (self.build/'traduction-linux').rglob('*') if p.is_file()}
        self.assertEqual(actual,prepare.LINUX_BUILD_FILES | {'payload/'+p for p in prepare.PAYLOAD_FILES})

    def test_missing_required_helper_does_not_replace_previous_engine(self):
        previous=self.build/'traduction-linux';previous.mkdir();(previous/'keep').write_text('old')
        (self.candidate/'installer.py').unlink()
        with self.assertRaises((ValueError,OSError)):self.run_prepare()
        self.assertEqual((previous/'keep').read_text(),'old')

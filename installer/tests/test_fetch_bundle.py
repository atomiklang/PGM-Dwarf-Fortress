import io,zipfile,tempfile,unittest
from pathlib import Path
import fetch_verified_bundle as f
class BundleArchive(unittest.TestCase):
 def archive(self,names):
  b=io.BytesIO()
  with zipfile.ZipFile(b,'w') as z:
   for name in names:
    info=zipfile.ZipInfo();info.filename=name;info.orig_filename=name
    z.writestr(info,b'x')
  with zipfile.ZipFile(io.BytesIO(b.getvalue())) as z:
   self.assertEqual(z.namelist(),names)
  return b.getvalue()
 def test_accepts_own_build_data(self):
  with tempfile.TemporaryDirectory() as d:
   f.unpack(self.archive(['BUNDLE.json','traduction-windows/payload/dfhooks_pgm.dll']),Path(d))
   self.assertEqual((Path(d)/'BUNDLE.json').read_bytes(),b'x')
 def test_rejects_escape_and_unrelated_code(self):
  for name in ['../game.exe','/absolute','C:/game.exe','presets/../../bad','core.py','presets\\bad']:
   with self.subTest(name=name),tempfile.TemporaryDirectory() as d:
    with self.assertRaises(ValueError):f.unpack(self.archive([name]),Path(d))
 def test_rejects_duplicate(self):
  with tempfile.TemporaryDirectory() as d:
   with self.assertRaises(ValueError):f.unpack(self.archive(['BUNDLE.json','BUNDLE.json']),Path(d))

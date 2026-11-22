"""Download only the already-tested native Windows CI artifact, with pinned hashes."""
from pathlib import Path
import hashlib,io,os,urllib.request,urllib.parse,zipfile
ZIP_SHA='d8bfd3fb2f9d5767e177e8d2f5acba7636d5bd3204e0f7b24fc067a4e56383f3'
EXE='PGM-Installer-Windows-0.1.0-beta.5.exe'
EXE_SHA='941c969b29c4277e843c47b66befd98263b4ce66e2ff3495dbb5d05cf4fe5b3f'
def extract(data,target):
 if hashlib.sha256(data).hexdigest()!=ZIP_SHA:raise ValueError('Windows artifact ZIP mismatch')
 with zipfile.ZipFile(io.BytesIO(data)) as z:
  entries=[e for e in z.infolist() if e.orig_filename==EXE]
  if len(entries)!=1:raise ValueError('Windows executable must occur once at artifact root')
  exe=z.read(entries[0])
 if hashlib.sha256(exe).hexdigest()!=EXE_SHA:raise ValueError('Windows executable mismatch')
 target.mkdir(parents=True,exist_ok=True);(target/EXE).write_bytes(exe)
 (target/'SHA256SUMS-Windows.txt').write_text(EXE_SHA+'  '+EXE+'\n')
class SafeRedirect(urllib.request.HTTPRedirectHandler):
 def redirect_request(self,req,fp,code,msg,headers,newurl):
  if urllib.parse.urlparse(newurl).scheme!='https':raise ValueError('Insecure artifact redirect')
  redirected=super().redirect_request(req,fp,code,msg,headers,newurl)
  if urllib.parse.urlparse(req.full_url).hostname!=urllib.parse.urlparse(newurl).hostname:
   for store in [redirected.headers,redirected.unredirected_hdrs]:
    for key in list(store):
     if key.lower()=='authorization':del store[key]
  return redirected

def main():
 req=urllib.request.Request('https://api.github.com/repos/atomiklang/PGM-Dwarf-Fortress/actions/artifacts/14764550072/zip',headers={'Authorization':'Bearer '+os.environ['GH_TOKEN'],'Accept':'application/vnd.github+json'})
 with urllib.request.build_opener(SafeRedirect()).open(req,timeout=60) as response:data=response.read(128*1024*1024+1)
 if len(data)>128*1024*1024:raise ValueError('Artifact too large')
 extract(data,Path('release'))
if __name__=='__main__':main()

"""Run a short GUI smoke test, using an isolated virtual display on Linux."""
import os
from pathlib import Path
import selectors
import shutil
import subprocess
import sys

def run(command):
    if sys.platform != 'linux':
        return subprocess.run(command,check=True,timeout=90)
    if shutil.which('xvfb-run'):
        return subprocess.run(['xvfb-run','-a']+command,check=True,timeout=90)
    read_fd,write_fd=os.pipe()
    server=None
    try:
        server=subprocess.Popen(['Xvfb','-displayfd',str(write_fd),'-screen','0','1024x768x24','-nolisten','tcp'],pass_fds=(write_fd,),stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
        os.close(write_fd);write_fd=None
        with selectors.DefaultSelector() as selector:
            selector.register(read_fd,selectors.EVENT_READ)
            if not selector.select(timeout=10):raise RuntimeError('Virtual display startup timed out')
        number=os.read(read_fd,64).decode().strip()
        if not number.isdigit():raise RuntimeError('Virtual display failed')
        env=dict(os.environ,DISPLAY=':'+number)
        return subprocess.run(command,env=env,check=True,timeout=90)
    finally:
        os.close(read_fd)
        if write_fd is not None:os.close(write_fd)
        if server:
            server.terminate()
            try:server.wait(timeout=5)
            except subprocess.TimeoutExpired:server.kill();server.wait()
if __name__=='__main__':run(sys.argv[1:])

import os
import sys
from socket import *
from threading import Thread

from watchdog.events import FileSystemEventHandler
from watchdog.observers import Observer

CMD_PORT = 6010
BUFFER = 1024

cmdSocket = None

class SourcecodeHandler(FileSystemEventHandler):
    def on_created(self, event):  on_sourcecode(event, event.src_path)
    def on_modified(self, event): on_sourcecode(event, event.src_path)
    def on_moved(self, event):    on_sourcecode(event, event.dest_path)

def on_sourcecode(event, path):
    if event.is_directory or ('tmp' in path):
        return
    cmdSocket.send('sendrequest {"cmd":"reload","modulefiles":["%s","src/main.lua"]}\n' % path)

class ResourceHandler(FileSystemEventHandler):
    def on_created(self, event):  on_resource(event, event.src_path)
    def on_modified(self, event): on_resource(event, event.src_path)
    def on_moved(self, event):    on_resource(event, event.dest_path)

def on_resource(event, path):
    if event.is_directory or ('tmp' in path):
        return
    cmdSocket.send('sendrequest {"cmd":"reload","modulefiles":["src/main.lua"]}\n')

def receiver():
    while True:
        res = cmdSocket.recv(BUFFER)
        if len(res) == 0: break
        print(res)

if __name__ == "__main__":
    cmdSocket = socket(AF_INET, SOCK_STREAM)
    cmdSocket.connect((sys.argv[1], CMD_PORT))
    Thread(target = receiver).start()
    obs = Observer()
    obs.schedule(SourcecodeHandler(), 'src', recursive=True)
    obs.schedule(ResourceHandler(), 'res', recursive=True)
    obs.start()
    try:
        while True:
            cmdSocket.send(raw_input() + '\n')
    except:
        pass
    obs.stop()
    obs.join()
    cmdSocket.send('exit\n')
    cmdSocket.close()

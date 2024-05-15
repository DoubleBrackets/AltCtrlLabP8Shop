#!/usr/bin/python
import os
import time
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler
import requests

url = 'http://ec2-3-145-172-234.us-east-2.compute.amazonaws.com:8080'
sep = os.sep

class MyHandler(FileSystemEventHandler):
    def on_modified(self, event):
        print(f'event type: {event.event_type}  path : {event.src_path}')
        filename = event.src_path.split(sep)[-1]
        path = event.src_path
        if(filename == 'labopen.txt'):
            print("file has been modified")
            new_state = open(path, 'r').read().strip()
            print("Setting room to " + new_state)
            body = {'setRoomState': int(new_state)}
            response = requests.post(url, json = body)
            print(response.text)

if __name__ == "__main__":
    event_handler = MyHandler()
    observer = Observer()
    observer.schedule(event_handler, path='.', recursive=False)
    observer.start()

    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        observer.stop()
    observer.join()
#!/usr/bin/python
import os
import time
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler
import requests
import sys

# API is unsecured right now (yeah....) so don't include it in the code
gdac_discord_bot_api_url = ""
lab_status_filename = 'lab_status.txt'
sep = os.sep

class FileChangeHandler(FileSystemEventHandler):
    def on_modified(self, event):
        print(f'event type: {event.event_type}  path : {event.src_path}')
        filename = event.src_path.split(sep)[-1]
        path = event.src_path

        # If the lab status changes, update discord bot status
        if(filename == lab_status_filename):
            self.update_lab_status_discord_bot(path)

    def update_lab_status_discord_bot(self, status_file_path):
        print("lab open file has been modified")

        new_state = open(status_file_path, 'r').read().strip()

        print("Setting room to " + new_state)

        print("Calling endpoint: " + gdac_discord_bot_api_url)

        # will need to match API of the gdac discord bot
        body = {'setRoomState': int(new_state)}
        response = requests.post(gdac_discord_bot_api_url, json = body)

        print(response.text)


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python backend.py <gdac_discord_bot_api_url>")
        sys.exit(1)

    gdac_discord_bot_api_url = sys.argv[1]
    
    print("Starting file watcher")
    # Watchdog observer for file changes
    event_handler = FileChangeHandler()
    observer = Observer()
    observer.schedule(event_handler, path='./interop', recursive=False)
    observer.start()

    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        observer.stop()

    observer.join()

# -*- coding: utf-8 -*-
"""
Media tools
"""
import os
import logging
import pipes
from collections import defaultdict
from datetime import datetime
from time import sleep

from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy import Column, Integer, String
from sqlalchemy.orm import sessionmaker


EXTENSIONS = ['.asf', '.avi', '.divx', '.f4v', '.flc', '.flv', '.m4v', '.mkv',
              '.mov', '.mp4', '.mpa', '.mpeg', '.mpg', '.ogv', '.wmv']
MINIMUM_VIDEO_SIZE = 10 * 1000 * 1000  # 10 megabytes
VIDEO_ROOT_PATH = os.path.join(os.environ.get('VIDEO_ROOT_PATH', ''), '')
APPS = ['vlc.Vlc', 'feh.feh', 'google-chrome', 'Chromium-browser']

logger = logging.getLogger(__name__)
engine = create_engine('sqlite:///:memory:', echo=True)  # TODO Save to a .sqlite file
Base = declarative_base()
Session = sessionmaker(bind=engine)
session = Session()


class Video(Base):
    """Video file, with path and size."""
    __tablename__ = 'video'

    video_id = Column(Integer, primary_key=True)
    path = Column(String)
    size = Column(Integer)

    def __repr__(self):
        return "<Video(path='{}', size='{}')>".format(self.path, self.size)


def scan_video_files():
    """Scan all video files in subdirectories, ignoring videos with less than 10 MB.
    Save the videos in SQLite.

    :return: None
    """
    if not VIDEO_ROOT_PATH:
        logger.error('The environment variable VIDEO_ROOT_PATH must contain the video root directory')
        return

    Base.metadata.create_all(engine)

    # http://stackoverflow.com/questions/18394147/recursive-sub-folder-search-and-return-files-in-a-list-python
    for partial_path in [os.path.join(root, file).replace(VIDEO_ROOT_PATH, '')
                         for root, dirs, files in os.walk(VIDEO_ROOT_PATH)
                         for file in files if os.path.splitext(file)[1].lower() in EXTENSIONS]:
        full_path = os.path.join(VIDEO_ROOT_PATH, partial_path)
        # http://stackoverflow.com/questions/2104080/how-to-check-file-size-in-python
        size = os.stat(full_path).st_size
        if size > MINIMUM_VIDEO_SIZE:
            session.add(Video(path=partial_path, size=size))
            session.commit()


def list_windows():
    """List current windows from selected applications.

    :return: Window titles grouped by application.
    :rtype dict
    """
    grep_args = ' -e '.join(APPS)
    t = pipes.Template()
    t.prepend('wmctrl -l -x', '.-')
    t.append('grep -e {}'.format(grep_args), '--')
    with t.open_r('pipefile') as f:
        lines = f.read()

    windows = {}
    for line in lines.split('\n'):
        words = line.split()
        if words:
            app = words[2]
            title = ' '.join(words[4:])
            if app not in windows.keys():
                windows[app] = [title]
            else:
                windows[app].append(title)
    return windows


def list_vlc_open_files():
    """List files opened by VLC in the root directory.

    :return: Files currently opened.
    :rtype list
    """
    t = pipes.Template()
    t.prepend('lsof -F n -c vlc 2>/dev/null', '.-')
    t.append("grep '^n{}'".format(VIDEO_ROOT_PATH), '--')
    with t.open_r('pipefile') as f:
        files = f.read()
    return files.strip().split('\n')


def window_monitor():
    """Loop to monitor open windows of the selected applications.
    An app can have multiple windows, each one with its title.

    :return:
    """
    last = {}
    monitor_start_time = datetime.now()
    time_format = '%H:%M:%S'
    try:
        while True:
            sleep(.2)

            for app, new_titles in list_windows().items():
                assert isinstance(new_titles, list)
                if app not in last.keys():
                    last[app] = defaultdict(tuple)

                for index, new_title in enumerate(new_titles):
                    if last[app][index] and last[app][index][1] == new_title:
                        continue

                    last_info = last[app][index]
                    start_time = last_info[0] if last_info else monitor_start_time
                    end_time = datetime.now()
                    old_title = last_info[1] if last_info else ''
                    diff = end_time - start_time
                    last[app][index] = (end_time, new_title)

                    if old_title:
                        # TODO Save to a log table
                        print('{start} to {end} ({diff}) {title} ({app})'.format(
                            app=app, title=old_title, diff=diff,
                            start=start_time.strftime(time_format),
                            end=end_time.strftime(time_format)))
    except KeyboardInterrupt:
        return

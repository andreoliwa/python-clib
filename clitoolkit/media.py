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
from subprocess import check_output, CalledProcessError

from sqlalchemy import create_engine, Column, Integer, String, DateTime, ForeignKey, event
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from sqlalchemy.engine import Engine


CONFIG_DIR = os.path.expanduser(os.path.join('~/.config/clitoolkit', ''))
os.makedirs(CONFIG_DIR, exist_ok=True)

EXTENSIONS = ['.asf', '.avi', '.divx', '.f4v', '.flc', '.flv', '.m4v', '.mkv',
              '.mov', '.mp4', '.mpa', '.mpeg', '.mpg', '.ogv', '.wmv']
MINIMUM_VIDEO_SIZE = 10 * 1000 * 1000  # 10 megabytes
VIDEO_ROOT_PATH = os.path.join(os.environ.get('VIDEO_ROOT_PATH', ''), '')
APPS = ['vlc.Vlc', 'feh.feh', 'google-chrome', 'Chromium-browser']
PIPEFILE = 'pipefile.tmp'

logger = logging.getLogger(__name__)
engine = create_engine('sqlite:///{}'.format(os.path.join(CONFIG_DIR, 'media.sqlite')), echo=True)
Base = declarative_base()
Session = sessionmaker(bind=engine)
session = Session()


@event.listens_for(Engine, "connect")
def enable_foreign_keys(dbapi_connection, connection_record):
    """Enable foreign keys in SQLite.
    See http://docs.sqlalchemy.org/en/rel_0_9/dialects/sqlite.html#sqlite-foreign-keys

    :param dbapi_connection:
    :param connection_record:
    """
    cursor = dbapi_connection.cursor()
    cursor.execute("PRAGMA foreign_keys=ON")
    cursor.close()


class Video(Base):
    """Video file, with path and size."""
    __tablename__ = 'video'

    video_id = Column(Integer, primary_key=True)
    path = Column(String, nullable=False, unique=True)
    size = Column(Integer, nullable=False)

    def __repr__(self):
        return "<Video(path='{}', size='{}')>".format(self.path, self.size)


class WindowLog(Base):
    """Log entry for an open window."""
    __tablename__ = 'window_log'

    window_id = Column(Integer, primary_key=True)

    start_dt = Column(DateTime, nullable=False)
    end_dt = Column(DateTime, nullable=False)
    app_name = Column(String, nullable=False)
    title = Column(String, nullable=False)

    video_id = Column(Integer, ForeignKey('video.video_id'))
    # video = relationship('Video', backref=backref('logs', order_by=window_id))

    def __repr__(self):
        return "<WindowLog(app='{}', title='{}')>".format(self.app_name, self.title)


def scan_video_files():
    """Scan all video files in subdirectories, ignoring videos with less than 10 MB.
    Save the videos in SQLite.

    :return: None
    """
    if not VIDEO_ROOT_PATH:
        logger.error('The environment variable VIDEO_ROOT_PATH must contain the video root directory')
        return

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
    with t.open_r(PIPEFILE) as f:
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
    with t.open_r(PIPEFILE) as f:
        files = f.read()
    return [file[1:] for file in files.strip().split('\n') if file]


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
                assert isinstance(app, str)
                assert isinstance(new_titles, list)

                if app not in last.keys():
                    last[app] = defaultdict(tuple)
                # TODO video_paths = list_vlc_open_files() if app.startswith('vlc') else []

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


def is_vlc_running():
    """Check if VLC is running.

    :return: True if VLC is running.
    :rtype bool
    """
    try:
        check_output(['pidof', 'vlc'])
        return True
    except CalledProcessError:
        return False


def add_to_playlist(videos):
    """Add one or more videos to VLC's playlist.

    :param videos: One or more video paths.
    :type videos list|str
    :return: True if videos were added to the playlist.
    :rtype bool
    """
    if not is_vlc_running():
        logger.error('VLC is not running, please open it first.')
        return False

    videos = [videos] if isinstance(videos, str) else videos
    t = pipes.Template()
    t.append('xargs -0 vlc --quiet --no-fullscreen --no-playlist-autostart --no-auto-preparse', '--')
    with t.open_w(PIPEFILE) as f:
        f.write('\0'.join(videos))
    return True


def filter_videos_by_path(query_string):
    """Return videos from the database based on a query string.
    All spaces in the query string will be converted to %, to be used in a LIKE expression.

    :param query_string:
    :type query_string str
    :return:
    """
    clean_query = '%{}%'.format('%'.join(query_string.split())) if query_string else None
    filter_string = Video.path.like(clean_query) if clean_query else ''
    return [os.path.join(VIDEO_ROOT_PATH, video.path)
            for video in session.query(Video).filter(filter_string).all()]


Base.metadata.create_all(engine)

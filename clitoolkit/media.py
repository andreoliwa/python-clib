# -*- coding: utf-8 -*-
"""Media tools."""
import os
import pipes
from collections import defaultdict
from datetime import datetime
from subprocess import CalledProcessError, check_output
from time import sleep

from sqlalchemy import or_
from sqlalchemy.orm.exc import NoResultFound

from clitoolkit import LOGGER, TIME_FORMAT, read_config
from clitoolkit.database import SESSION_INSTANCE, Video, WindowLog

EXTENSIONS = ['.asf', '.avi', '.divx', '.f4v', '.flc', '.flv', '.m4v', '.mkv',
              '.mov', '.mp4', '.mpa', '.mpeg', '.mpg', '.ogv', '.wmv']
MINIMUM_VIDEO_SIZE = 10 * 1000 * 1000  # 10 megabytes
APPS = ['vlc.Vlc', 'feh.feh', 'google-chrome', 'Chromium-browser.Chromium-browser', 'Navigator.Firefox']
PIPEFILE = 'pipefile.tmp'


def video_root_path():
    """Get the video root path from the config file.

    :return: Video root path.
    :raise ValueError: if the key is empty
    """
    path = os.path.join(read_config('dirs', 'video_root', ''), '')
    if not path:
        raise ValueError("The video_root key is empty in config.ini")
    return path


def scan_video_files():
    """Scan all video files in subdirectories, ignoring videos with less than 10 MB.

    Save the videos in SQLite.

    :return: None
    """
    video_path = video_root_path()
    # http://stackoverflow.com/questions/18394147/recursive-sub-folder-search-and-return-files-in-a-list-python
    for partial_path in [os.path.join(root, file).replace(video_path, '')
                         for root, dirs, files in os.walk(video_path)
                         for file in files if os.path.splitext(file)[1].lower() in EXTENSIONS]:
        full_path = os.path.join(video_path, partial_path)
        # http://stackoverflow.com/questions/2104080/how-to-check-file-size-in-python
        size = os.stat(full_path).st_size
        if size > MINIMUM_VIDEO_SIZE:
            SESSION_INSTANCE.add(Video(path=partial_path, size=size))
            SESSION_INSTANCE.commit()


def list_windows():
    """List current windows from selected applications.

    Always return at least one element in each application list, even if it's an empty title.
    This is needed by the window monitor to detect when an application was closed, and still log a title change.

    :return: Window titles grouped by application.
    :rtype: dict
    """
    grep_args = ' -e '.join(APPS)
    pipe = pipes.Template()
    pipe.prepend('wmctrl -l -x', '.-')
    pipe.append('grep -e {}'.format(grep_args), '--')
    with pipe.open_r(PIPEFILE) as handle:
        lines = handle.read()

    windows = {app: [] for app in APPS}
    for line in lines.split('\n'):
        words = line.split()
        if words:
            app = words[2]
            if app not in windows.keys():
                windows[app] = []
            title = ' '.join(words[4:])
            if app.startswith('vlc'):
                title = ''
                open_files = list_vlc_open_files(False)
                if open_files:
                    windows[app].extend(open_files)
                    continue
            windows[app].append(title)
    return {key: value if value else [''] for key, value in windows.items()}


def list_vlc_open_files(full_path=True):
    """List files opened by VLC in the root directory.

    :param full_path: True to show full path, False to strip the video root path.
    :return: Files currently opened.
    :rtype: list
    """
    video_path = video_root_path()
    pipe = pipes.Template()
    pipe.prepend('lsof -F n -c vlc 2>/dev/null', '.-')
    pipe.append("grep '^n{}'".format(video_path), '--')
    with pipe.open_r(PIPEFILE) as handle:
        files = handle.read()
    return [file[1:].replace(video_path, '') if not full_path else file[1:]
            for file in files.strip().split('\n') if file]


def window_monitor(save_logs=True):
    """Loop to monitor open windows of the selected applications.

    An app can have multiple windows, each one with its title.

    :param save_logs: True to save logs (default), False to only display what would be saved (dry run).
    :return:
    """
    # TODO: Convert data from $HOME/.gtimelog/window-monitor.db
    last = {}
    monitor_start_time = datetime.now()
    LOGGER.info('Starting the window monitor now (%s)...', monitor_start_time.strftime(TIME_FORMAT))
    if not save_logs:
        LOGGER.error('Not saving logs to the database')
    try:
        while True:
            sleep(.2)

            for app, new_titles in list_windows().items():
                assert isinstance(app, str)
                assert isinstance(new_titles, list)

                if app not in last.keys():
                    last[app] = defaultdict(tuple)

                for index, new_title in enumerate(new_titles):
                    if last[app][index] and last[app][index][1] == new_title:
                        continue

                    last_info = last[app][index]
                    # Time since last saved time, or since the beginning of the monitoring
                    start_time = last_info[0] if last_info else monitor_start_time
                    end_time = datetime.now()
                    # Save time info for the next change of window title
                    last[app][index] = (end_time, new_title)

                    # Save logs only after the first change of title
                    old_title = last_info[1] if last_info else ''
                    if old_title:
                        try:
                            video = SESSION_INSTANCE.query(Video).filter(Video.path == old_title).one()
                            video_id = video.video_id
                        except NoResultFound:
                            video_id = None

                        window_log = WindowLog(start_dt=start_time, end_dt=end_time, app_name=app,
                                               title=old_title, video_id=video_id)
                        LOGGER.info(window_log)
                        if save_logs:
                            SESSION_INSTANCE.add(window_log)
                            SESSION_INSTANCE.commit()

                    if new_title:
                        LOGGER.warning("%s Open window in %s: %s", end_time.strftime(TIME_FORMAT), app, new_title)
    except KeyboardInterrupt:
        return


def is_vlc_running():
    """Check if VLC is running.

    :return: True if VLC is running.
    :rtype: bool
    """
    try:
        check_output(['pidof', 'vlc'])
        return True
    except CalledProcessError:
        return False


def add_to_playlist(videos):
    """Add one or more videos to VLC's playlist.

    :param videos: One or more video paths.
    :type videos: list|str

    :return: True if videos were added to the playlist.
    :rtype: bool
    """
    if not is_vlc_running():
        os.system('$(which vlc) -q &')
        sleep(1)

    videos = [videos] if isinstance(videos, str) else videos
    pipe = pipes.Template()
    pipe.append('xargs -0 vlc --quiet --no-fullscreen --no-auto-preparse --no-playlist-autostart', '--')
    os.chdir(video_root_path())
    with pipe.open_w(PIPEFILE) as handle:
        handle.write('\0'.join(videos))
    LOGGER.info('%d videos added to the playlist.', len(videos))
    return True


def query_videos_by_path(search=None):
    """Return videos from the database based on a query string.

    All spaces in the query string will be converted to %, to be used in a LIKE expression.

    :param search: Optional query strings to search; if not provided, return all videos.
    :return:

    :type search: str|list
    """
    sa_filter = SESSION_INSTANCE.query(Video)
    if search:
        conditions = []
        search = [search] if isinstance(search, str) else search
        for query_string in search:
            clean_query = '%{}%'.format('%'.join(query_string.split()))
            conditions.append(Video.path.like(clean_query))
        sa_filter = sa_filter.filter(or_(*conditions))
    return query_to_list(sa_filter)


def query_to_list(sa_filter):
    """Output a SQLAlchemy Video query as a list of videos with full path.

    :param sa_filter: SQLAlchemy query filter.
    :type sa_filter: sqlalchemy.orm.query.Query
    :return: List of videos with full path.
    """
    return [os.path.join(video_root_path(), video.path) for video in sa_filter.all()]


def query_not_logged_videos():
    """Return videos that were not yet logged.

    :return:
    :rtype: list
    """
    return query_to_list(SESSION_INSTANCE.query(Video).outerjoin(
        WindowLog, Video.video_id == WindowLog.video_id).filter(WindowLog.video_id.is_(None)))

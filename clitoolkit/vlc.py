# -*- coding: utf-8 -*-
"""
VLC tools
"""
import os
import logging
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy import Column, Integer, String
from sqlalchemy.orm import sessionmaker

# Some valid video extensions (lowercase)
EXTENSIONS = ['.asf', '.avi', '.divx', '.f4v', '.flc', '.flv', '.m4v', '.mkv',
              '.mov', '.mp4', '.mpa', '.mpeg', '.mpg', '.ogv', '.wmv']
MINIMUM_VIDEO_SIZE = 10 * 1000 * 1000  # 10 megabytes
VLC_ROOT_PATH = os.path.join(os.environ.get('VLC_ROOT_PATH', ''), '')

logger = logging.getLogger(__name__)
engine = create_engine('sqlite:///:memory:', echo=True)
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
    if not VLC_ROOT_PATH:
        logger.error('The environment variable VLC_ROOT_PATH must contain the video root directory')
        return

    Base.metadata.create_all(engine)

    # http://stackoverflow.com/questions/18394147/recursive-sub-folder-search-and-return-files-in-a-list-python
    for partial_path in [os.path.join(root, file).replace(VLC_ROOT_PATH, '')
                         for root, dirs, files in os.walk(VLC_ROOT_PATH)
                         for file in files if os.path.splitext(file)[1].lower() in EXTENSIONS]:
        full_path = os.path.join(VLC_ROOT_PATH, partial_path)
        # http://stackoverflow.com/questions/2104080/how-to-check-file-size-in-python
        size = os.stat(full_path).st_size
        if size > MINIMUM_VIDEO_SIZE:
            session.add(Video(path=partial_path, size=size))
            session.commit()

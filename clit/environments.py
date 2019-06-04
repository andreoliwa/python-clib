# -*- coding: utf-8 -*-
"""Environment variables."""
import os
from typing import List

from prettyconf import config

from clit.config import cast_to_directory_list

config.starting_path = os.path.expanduser("~/.config/clit")

RSYNC_EXCLUDE: List[str] = config(
    "RSYNC_EXCLUDE", cast=config.list, default="lost+found/,.dropbox.cache,.Trash-*,.DS_Store"
)
BACKUP_DIRS: List[str] = config("BACKUP_DIRS", cast=cast_to_directory_list())
PICTURE_DIRS: List[str] = config("PICTURE_DIRS", cast=cast_to_directory_list())

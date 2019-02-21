"""Environment variables."""
import os
from typing import List  # noqa

from prettyconf import config

from libwaa.prettyconf import cast_to_directory_list

config.starting_path = os.path.expanduser("~/.config/clit")

RSYNC_EXCLUDE = config(
    "RSYNC_EXCLUDE", cast=config.list, default="lost+found/,.dropbox.cache,.Trash-*,.DS_Store"
)  # type: List[str]
BACKUP_DIRS = config("BACKUP_DIRS", cast=cast_to_directory_list())  # type: List[str]
PICTURE_DIRS = config("PICTURE_DIRS", cast=cast_to_directory_list())  # type: List[str]

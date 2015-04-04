# -*- coding: utf-8 -*-
"""Initialize the clitoolkit module."""
import os
import logging
from configparser import ConfigParser

from sqlalchemy import create_engine, event
from sqlalchemy.ext.declarative import declarative_base

from sqlalchemy.orm import sessionmaker
from colorlog import ColoredFormatter


__author__ = 'Wagner Augusto Andreoli'
__email__ = 'wagnerandreoli@gmail.com'
__version__ = '0.7.3'

CONFIG_DIR = os.path.expanduser(os.path.join('~/.config', os.path.basename(os.path.dirname(__file__)), ''))
os.makedirs(CONFIG_DIR, exist_ok=True)

CONFIG_FILENAME = os.path.join(CONFIG_DIR, 'config.ini')
CONFIG = ConfigParser()
# http://stackoverflow.com/questions/19359556/configparser-reads-capital-keys-and-make-them-lower-case
CONFIG.optionxform = str
CONFIG.read(CONFIG_FILENAME)

LOGGER = logging.getLogger(__name__)
LOGGER.setLevel(logging.INFO)
if not LOGGER.hasHandlers():
    CHANNEL = logging.StreamHandler()
    CHANNEL.setFormatter(
        ColoredFormatter(
            "%(log_color)s%(levelname)-8s%(reset)s %(blue)s%(message)s", datefmt=None,
            reset=True, log_colors={'DEBUG': 'cyan',
                                    'INFO': 'green',
                                    'WARNING': 'yellow',
                                    'ERROR': 'red',
                                    'CRITICAL': 'red,bg_white'},
            secondary_log_colors={}
        ))
    LOGGER.addHandler(CHANNEL)

ENGINE = create_engine('sqlite:///{}'.format(os.path.join(CONFIG_DIR, 'database.sqlite')))
BASE_MODEL = declarative_base()
SESSION_CLASS = sessionmaker(bind=ENGINE)
SESSION_INSTANCE = SESSION_CLASS()


def read_config(section_name, key_name, default=None):
    """Read a value from the config file.

    Create section and key in the config object, if they don't exist.
    The config must be saved with save_config(), to persist the values.

    :param section_name: Name of the section in the .ini file.
    :param key_name: Name of the key to read the value from.
    :param default: Default value in case the key doesn't exist.
    :return: Section if key_name is empty; otherwise, return the key value or the default.
    """
    try:
        section = CONFIG[section_name]
    except KeyError:
        CONFIG[section_name] = {}
        section = CONFIG[section_name]
    if not key_name:
        return section

    try:
        return section[key_name]
    except KeyError:
        section[key_name] = default
        return section[key_name]


def save_config():
    """Save the config file."""
    os.makedirs(os.path.dirname(CONFIG_FILENAME), exist_ok=True)
    with open(CONFIG_FILENAME, 'w') as handle:
        CONFIG.write(handle)


@event.listens_for(ENGINE, "connect")
def enable_foreign_keys(dbapi_connection, connection_record):
    """Enable foreign keys in SQLite.

    See http://docs.sqlalchemy.org/en/rel_0_9/dialects/sqlite.html#sqlite-foreign-keys

    :param dbapi_connection:
    :param connection_record:
    """
    assert connection_record
    cursor = dbapi_connection.cursor()
    cursor.execute("PRAGMA foreign_keys=ON")
    cursor.close()


BASE_MODEL.metadata.create_all(ENGINE)

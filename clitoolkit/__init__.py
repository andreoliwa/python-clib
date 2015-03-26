# -*- coding: utf-8 -*-
"""
Initialize the clitoolkit module.
"""
import os
import logging
from configparser import ConfigParser

from colorlog import ColoredFormatter


__author__ = 'Wagner Augusto Andreoli'
__email__ = 'wagnerandreoli@gmail.com'
__version__ = '0.7.1'

config_filename = os.path.expanduser(os.path.join(
    '~/.config', os.path.basename(os.path.dirname(__file__)), 'config.ini'))
config = ConfigParser()
# http://stackoverflow.com/questions/19359556/configparser-reads-capital-keys-and-make-them-lower-case
config.optionxform = str
config.read(config_filename)

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)
if not logger.hasHandlers():
    ch = logging.StreamHandler()
    ch.setFormatter(
        ColoredFormatter(
            "%(log_color)s%(levelname)-8s%(reset)s %(blue)s%(message)s", datefmt=None,
            reset=True, log_colors={'DEBUG': 'cyan',
                                    'INFO': 'green',
                                    'WARNING': 'yellow',
                                    'ERROR': 'red',
                                    'CRITICAL': 'red,bg_white',
                                    },
            secondary_log_colors={}
        ))
    logger.addHandler(ch)


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
        section = config[section_name]
    except KeyError:
        config[section_name] = {}
        section = config[section_name]
    if not key_name:
        return section

    try:
        return section[key_name]
    except KeyError:
        section[key_name] = default
        return section[key_name]


def save_config():
    """Save the config file."""
    os.makedirs(os.path.dirname(config_filename), exist_ok=True)
    with open(config_filename, 'w') as fp:
        config.write(fp)

# -*- coding: utf-8 -*-
import logging
import os

from clitoolkit import read_config, save_config


def create_symbolic_links():
    """Create symbolic links for files and dirs, following what's stored on the config file."""
    dot_files_dir = read_config(
        'dirs', 'dotfiles', os.path.realpath(os.path.join(os.path.dirname(__file__), '../dotfiles')))
    if not os.path.exists(dot_files_dir):
        logging.warning("The directory '%s' does not exist", dot_files_dir)
        return False

    cut = len(dot_files_dir) + 1
    for root, dirs, files in os.walk(dot_files_dir):
        for file in files:
            key = os.path.join(root, file)[cut:]
            target = read_config('file_links', key, '')
            print("File '{}' points to '{}'".format(key, target))
    save_config()

    # TODO Warn if link exists
    # TODO Warn if a dotfile has no json config
    # TODO Warn if a json config has no real file
    # TODO Create if the target exists and the link doesn't
    return True

# -*- coding: utf-8 -*-
"""Files, symbolic links, operating system utilities."""
import os
from clitoolkit import logger, read_config, save_config


def create_symbolic_links():
    """Create symbolic links for files and dirs, following what's stored on the config file."""
    dot_files_dir = read_config(
        'dirs', 'dotfiles', os.path.realpath(os.path.join(os.path.dirname(__file__), '../dotfiles')))
    if not os.path.exists(dot_files_dir):
        logger.warning("The directory '%s' does not exist", dot_files_dir)
        return

    links = {}
    cut = len(dot_files_dir) + 1
    for root, _, files in os.walk(dot_files_dir):
        for one_file in files:
            source_file = os.path.join(root, one_file)
            key = source_file[cut:]
            raw_link_name = read_config('symlinks/files', key, '')
            links[key] = (source_file, raw_link_name)
    # http://stackoverflow.com/questions/9001509/how-can-i-sort-a-python-dictionary-sort-by-key/13990710#13990710
    for key in sorted(links):
        (source_file, raw_link_name) = links[key]
        create_link(key, source_file, raw_link_name)

    save_config()


def create_link(key, source_file, raw_link):
    """Check and create a symbolic link.

    :param key: Key name in the config.ini file.
    :param source_file: Full path to the source file that will be linked.
    :param raw_link: Raw destination link taken from config.ini.
    :return:
    """
    message = ''
    final_link = raw_link
    if not raw_link:
        message = 'empty link in the config file.'
    else:
        expanded_link = os.path.expanduser(raw_link)
        if os.path.isdir(expanded_link):
            final_link = os.path.join(expanded_link, os.path.basename(source_file))
        else:
            final_link = expanded_link

        if os.path.islink(final_link):
            message = 'link already exists.'
            # TODO Check if the link is already pointing to the source_file
            # TODO If 'yes', logger.info(); if 'no', logger.warning()
        elif os.path.isfile(final_link):
            message = 'file already exists.'
            # TODO Check if both files are the same (call the 'diff' utility)
            # TODO If files are identical, rename the target and continue with link creation

    log_func = logger.warning if message else logger.info
    log_func("'{}' -> '{}' ({})".format(key, final_link, message))
    # TODO Create if the target exists and the link doesn't

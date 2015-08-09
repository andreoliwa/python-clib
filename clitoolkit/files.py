# -*- coding: utf-8 -*-
"""Files, symbolic links, operating system utilities."""
import os

import click

from clitoolkit import CONFIG, LOGGER, read_config, save_config

SECTION_SYMLINKS_FILES = 'symlinks/files'
SECTION_SYMLINKS_DIRS = 'symlinks/dirs'


@click.command()
def create_symbolic_links():
    """Create symbolic links for files and dirs, following what's stored on the config file."""
    dot_files_dir = read_config(
        'dirs', 'dotfiles', os.path.realpath(os.path.join(os.path.dirname(__file__), '../dotfiles')))
    if not os.path.exists(dot_files_dir):
        LOGGER.warning("The directory '%s' does not exist", dot_files_dir)
        return
    LOGGER.info("Directory with dot files: '%s'", dot_files_dir)

    LOGGER.info("Creating links for files in [%s]", SECTION_SYMLINKS_FILES)
    links = {}
    cut = len(dot_files_dir) + 1
    for root, _, files in os.walk(dot_files_dir):
        for one_file in files:
            source_file = os.path.join(root, one_file)
            key = source_file[cut:]
            raw_link_name = read_config(SECTION_SYMLINKS_FILES, key, '')
            links[key] = (source_file, raw_link_name)
    # http://stackoverflow.com/questions/9001509/how-can-i-sort-a-python-dictionary-sort-by-key/13990710#13990710
    for key in sorted(links):
        (source_file, raw_link_name) = links[key]
        create_link(key, source_file, raw_link_name, False)

    LOGGER.info("Creating links for dirs in [%s]", SECTION_SYMLINKS_DIRS)
    if CONFIG.has_section(SECTION_SYMLINKS_DIRS):
        for key in CONFIG.options(SECTION_SYMLINKS_DIRS):
            raw_link_name = read_config(SECTION_SYMLINKS_DIRS, key, '')
            create_link(key, key, raw_link_name, True)

    save_config()


def create_link(key, source_file, raw_link, is_dir):
    """Check and create a symbolic link.

    :param key: Key name in the config.ini file.
    :param source_file: Full path to the source file that will be linked.
    :param raw_link: Raw destination link taken from config.ini.
    :param is_dir: Consider the paths as directories.
    :return:
    """
    def message(text, logger_func=LOGGER.warning):
        """Show a message with details about the links and files.

        :param text: Text to be shown.
        :param logger_func: Logger function to be used.
        :return:
        """
        logger_func("%s -> '%s': %s", key, final_link, text)

    if is_dir:
        # In config.ini, a dir can contain the char "~" in the key
        source_file = os.path.expanduser(source_file)

    final_link = raw_link
    if not raw_link:
        message('empty link in the config file')
        return

    expanded_link = os.path.expanduser(raw_link)
    if raw_link == '~' or expanded_link.endswith('/'):
        # Append the basename when the dir ends with a slash
        final_link = os.path.join(expanded_link, os.path.basename(source_file))
    else:
        final_link = expanded_link

    if os.path.islink(final_link):
        try:
            if os.path.samefile(source_file, final_link):
                message('link already exists', LOGGER.info)
                return
            message('link already exists, but points to a different file')
        except FileNotFoundError as err:
            message('file not found? {}'.format(err), LOGGER.error)
        return
    elif os.path.isfile(final_link):
        if os.path.samefile(source_file, final_link):
            message("an identical file already exists; it can be manually replaced")
            return
        message("a file with the same name already exists, and they are not the same. "
                "Try comparing the files with:\nmeld '{}' '{}'".format(source_file, final_link), LOGGER.error)
        return

    os.symlink(source_file, final_link, target_is_directory=not is_dir)
    message('link created', LOGGER.info)

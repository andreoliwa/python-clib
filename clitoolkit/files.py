# -*- coding: utf-8 -*-
"""Files, symbolic links, operating system utilities."""
import os
from shlex import split
from subprocess import call, check_output
from typing import List

import click
import crayons
from plumbum.cmd import rsync

from clitoolkit import CONFIG, LOGGER, read_config, save_config

SECTION_SYMLINKS_FILES = 'symlinks/files'
SECTION_SYMLINKS_DIRS = 'symlinks/dirs'
PYCHARM_APP_FULL_PATH = '/Applications/PyCharm.app/Contents/MacOS/pycharm'


@click.command()
def create_symbolic_links():
    """Create symbolic links for files and dirs, following what's stored on the config file."""
    dot_files_dir = read_config(
        'dirs', 'dotfiles', os.path.realpath(os.path.join(os.path.dirname(__file__), '../dotfiles')))
    if not os.path.exists(dot_files_dir):
        LOGGER.warning("The directory '%s' does not exist", dot_files_dir)
        return
    LOGGER.info("Directory with dot files: '%s'", dot_files_dir)

    LOGGER.info('Creating links for files in [%s]', SECTION_SYMLINKS_FILES)
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

    LOGGER.info('Creating links for dirs in [%s]', SECTION_SYMLINKS_DIRS)
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
            message('an identical file already exists; it can be manually replaced')
            return
        message('a file with the same name already exists, and they are not the same. '
                "Try comparing the files with:\nmeld '{}' '{}'".format(source_file, final_link), LOGGER.error)
        return

    os.symlink(source_file, final_link, target_is_directory=not is_dir)
    message('link created', LOGGER.info)


@click.command()
@click.argument('files', nargs=-1)
def pycharm_cli(files):
    """Invoke PyCharm on the command line.

    If a file doesn't exist, call `which` to find out the real location.
    """
    full_paths = []
    for possible_file in files:
        if os.path.isfile(possible_file):
            real_file = os.path.abspath(possible_file)
        else:
            real_file = check_output(['which', possible_file]).decode().strip()
        full_paths.append(real_file)
    command_line = [PYCHARM_APP_FULL_PATH] + full_paths
    print(crayons.green('Calling PyCharm with {}'.format(' '.join(command_line))))
    call(command_line)


def sync_dir(source_dirs: List[str], destination_dirs: List[str], dry_run: bool=False, kill: bool=False):
    """Synchronize a source directory with a destination."""
    from clitoolkit.environments import RSYNC_EXCLUDE

    for dest_dir in destination_dirs:
        for src_dir in source_dirs:
            # Remove the user home and concatenate the source after the destination
            full_dest_dir = os.path.join(dest_dir, src_dir.replace(os.path.expanduser('~'), '')[1:])

            rsync_args = '{dry_run}{kill}-trOlhDuzv --modify-window=2 --progress {exclude} {src}/ {dest}/'.format(
                dry_run='-n ' if dry_run else '',
                kill='--del ' if kill else '',
                exclude=' '.join(['--exclude={}'.format(e) for e in RSYNC_EXCLUDE]),
                src=src_dir,
                dest=full_dest_dir,
            )
            print('Backing up source directory with', crayons.green('rsync {}'.format(rsync_args)))
            os.makedirs(full_dest_dir, exist_ok=True)
            command = rsync[split(rsync_args)]
            rv = command()
            print(rv)


@click.command()
@click.option('--dry-run', '-n', default=False, is_flag=True, help='Dry-run')
@click.option('--kill', '-k', default=False, is_flag=True, help='Kill files when using rsync (--del)')
@click.option('--pictures', '-p', default=False, is_flag=True, help='Backup pictures')
@click.pass_context
def backup_full(ctx, dry_run: bool, kill: bool, pictures: bool):
    """Perform all backups in a single script."""
    if pictures:
        print(crayons.green('Pictures backup', bold=True))
        from clitoolkit.environments import PICTURE_DIRS, BACKUP_DIRS
        sync_dir(PICTURE_DIRS, BACKUP_DIRS, dry_run, kill)
    else:
        print(crayons.red('Choose one of the options below.'))
        print(ctx.get_help())


if __name__ == '__main__':
    backup_full()

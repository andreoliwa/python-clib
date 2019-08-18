# -*- coding: utf-8 -*-
"""Files, symbolic links, operating system utilities."""
import os
from argparse import ArgumentTypeError
from pathlib import Path
from shlex import split
from subprocess import PIPE, run
from time import sleep
from typing import List

import click
from plumbum import FG

from clib import CONFIG, DRY_RUN_OPTION, LOGGER, read_config, save_config

SECTION_SYMLINKS_FILES = "symlinks/files"
SECTION_SYMLINKS_DIRS = "symlinks/dirs"


@click.command()
def create_symbolic_links():
    """Create symbolic links for files and dirs, following what's stored on the config file."""
    dot_files_dir = read_config(
        "dirs", "dotfiles", os.path.realpath(os.path.join(os.path.dirname(__file__), "../dotfiles"))
    )
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
            raw_link_name = read_config(SECTION_SYMLINKS_FILES, key, "")
            links[key] = (source_file, raw_link_name)
    # http://stackoverflow.com/questions/9001509/how-can-i-sort-a-python-dictionary-sort-by-key/13990710#13990710
    for key in sorted(links):
        (source_file, raw_link_name) = links[key]
        create_link(key, source_file, raw_link_name, False)

    LOGGER.info("Creating links for dirs in [%s]", SECTION_SYMLINKS_DIRS)
    if CONFIG.has_section(SECTION_SYMLINKS_DIRS):
        for key in CONFIG.options(SECTION_SYMLINKS_DIRS):
            raw_link_name = read_config(SECTION_SYMLINKS_DIRS, key, "")
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
        message("empty link in the config file")
        return

    expanded_link = os.path.expanduser(raw_link)
    if raw_link == "~" or expanded_link.endswith("/"):
        # Append the basename when the dir ends with a slash
        final_link = os.path.join(expanded_link, os.path.basename(source_file))
    else:
        final_link = expanded_link

    if os.path.islink(final_link):
        try:
            if os.path.samefile(source_file, final_link):
                message("link already exists", LOGGER.info)
                return
            message("link already exists, but points to a different file")
        except FileNotFoundError as err:
            message("file not found? {}".format(err), LOGGER.error)
        return
    elif os.path.isfile(final_link):
        if os.path.samefile(source_file, final_link):
            message("an identical file already exists; it can be manually replaced")
            return
        message(
            "a file with the same name already exists, and they are not the same. "
            "Try comparing the files with:\nmeld '{}' '{}'".format(source_file, final_link),
            LOGGER.error,
        )
        return

    os.symlink(source_file, final_link, target_is_directory=not is_dir)
    message("link created", LOGGER.info)


def sync_dir(source_dirs: List[str], destination_dirs: List[str], dry_run: bool = False, kill: bool = False):
    """Synchronize a source directory with a destination."""
    # Import locally, so we get an error only in this function, and not in other functions of this module.
    from plumbum.cmd import rsync
    from clib.environments import RSYNC_EXCLUDE

    for dest_dir in destination_dirs:
        for src_dir in source_dirs:
            # Remove the user home and concatenate the source after the destination
            full_dest_dir = os.path.join(dest_dir, src_dir.replace(os.path.expanduser("~"), "")[1:])

            rsync_args = "{dry_run}{kill}-trOlhDuzv --modify-window=2 --progress {exclude} {src}/ {dest}/".format(
                dry_run="-n " if dry_run else "",
                kill="--del " if kill else "",
                exclude=" ".join([f"--exclude={e}" for e in RSYNC_EXCLUDE]),
                src=src_dir,
                dest=full_dest_dir,
            )
            click.secho(f"rsync {rsync_args}", fg="green")
            os.makedirs(full_dest_dir, exist_ok=True)
            rsync[split(rsync_args)] & FG


@click.command()
@DRY_RUN_OPTION
@click.option("--kill", "-k", default=False, is_flag=True, help="Kill files when using rsync (--del)")
@click.option("--pictures", "-p", default=False, is_flag=True, help="Backup pictures")
@click.pass_context
def backup_full(ctx, dry_run: bool, kill: bool, pictures: bool):
    """Perform all backups in a single script."""
    if pictures:
        click.secho("Pictures backup", bold=True, fg="green")
        from clib.environments import PICTURE_DIRS, BACKUP_DIRS

        sync_dir(PICTURE_DIRS, BACKUP_DIRS, dry_run, kill)
    else:
        click.secho("Choose one of the options below.", fg="red")
        print(ctx.get_help())


def shell(
    command_line,
    quiet=False,
    exit_on_failure: bool = False,
    return_lines=False,
    dry_run=False,
    header: str = "",
    **kwargs,
):
    """Print and run a shell command.

    :param quiet: Don't print the command line that will be executed.
    :param exit_on_failure: Exit if the command failed (return code is not zero).
    :param return_lines: Return a list of lines instead of a ``CompletedProcess`` instance.
    :param dry_run: Only print the command that would be executed, and return.
    :param header: Print a header before the command.
    """
    if not quiet or dry_run:
        if header:
            click.secho(f"\n# {header}", fg="bright_white")
        click.secho("$ ", fg="magenta", nl=False)
        click.secho(command_line, fg="yellow")
        if dry_run:
            return
    if return_lines:
        kwargs.setdefault("stdout", PIPE)

    completed_process = run(command_line, shell=True, universal_newlines=True, **kwargs)
    if exit_on_failure and completed_process.returncode != 0:
        exit(completed_process.returncode)

    if not return_lines:
        return completed_process

    stdout = completed_process.stdout.strip().strip("\n")
    return stdout.split("\n") if stdout else []


def shell_find(command_line, **kwargs) -> List[str]:
    """Run a find command using the shell, and return its output as a list."""
    if not command_line.startswith("find"):
        command_line = f"find {command_line}"
    kwargs.setdefault("quiet", True)
    kwargs.setdefault("check", True)
    return shell(command_line, return_lines=True, **kwargs)


def _check_type(full_path, method, msg):
    """Check a path, raise an error if it's not valid."""
    obj = Path(full_path)
    if not method(obj):
        raise ArgumentTypeError(f"{full_path} is not a valid existing {msg}")
    return obj


def existing_directory_type(directory):
    """Convert the string to a Path object, raising an error if it's not a directory. Use with argparse."""
    return _check_type(directory, Path.is_dir, "directory")


def existing_file_type(file):
    """Convert the string to a Path object, raising an error if it's not a file. Use with argparse."""
    return _check_type(file, Path.is_file, "file")


def wait_for_process(process_name: str) -> None:
    """Wait for a process to finish.

    https://stackoverflow.com/questions/1058047/wait-for-any-process-to-finish
    """
    pid = shell(f"pidof {process_name}", quiet=True, stdout=PIPE).stdout.strip()
    if not pid:
        return

    pid_path = Path(f"/proc/{pid}")
    while pid_path.exists():
        sleep(0.5)


@click.command()
@DRY_RUN_OPTION
@click.argument("directories", nargs=-1, required=True, type=click.Path(exists=True), metavar="[DIR1 [DIR2]...]")
def rm_broken_symlinks(dry_run: bool, directories):
    """Remove broken symlinks from directories (asks for confirmation)."""
    if dry_run:
        click.secho("[DRY-RUN]", fg="cyan")

    clean_dirs = [dir_str.rstrip("/") for dir_str in directories]
    base_command = "find {dir} -type l ! -exec test -e {{}} \; -print{extra}"

    all_broken_links = []
    for clean_dir in clean_dirs:
        broken_links = shell_find(base_command.format(dir=clean_dir, extra=""), quiet=False)
        all_broken_links.extend(broken_links)
        for file in broken_links:
            click.echo(file)
    if not all_broken_links:
        click.secho("There are no broken links to be removed", fg="green")
        exit(0)
    if dry_run:
        exit(0)

    click.confirm("These broken links will be removed. Continue?", default=False, abort=True)

    for clean_dir in clean_dirs:
        click.secho(f"Removing broken symlinks in {click.format_filename(clean_dir)}...", fg="green")
        shell(base_command.format(dir=clean_dir, extra=" -delete"))

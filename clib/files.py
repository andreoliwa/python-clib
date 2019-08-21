# -*- coding: utf-8 -*-
"""Files, symbolic links, operating system utilities."""
import os
import re
from argparse import ArgumentTypeError
from parser import ParserError
from pathlib import Path
from shlex import split
from subprocess import PIPE, run
from time import sleep
from typing import List

import click
import pendulum
from plumbum import FG
from slugify import slugify

from clib import DRY_RUN_OPTION

# DATE_REGEX = re.compile(r"(\d{2}[-_\.]?\d{2}[-_\.]?(19\d{2}|20\d{2})|(19\d{2}|20\d{2})[-_\.]?\d{2}[-_\.]?\d{2})")
DATE_REGEX = re.compile(r"([0-9][0-9-_\.]+[0-9])")
UNDERLINE_LOWER_CASE_REGEX = re.compile(r"_[a-z]")
POSSIBLE_FORMATS = (
    # Human formats first
    "MM_YYYY",
    "DD_MM_YYYY",
    "DD_MM_YY",
    "DDMMYYYY",
    "DD_MM_YYYY_HH_mm_ss",
    "DD_MM_YY_HH_mm_ss",
    # Then inverted formats
    "YYYY_MM",
    "YYYY_MM_DD",
    "YYYYMMDD",
    "YY_MM_DD_HH_mm_ss",
    "YYYY_MM_DD_HH_mm_ss",
    "YYYYMMDDHHmmss",
)


def sync_dir(source_dirs: List[str], destination_dirs: List[str], dry_run: bool = False, kill: bool = False):
    """Synchronize a source directory with a destination."""
    # Import locally, so we get an error only in this function, and not in other functions of this module.
    from plumbum.cmd import rsync
    from clib.environments import RSYNC_EXCLUDE

    for dest_dir in destination_dirs:
        if not dest_dir:
            continue
        for src_dir in source_dirs:
            if not src_dir:
                continue
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
    base_command = r"find {dir} -type l ! -exec test -e {{}} \; -print{extra}"

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


def slugify_camel_iso(old_string: str) -> str:
    """Slugify a string with camel case, underscores and ISO date/time formats.

    >>> slugify_camel_iso("some name Here 2017_12_30")
    'Some_Name_Here_2017-12-30'
    >>> slugify_camel_iso("DONT_PAY_this-bill-10-05-2015")
    'Dont_Pay_This_Bill_2015-05-10'
    >>> slugify_camel_iso("normal DATE 01012019 with no DASHES")
    'Normal_Date_2019-01-01_With_No_Dashes'
    >>> slugify_camel_iso("normal DATE 23_05_2019 with underscores")
    'Normal_Date_2019-05-23_With_Underscores'
    >>> slugify_camel_iso("inVerTed DATE 20191020 with no DASHES")
    'Inverted_Date_2019-10-20_With_No_Dashes'
    >>> slugify_camel_iso("blablabla-SCREAM LOUD AGAIN - XXX UTILIZAÇÃO 27.11.17")
    'Blablabla_Scream_Loud_Again_Xxx_Utilizacao_2017-11-27'
    >>> slugify_camel_iso("something-614 ATA AUG IN 25-04-17")
    'Something_614_Ata_Aug_In_2017-04-25'
    >>> slugify_camel_iso("inverted 2017_12_30_10_44_56 bla")
    'Inverted_2017-12-30T10-44-56_Bla'
    >>> slugify_camel_iso("normal 30.12.2017_10_44_56 bla")
    'Normal_2017-12-30T10-44-56_Bla'
    >>> slugify_camel_iso(" no day inverted 1975 08 ")
    'No_Day_Inverted_1975-08'
    >>> slugify_camel_iso(" no day normal 08 1975 ")
    'No_Day_Normal_1975-08'
    """
    # TODO
    # >>> slugify_camel_iso("WhatsApp Ptt 2019-08-21 at 14.24.19")
    # 'Whatsapp_Ptt_2019-08-21T14-24-19'
    new_string = slugify(old_string, separator="_").capitalize()
    new_string = UNDERLINE_LOWER_CASE_REGEX.sub(lambda matchobj: matchobj.group(0).upper(), new_string)

    def try_date(matchobj):
        original_string = matchobj.group(0)
        actual_date = None
        which_format = "YYYY-MM-DD"
        for date_format in POSSIBLE_FORMATS:
            # Only try formats with the same size; Pendulum is too permissive and returns wrong dates.
            if len(original_string) != len(date_format):
                continue

            try:
                actual_date = pendulum.from_format(original_string, date_format)
                if "HH" in date_format:
                    which_format = "YYYY-MM-DDTHH-mm-ss"
                elif "DD" not in date_format:
                    which_format = "YYYY-MM"
                break
            except ValueError:
                continue
            if actual_date is None:
                try:
                    actual_date = pendulum.parse(original_string, strict=False)
                except (ValueError, ParserError):
                    continue

        return actual_date.format(which_format) if actual_date else original_string

    new_string = DATE_REGEX.sub(try_date, new_string)
    return new_string


def rename_batch(dry_run: bool, which_type: str, root_dir: Path, items: List[Path]) -> bool:
    """Rename a batch of items (directories or files)."""
    pairs = []
    for item in sorted(items):
        new_name = slugify_camel_iso(item.stem) + item.suffix.lower()

        if item.name == new_name:
            continue

        relative_dir = str(item.parent.relative_to(root_dir))

        if dry_run:
            click.secho("[dry-run] ", fg="bright_red", nl=False)
        click.echo(f"from: {relative_dir}/{item.name}")
        if dry_run:
            click.secho("[dry-run] ", fg="bright_red", nl=False)
        click.echo(f"  to: {relative_dir}/", nl=False)
        click.secho(new_name, fg="green")
        pairs.append((item, item.with_name(new_name)))

    if not dry_run and pairs:
        click.confirm(f"Rename these {which_type}?", default=False, abort=True)
        for original, new in pairs:
            os.rename(original, new)
        click.secho(f"{which_type.capitalize()} renamed succesfully.", fg="green")

    return bool(pairs)


@click.command()
@DRY_RUN_OPTION
@click.argument("directories", nargs=-1, type=click.Path(exists=True, file_okay=False, dir_okay=True), required=True)
def rename_slugify(dry_run: bool, directories):
    """Rename files recursively, slugifying them. Format dates in file names as ISO. Ignore hidden files."""
    for directory in directories:
        original_dir = Path(directory)

        # Rename directories first
        rename_batch(
            dry_run,
            "directories",
            original_dir,
            [item for item in original_dir.glob("**/*") if item.is_dir() and not item.name.startswith(".")],
        )

        # Glob the renamed directories for files
        files_found = rename_batch(
            dry_run,
            "files",
            original_dir,
            [item for item in original_dir.glob("**/*") if not item.is_dir() and not item.name.startswith(".")],
        )

        if not files_found:
            click.secho("All files already have correct names.")

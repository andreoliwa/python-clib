"""Files, symbolic links, operating system utilities."""

import os
import sys
from argparse import ArgumentTypeError
from pathlib import Path
from shlex import split
from subprocess import PIPE, run
from time import sleep
from typing import Any, List, Optional

import click
from plumbum import FG

from clib import dry_run_option
from clib.ui import echo_dry_run


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
@dry_run_option
@click.option("--kill", "-k", default=False, is_flag=True, help="Kill files when using rsync (--del)")
@click.option("--pictures", "-p", default=False, is_flag=True, help="Backup pictures")
@click.pass_context
def backup_full(ctx, dry_run: bool, kill: bool, pictures: bool):
    """Perform all backups in a single script."""
    if pictures:
        from clib.environments import BACKUP_DIRS, PICTURE_DIRS

        click.secho("Pictures backup", bold=True, fg="green")
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
        sys.exit(completed_process.returncode)

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


def fzf(
    items: List[Any], *, reverse=False, query: str = None, auto_select: bool = None, exit_no_match: bool = None
) -> Optional[str]:
    """Run fzf to select among multiple choices."""
    choices = "\n".join([str(item) for item in items])

    query_opt = ""
    if query:
        query_opt = f" --query={query}"
        # If there is a query, set auto-select flags when no explicit booleans were informed
        if auto_select is None:
            auto_select = True
        if exit_no_match is None:
            exit_no_match = True

    select_one_opt = " --select-1" if auto_select else ""
    tac_opt = " --tac" if reverse else ""
    exit_zero_opt = " --exit-0" if exit_no_match else ""

    return min(
        shell(
            f'echo "{choices}" | fzf --height 40% --reverse --inline-info '
            f"{query_opt}{tac_opt}{select_one_opt}{exit_zero_opt} --cycle",
            quiet=True,
            return_lines=True,
        ),
        default=None,
    )


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
@dry_run_option
@click.argument("directories", nargs=-1, required=True, type=click.Path(exists=True), metavar="[DIR1 [DIR2]...]")
def rm_broken_symlinks(dry_run: bool, directories):
    """Remove broken symlinks from directories (asks for confirmation)."""
    clean_dirs = [dir_str.rstrip("/") for dir_str in directories]
    base_command = r"find {dir} -type l ! -exec test -e {{}} \; -print{extra}"

    all_broken_links = []
    for clean_dir in clean_dirs:
        broken_links = shell_find(base_command.format(dir=clean_dir, extra=""), quiet=False)
        all_broken_links.extend(broken_links)
        for file in broken_links:
            echo_dry_run(file, dry_run=dry_run)
    if not all_broken_links:
        echo_dry_run("There are no broken links to be removed", dry_run=dry_run, fg="green")
        exit(0)
    if dry_run:
        exit(0)

    click.confirm("These broken links will be removed. Continue?", default=False, abort=True)

    for clean_dir in clean_dirs:
        click.secho(f"Removing broken symlinks in {click.format_filename(clean_dir)}...", fg="green")
        shell(base_command.format(dir=clean_dir, extra=" -delete"))

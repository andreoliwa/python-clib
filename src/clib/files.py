"""Files, symbolic links, operating system utilities."""
import os
import re
import sys
import unicodedata
from argparse import ArgumentTypeError
from pathlib import Path
from shlex import split
from subprocess import PIPE, run
from time import sleep
from typing import Any, List, Optional, Set, Union

import click
import pendulum
from plumbum import FG
from slugify import slugify

from clib import dry_run_option, verbose_option, yes_option
from clib.constants import COLOR_OK

SLUG_SEPARATOR = "_"
REGEX_EXISTING_TIME = re.compile(r"(-[0-9]{2})[ _]?[Aa]?[Tt][ _]?([0-9]{2}[-._])")
REGEX_UPPER_CASE_LETTER = re.compile(r"([a-z])([A-Z]+)")
REGEX_UNDERLINE_LOWER_CASE = re.compile("_[a-z]")
REGEX_DATE_TIME = re.compile(r"([0-9][0-9-_\.]+[0-9])")
REGEX_MULTIPLE_SEPARATORS = re.compile("_+")

POSSIBLE_FORMATS = (
    # Human formats first
    "MM_YYYY",
    "DD_MM_YYYY",
    "DD_MM_YY",
    "DDMMYYYY",
    "DDMMYY",
    "DD_MM_YYYY_HH_mm_ss",
    "DD_MM_YY_HH_mm_ss",
    "DDMMYYYYHHmm",
    # Then inverted formats
    "YYYY_MM",
    "YYYY_MM_DD",
    "YYYYMMDD",
    "YY_MM_DD_HH_mm_ss",
    "YYYY_MM_DD_HH_mm_ss",
    "YYYYMMDDHHmmss",
    "YYYYMMDD_HHmmss",
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
            f'echo "{choices}" | fzf --height={len(items) + 2}'
            f"{query_opt}{tac_opt}{select_one_opt}{exit_zero_opt} --cycle",
            quiet=True,
            return_lines=True,
        ),
        default=None,
    )


def relative_to_home(full_path: Union[str, Path]):
    """Return a directory with ``~`` instead of printing the home dir full path."""
    path_obj = Path(full_path)
    return "~/{}".format(path_obj.relative_to(path_obj.home()))


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
    >>> slugify_camel_iso("inverted DATE 20191020 with no DASHES")
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
    >>> slugify_camel_iso(" CamelCase pascalCase JSONfile WhatsApp")
    'Camel_Case_Pascal_Case_Jsonfile_Whats_App'
    >>> slugify_camel_iso(" 2019-08-22T16-01-22 keep formatted times ")
    '2019-08-22T16-01-22_Keep_Formatted_Times'
    >>> slugify_camel_iso("WhatsApp Ptt 2019-08-21 at 14.24.19")
    'Whats_App_Ptt_2019-08-21T14-24-19'
    >>> slugify_camel_iso("Whats_App_Image_2019-08-23_At_12_34_55 fix times on whatsapp files")
    'Whats_App_Image_2019-08-23T12-34-55_Fix_Times_On_Whatsapp_Files'
    >>> slugify_camel_iso("Whats_App_Zip_2019-08-23_At_13_23.36")
    'Whats_App_Zip_2019-08-23T13-23-36'
    >>> slugify_camel_iso("fwdConsultaCognicao")
    'Fwd_Consulta_Cognicao'
    >>> slugify_camel_iso("bla Bancários - Atenção ble")
    'Bla_Bancarios_Atencao_Ble'
    >>> slugify_camel_iso(" 240819 human day month year 290875 ")
    '2019-08-24_Human_Day_Month_Year_1975-08-29'
    >>> slugify_camel_iso("2019-08-23T12-48-26words with numbers")
    '2019-08-23T12-48-26_Words_With_Numbers'
    >>> slugify_camel_iso("some 20180726_224001 thing")
    'Some_2018-07-26T22-40-01_Thing'
    >>> slugify_camel_iso("glued14092019")
    'Glued_2019-09-14'
    >>> slugify_camel_iso("glued2019-08-23T12-48-26")
    'Glued_2019-08-23T12-48-26'
    >>> slugify_camel_iso("yeah-1975-08")
    'Yeah_1975-08'
    >>> slugify_camel_iso("xxx visa-2013-07 yyy")
    'Xxx_Visa_2013-07_Yyy'
    >>> slugify_camel_iso("date without seconds 101020191830 ")
    'Date_Without_Seconds_2019-10-10T18-30-00'
    >>> slugify_camel_iso(" p2p b2b 1on1 P2P B2B 1ON1 ")
    'P2p_B2b_1on1_P2p_B2b_1on1'
    """
    temp_string = unicodedata.normalize("NFKC", old_string)

    # Insert separator in these cases
    for regex in (REGEX_EXISTING_TIME, REGEX_UPPER_CASE_LETTER):
        temp_string = regex.sub(r"\1_\2", temp_string)

    slugged = slugify(temp_string, separator=SLUG_SEPARATOR).capitalize()

    next_ten_years = pendulum.today().year + 10

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

                # If the year has only 2 digits, consider it as between 1929 and 2029
                format_has_century = "YYYY" in date_format
                if not format_has_century and actual_date.year > next_ten_years:
                    actual_date = actual_date.subtract(years=100)

                if "HH" in date_format:
                    which_format = "YYYY-MM-DDTHH-mm-ss"
                elif "DD" not in date_format:
                    which_format = "YYYY-MM"
                break
            except ValueError:
                continue

        new_date = actual_date.format(which_format) if actual_date else original_string
        return f"{SLUG_SEPARATOR}{new_date}{SLUG_SEPARATOR}"

    replaced_dates_multiple_seps = REGEX_DATE_TIME.sub(try_date, slugged)
    single_seps = REGEX_MULTIPLE_SEPARATORS.sub(SLUG_SEPARATOR, replaced_dates_multiple_seps)
    corrected_case = REGEX_UNDERLINE_LOWER_CASE.sub(lambda match_obj: match_obj.group(0).upper(), single_seps)
    return corrected_case.strip(SLUG_SEPARATOR)


def rename_batch(yes: bool, dry_run: bool, is_dir: bool, root_dir: Path, items: Set[Path]) -> bool:
    """Rename a batch of items (directories or files)."""
    which_type = "directories" if is_dir else "files"
    pairs = []
    for item in sorted(items):
        if is_dir:
            new_name = slugify_camel_iso(item.name)
        else:
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
        click.secho(new_name, fg="yellow")
        pairs.append((item, item.with_name(new_name)))

    if not dry_run and pairs:
        pretty_root = relative_to_home(root_dir)
        if not yes:
            click.confirm(f"{pretty_root}: Rename these {which_type}?", default=False, abort=True)
        for original, new in pairs:
            os.rename(original, new)
        click.secho(f"{pretty_root}: {which_type.capitalize()} renamed succesfully.", fg="yellow")

    return bool(pairs)


@click.command()
@click.option(
    "-x",
    "--exclude",
    type=click.Path(exists=True, resolve_path=True),
    multiple=True,
    help="Exclude one or more directories",
)
@yes_option
@dry_run_option
@verbose_option
@click.argument("directories", nargs=-1, type=click.Path(exists=True, file_okay=False, dir_okay=True), required=True)
def rename_slugify(exclude, yes: bool, dry_run: bool, verbose: bool, directories):
    """Rename files recursively, slugifying them. Format dates in file names as ISO. Ignore hidden dirs/files."""
    excluded_dirs = set()
    excluded_files = set()
    for file_system_object in exclude:
        path = Path(file_system_object)
        if path.is_dir():
            excluded_dirs.add(path)
        else:
            excluded_files.add(path)
    if excluded_dirs and verbose:
        pretty_dirs = sorted({relative_to_home(path) for path in excluded_dirs})
        click.echo(f"Excluding directories: {', '.join(pretty_dirs)}")
    if excluded_files and verbose:
        pretty_files = sorted({relative_to_home(path) for path in excluded_files})
        click.echo(f"Excluding files: {', '.join(pretty_files)}")

    for directory in directories:
        original_dir = Path(directory)

        dirs_to_rename = set()
        files_to_rename = set()
        for child in original_dir.glob("**/*"):
            if child.name.startswith(".") or "/." in str(child):
                if verbose:
                    click.echo(f"Ignoring hidden {relative_to_home(child)}")
                continue
            add = True
            for dir_to_exclude in excluded_dirs:
                if str(child).startswith(str(dir_to_exclude)):
                    if verbose:
                        click.echo(f"Ignoring {relative_to_home(child)}")
                    add = False
                    break
            if not add:
                continue

            if child.is_dir():
                dirs_to_rename.add(child)
            else:
                if child not in excluded_files:
                    files_to_rename.add(child)
                elif verbose:
                    click.echo(f"Ignoring file {relative_to_home(child)}")

        # Rename directories first
        rename_batch(yes, dry_run, True, original_dir, dirs_to_rename)

        # Glob the renamed directories for files
        files_found = rename_batch(yes, dry_run, False, original_dir, files_to_rename)

        if not files_found:
            click.secho(f"{relative_to_home(directory)}: All files already have correct names.", fg=COLOR_OK)

"""Rename dirs and files and merge dirs in the process."""

import os
import re
import unicodedata
from functools import partial
from pathlib import Path
from typing import Set, Union

import click
import pendulum
from slugify import slugify

from clib import dry_run_option, verbose_option, yes_option
from clib.constants import COLOR_OK
from clib.types import PathOrStr
from clib.ui import echo_dry_run

REGEX_EXISTING_TIME = re.compile(r"(-[0-9]{2})[ _]?[Aa]?[Tt][ _]?([0-9]{2}[-._])")
REGEX_UPPER_CASE_LETTER = re.compile(r"([a-z])([A-Z]+)")
REGEX_UNDERLINE_LOWER_CASE = re.compile("_[a-z]")
REGEX_DATE_TIME = re.compile(r"([0-9][0-9-_\.]+[0-9])")
REGEX_MULTIPLE_SEPARATORS = re.compile("_+")

REGEX_UNIQUE_FILE = re.compile(r"(?P<original_stem>.+)_copy(?P<index>\d+)?", re.IGNORECASE)
REMOVE_CHARS_FROM_DIR = "/ \t\n"

SLUG_SEPARATOR = "_"
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
IGNORE_FILES_ON_MERGE = {".DS_Store"}


@click.command()
@click.option(
    "-x",
    "--exclude",
    # resolve_path doesn't expand the tilde (~) to the home dir
    type=click.Path(exists=False, resolve_path=False),
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
        path = Path(file_system_object).expanduser()
        if not path.exists():
            continue
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
        original_dir = Path(directory).expanduser()

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

        echo_dry_run(f"from: {relative_dir}/{item.name}", dry_run=dry_run)
        echo_dry_run(f"  to: {relative_dir}/", nl=False, dry_run=dry_run)
        click.secho(new_name, fg="yellow")
        pairs.append((item, item.with_name(new_name)))

    if not dry_run and pairs:
        pretty_root = relative_to_home(root_dir)
        if not yes:
            click.confirm(f"{pretty_root}: Rename these {which_type}?", default=False, abort=True)
        for original, new in pairs:
            if str(original) == str(new) and new.exists():
                # Don't rename files with the exact same name that already exist
                click.secho(f"New file already exists! {new}", err=True, fg="red")
            else:
                try:
                    os.rename(original, new)
                except OSError as err:
                    if err.errno == 66:  # Directory not empty
                        merge_directories(new, original)
                    else:
                        raise err
        click.secho(f"{pretty_root}: {which_type.capitalize()} renamed succesfully.", fg="yellow")

    return bool(pairs)


def relative_to_home(full_path: Union[str, Path]):
    """Return a directory with ``~`` instead of printing the home dir full path."""
    path_obj = Path(full_path)
    return f"~/{path_obj.relative_to(path_obj.home())}"


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


def merge_directories(target_dir: PathOrStr, *source_dirs: PathOrStr, dry_run: bool = False):
    """Merge directories into one, keeping subdirectories and renaming files with the same name."""
    echo = partial(echo_dry_run, dry_run=dry_run)
    target_color = "green"
    source_color = "bright_blue"

    echo(f"Target: {target_dir}", fg=target_color)
    if not Path(target_dir).is_dir():
        click.secho("Target is not a directory", err=True, fg="red")
        return False

    for source_dir in source_dirs:
        echo(f"Source: {source_dir}", fg=source_color)
        if not Path(source_dir).is_dir():
            click.secho("Source is not a directory", err=True, fg="red")
            continue

        for path in sorted(Path(source_dir).rglob("*")):
            if path.is_dir() or path.stem in IGNORE_FILES_ON_MERGE:
                continue

            new_path = unique_file_name(target_dir / path.relative_to(source_dir))
            echo(f"Moving {dir_with_end_slash(source_dir)}", nl=False)
            click.secho(str(path.relative_to(source_dir)), fg=source_color, nl=False)
            click.secho(f" to {dir_with_end_slash(target_dir)}", nl=False)
            click.secho(str(new_path.relative_to(target_dir)), fg=target_color)
            if not dry_run:
                new_path.parent.mkdir(parents=True, exist_ok=True)
                path.rename(new_path)


@click.command()
@dry_run_option
@click.argument(
    "target_directory", nargs=1, type=click.Path(exists=True, file_okay=False, dir_okay=True), required=True
)
@click.argument(
    "source_directories", nargs=-1, type=click.Path(exists=True, file_okay=False, dir_okay=True), required=True
)
def merge_dirs(dry_run: bool, target_directory, source_directories):
    """Merge directories into one, keeping subdirectories and renaming files with the same name."""
    merge_directories(target_directory, *source_directories, dry_run=dry_run)


def unique_file_name(path_or_str: PathOrStr) -> Path:
    """Unique file name: append a number to the file name until the file is not found."""
    path = Path(path_or_str)
    while path.exists():
        original_stem = None
        index = None
        for match in REGEX_UNIQUE_FILE.finditer(path.stem):
            original_stem = match.group("original_stem")
            index = int(match.group("index") or 0) + 1

        if not original_stem:
            new_stem = path.stem
        else:
            new_stem = original_stem

        new_name = f"{new_stem}_Copy{index if index else ''}{path.suffix}"
        path = path.with_name(new_name)

    return path


def dir_with_end_slash(path: PathOrStr) -> str:
    r"""Always add a slash at the end of a directory.

    >>> dir_with_end_slash('/tmp/dir \t\n')
    '/tmp/dir/'
    >>> dir_with_end_slash(Path('/tmp/dir'))
    '/tmp/dir/'
    >>> dir_with_end_slash('/tmp/dir/file.txt')
    '/tmp/dir/file.txt/'
    >>> dir_with_end_slash(Path('/tmp/dir/file.txt'))
    '/tmp/dir/file.txt/'
    """
    if isinstance(path, str):
        path = Path(path.rstrip(REMOVE_CHARS_FROM_DIR))
    else:
        path = Path(path)
    return str(path) + os.sep

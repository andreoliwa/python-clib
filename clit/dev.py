"""Development helpers."""
import os
from pathlib import Path
from shutil import rmtree
from subprocess import call, check_output
from textwrap import dedent
from typing import Tuple

import click
from plumbum import FG, RETCODE

from clit.constants import PYCHARM_MACOS_APP_PATH
from clit.files import shell
from clit.ui import prompt


@click.command()
@click.argument("files", nargs=-1)
def pycharm_cli(files):
    """Invoke PyCharm on the command line.

    If a file doesn't exist, call `which` to find out the real location.
    """
    full_paths = []
    for possible_file in files:
        if os.path.isfile(possible_file):
            real_file = os.path.abspath(possible_file)
        else:
            real_file = check_output(["which", possible_file]).decode().strip()
        full_paths.append(real_file)
    command_line = [PYCHARM_MACOS_APP_PATH] + full_paths
    click.secho(f"Calling PyCharm with {' '.join(command_line)}", fg="green")
    call(command_line)


@click.command()
@click.option("--delete", "-d", default=False, is_flag=True, help="Delete pytest directory first")
@click.option("--failed", "-f", default=False, is_flag=True, help="Run only failed tests")
@click.option("--count", "-c", default=0, help="Repeat the same test several times")
@click.option("--reruns", "-r", default=0, help="Re-run a failed test several times")
@click.argument("class_names_or_args", nargs=-1)
def pytest_run(delete: bool, failed: bool, count: int, reruns: int, class_names_or_args: Tuple[str]):
    """Run pytest with some shortcut options."""
    # Import locally, so we get an error only in this function, and not in other functions of this module.
    from plumbum.cmd import time as time_cmd, rm

    if delete:
        click.secho("Removing .pytest directory", fg="green", bold=True)
        rm["-rf", ".pytest"] & FG

    pytest_plus_args = ["pytest", "-vv", "--run-intermittent"]
    if reruns:
        pytest_plus_args.extend(["--reruns", str(reruns)])
    if failed:
        pytest_plus_args.append("--failed")

    if count:
        pytest_plus_args.extend(["--count", str(count)])

    if class_names_or_args:
        targets = []
        for name in class_names_or_args:
            if "." in name:
                parts = name.split(".")
                targets.append("{}.py::{}".format("/".join(parts[0:-1]), parts[-1]))
            else:
                # It might be an extra argument, let's just append it
                targets.append(name)
        pytest_plus_args.append("-s")
        pytest_plus_args.extend(targets)

    click.secho(f"Running tests: time {' '.join(pytest_plus_args)}", fg="green", bold=True)
    rv = time_cmd[pytest_plus_args] & RETCODE(FG=True)
    exit(rv)


class PyPICommands:
    """Commands executed by this helper script."""

    # https://github.com/peritus/bumpversion
    BUMP_VERSION = "bumpversion {part}"
    BUMP_VERSION_DRY_RUN = f"{BUMP_VERSION} --dry-run --verbose"

    # https://github.com/conventional-changelog/conventional-changelog/tree/master/packages/conventional-changelog-cli
    CHANGELOG = "conventional-changelog -i CHANGELOG.md -p angular"

    BUILD_SETUP_PY = "python setup.py sdist bdist_wheel --universal"

    # https://poetry.eustace.io/
    BUILD_POETRY = "poetry build"

    GIT_ADD = "git add ."
    GIT_COMMIT = "git commit -m'{}'"
    GIT_PUSH = "git push"
    GIT_TAG = "git tag v{}"

    # https://github.com/pypa/twine
    # I tried using "poetry publish -u $TWINE_USERNAME -p $TWINE_PASSWORD"; the command didn't fail, but nothing was uploaded
    # I also tried setting $TWINE_USERNAME and $TWINE_PASSWORD on the environment, but then "twine upload" didn't work for some reason.
    TWINE_UPLOAD = "twine upload dist/*"

    # https://www.npmjs.com/package/conventional-github-releaser
    GITHUB_RELEASE = "conventional-github-releaser -p angular -v"


@click.group()
def pypi():
    """Commands to publish packages on PyPI."""
    pass


@pypi.command()
@click.option("--part", default="minor", type=click.Choice(["major", "minor", "patch"]))
def full(part):
    """The full process to upload to PyPI (bump version, changelog, package, upload)."""
    bump_dry_run_cmd = PyPICommands.BUMP_VERSION_DRY_RUN.format(part=part)
    bump = shell(bump_dry_run_cmd)
    if bump.returncode != 0:
        exit(bump.returncode)

    chosen_lines = shell(
        f'{bump_dry_run_cmd} 2>&1 | rg -e "would.+bump" -e "new version" | rg -o "\'(.+)\'"', return_lines=True
    )
    new_version = chosen_lines[0].strip("'")
    commit_message = chosen_lines[1].strip("'")
    print(f"New version: {new_version}\nCommit message: {commit_message}")
    prompt("Were all versions correctly bumped?")

    shell(PyPICommands.BUMP_VERSION.format(part=part))
    shell(f"{PyPICommands.CHANGELOG} -s")

    try:
        dist_dir = (Path(os.curdir) / "dist").resolve()
        print(f"Removing previous builds on {dist_dir}")
        rmtree(str(dist_dir))
    except OSError:
        pass

    shell(PyPICommands.BUILD_POETRY)
    shell("ls -l dist")
    prompt("Was a dist/ directory created with a .tar.gz and a wheel?")

    shell("git diff")
    prompt("Is the git diff correct?")

    prompt(
        "Last confirmation (point of no return):"
        + "Changes will be committed, files will be uploaded to PyPI, a GitHub release will be created"
    )

    print("Add files, commit and push")
    for command in (PyPICommands.GIT_ADD, PyPICommands.GIT_COMMIT.format(commit_message), PyPICommands.GIT_PUSH):
        shell(command)

    print("Create the tag but don't push it yet (conventional-github-releaser will do that)")
    shell(PyPICommands.GIT_TAG.format(new_version))

    print("Upload the files to PyPI via Twine")
    shell(PyPICommands.TWINE_UPLOAD)

    print("Create a GitHub release")
    shell(PyPICommands.GITHUB_RELEASE)

    print(f"The new version {new_version} was uploaded to PyPI")


@pypi.command()
def changelog():
    """Preview the changelog."""
    shell(f"{PyPICommands.CHANGELOG} -u | less")


@click.command()
def poetry_setup_py():
    """Use poetry to generate a setup.py file from pyproject.toml."""
    shell("poetry build")
    shell("tar -xvzf dist/*.gz --strip-components 1 */setup.py")
    shell("black setup.py")

    setup_py_path: Path = Path.cwd() / "setup.py"
    lines = setup_py_path.read_text().split("\n")
    lines.insert(
        1,
        dedent(
            '''
        """NOTICE: This file was generated automatically by the command: poetry-setup-py."""
    '''
        ).strip(),
    )

    # Add a hint so mypy ignores the setup() line
    lines[-2] += "  # type: ignore"

    setup_py_path.write_text("\n".join(lines))
    click.secho("setup.py generated!", fg="green")

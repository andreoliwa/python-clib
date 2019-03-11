"""Development helpers."""
import os
import re
from pathlib import Path
from shutil import rmtree
from textwrap import dedent
from typing import List, Tuple

import click
from plumbum import FG, RETCODE
from requests_html import HTMLSession

from clit.files import shell
from clit.ui import prompt

# Possible formats for tests:
# ___ test_name ___
# ___ Error on setup of test_name ___
# ___ test_name[Parameter] ___
TEST_NAMES_REGEX = re.compile(r"___ .*(test[^\[\] ]+)[\[\]A-Za-z]* ___")

PYCHARM_MACOS_APP_PATH = Path("/Applications/PyCharm.app/Contents/MacOS/pycharm")


@click.command()
@click.argument("files", nargs=-1)
def pycharm_cli(files):
    """Invoke PyCharm on the command line.

    If a file doesn't exist, call `which` to find out the real location.
    """
    full_paths: List[str] = []
    errors = False
    for possible_file in files:
        path = Path(possible_file).absolute()
        if path.is_file():
            full_paths.append(str(path))
        else:
            which_file = shell(f"which {possible_file}", quiet=True, return_lines=True)
            if which_file:
                full_paths.append(which_file[0])
            else:
                click.secho(f"File not found on $PATH: {possible_file}", fg="red")
                errors = True
    if full_paths:
        shell(f"{PYCHARM_MACOS_APP_PATH} {' '.join(full_paths)}")
    exit(1 if errors else 0)


@click.group()
def xpytest():
    """Extra commands for py.test."""
    pass


@xpytest.command()
@click.option("--delete", "-d", default=False, is_flag=True, help="Delete pytest directory first")
@click.option("--failed", "-f", default=False, is_flag=True, help="Run only failed tests")
@click.option("--count", "-c", default=0, help="Repeat the same test several times")
@click.option("--reruns", "-r", default=0, help="Re-run a failed test several times")
@click.argument("class_names_or_args", nargs=-1)
def run(delete: bool, failed: bool, count: int, reruns: int, class_names_or_args: Tuple[str]):
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


@xpytest.command()
@click.option("-f", "--result-file", type=click.File())
@click.option("-j", "--jenkins-url", multiple=True)
@click.option("-s", "dont_capture", flag_value="-s", help="Don't capture output")
@click.pass_context
def results(ctx, result_file, jenkins_url: Tuple[str, ...], dont_capture):
    """Parse a file with the output of failed tests, then re-run only those failed tests."""
    if result_file:
        contents = result_file.read()
    elif jenkins_url:
        responses = []
        for url in set(jenkins_url):
            request = HTMLSession().get(url, auth=(os.environ["JENKINS_USERNAME"], os.environ["JENKINS_PASSWORD"]))
            responses.append(request.html.html)
        contents = "\n".join(responses)
    else:
        click.echo(ctx.get_help())
        return

    match = re.search(r"<title>(?P<error>.+Invalid password.+)</title>", contents)
    if match:
        click.secho(match.group("error"), fg="red")
        exit(1)

    all_tests = set(TEST_NAMES_REGEX.findall(contents))
    expression = " or ".join(all_tests)
    if not dont_capture:
        dont_capture = ""
    shell(f"pytest -vv {dont_capture} -k '{expression}'")


class PyPICommands:
    """Commands executed by this helper script."""

    # https://github.com/peritus/bumpversion
    BUMP_VERSION = "bumpversion {allow_dirty} {part}"
    BUMP_VERSION_DRY_RUN = f"{BUMP_VERSION} --dry-run --verbose"

    # https://github.com/conventional-changelog/conventional-changelog/tree/master/packages/conventional-changelog-cli
    CHANGELOG = "conventional-changelog -i CHANGELOG.md -p angular"

    BUILD_SETUP_PY = "python setup.py sdist bdist_wheel --universal"

    # https://poetry.eustace.io/
    BUILD_POETRY = "poetry build"

    GIT_ADD_AND_COMMIT = "git add . && git commit -m'{}' --no-verify"
    GIT_PUSH = "git push"
    GIT_TAG = "git tag v{}"

    # https://github.com/pypa/twine
    # I tried using "poetry publish -u $TWINE_USERNAME -p $TWINE_PASSWORD"; the command didn't fail, but nothing was uploaded
    # I also tried setting $TWINE_USERNAME and $TWINE_PASSWORD on the environment, but then "twine upload" didn't work for some reason.
    TWINE_UPLOAD = "twine upload {repo} dist/*"

    # https://www.npmjs.com/package/conventional-github-releaser
    GITHUB_RELEASE = "conventional-github-releaser -p angular -v"


def remove_previous_builds() -> bool:
    """Remove previous builds under the /dist directory."""
    dist_dir = (Path(os.curdir) / "dist").resolve()
    if not dist_dir.exists():
        return False

    click.echo(f"Removing previous builds on {dist_dir}")
    try:
        rmtree(str(dist_dir))
    except OSError:
        return False
    return True


@click.group()
def pypi():
    """Commands to publish packages on PyPI."""
    pass


@pypi.command()
@click.option(
    "--part",
    "-p",
    default="minor",
    type=click.Choice(["major", "minor", "patch"]),
    help="Which part of the version number to bump",
)
@click.option(
    "--allow-dirty", "-d", default=False, is_flag=True, type=bool, help="Allow bumpversion to run on a dirty repo"
)
@click.option(
    "--github-only", "-g", default=False, is_flag=True, type=bool, help="Skip PyPI and publish only to GitHub"
)
@click.pass_context
def full(ctx, part, allow_dirty: bool, github_only: bool):
    """The full process to upload to PyPI (bump version, changelog, package, upload)."""
    # Recreate the setup.py
    ctx.invoke(setup_py)

    allow_dirty_option = "--allow-dirty" if allow_dirty else ""
    bump_dry_run_cmd = PyPICommands.BUMP_VERSION_DRY_RUN.format(allow_dirty=allow_dirty_option, part=part)
    bump = shell(bump_dry_run_cmd)
    if bump.returncode != 0:
        exit(bump.returncode)

    chosen_lines = shell(
        f'{bump_dry_run_cmd} 2>&1 | rg -e "would commit to git.+bump" -e "new version" | rg -o "\'(.+)\'"',
        return_lines=True,
    )
    new_version = chosen_lines[0].strip("'")
    commit_message = chosen_lines[1].strip("'")
    click.echo(f"New version: {new_version}\nCommit message: {commit_message}")
    prompt("Were all versions correctly displayed?")

    shell(PyPICommands.BUMP_VERSION.format(allow_dirty=allow_dirty_option, part=part))
    shell(f"{PyPICommands.CHANGELOG} -s")

    remove_previous_builds()

    shell(PyPICommands.BUILD_POETRY)
    shell("ls -l dist")
    prompt("Was a dist/ directory created with a .tar.gz and a wheel?")

    shell("git diff")
    prompt("Is the git diff correct?")

    upload_message = "GitHub only" if github_only else "PyPI"
    prompt(
        "Last confirmation (point of no return):\n"
        + f"Changes will be committed, files will be uploaded to {upload_message}, a GitHub release will be created"
    )

    commands = [
        ("Add all files and commit (skipping hooks)", PyPICommands.GIT_ADD_AND_COMMIT.format(commit_message)),
        ("Push", PyPICommands.GIT_PUSH),
        (
            "Create the tag but don't push it yet (conventional-github-releaser will do that)",
            PyPICommands.GIT_TAG.format(new_version),
        ),
        ("Test upload the files to TestPyPI via Twine", PyPICommands.TWINE_UPLOAD.format(repo="-r testpypi")),
    ]
    if not github_only:
        commands.append(("Upload the files to PyPI via Twine", PyPICommands.TWINE_UPLOAD.format(repo="")))
    commands.append(("Create a GitHub release", PyPICommands.GITHUB_RELEASE))
    for header, command in commands:
        while True:
            click.secho(f"\n>>> {header}", fg="bright_white")
            if shell(command).returncode == 0:
                break
            prompt("Something went wrong, running the same command again.", fg="red")

    click.secho(f"The new version {new_version} was uploaded to {upload_message}! ✨ 🍰 ✨", fg="bright_white")


@pypi.command()
def changelog():
    """Preview the changelog."""
    shell(f"{PyPICommands.CHANGELOG} -u | less")


@click.group()
def xpoetry():
    """Extra commands for poetry."""
    pass


@xpoetry.command()
def setup_py():
    """Use poetry to generate a setup.py file from pyproject.toml."""
    remove_previous_builds()
    shell("poetry build")
    shell("tar -xvzf dist/*.gz --strip-components 1 */setup.py")
    shell("black setup.py")

    setup_py_path: Path = Path.cwd() / "setup.py"
    lines = setup_py_path.read_text().split("\n")
    lines.insert(
        1,
        dedent(
            '''
        """NOTICE: This file was generated automatically by the command: xpoetry setup-py."""
    '''
        ).strip(),
    )

    # Add a hint so mypy ignores the setup() line
    lines[-2] += "  # type: ignore"

    setup_py_path.write_text("\n".join(lines))
    click.secho("setup.py generated!", fg="green")

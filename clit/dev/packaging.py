"""Packaging tools to publish projects on PyPI and GitHub."""
import os
from pathlib import Path
from shutil import rmtree
from textwrap import dedent
from typing import List, Optional, Tuple

import click

from clit import DRY_RUN_OPTION
from clit.files import shell
from clit.ui import prompt

HeaderCommand = Tuple[str, str]


class Publisher:
    """Helper to publish packages."""

    TOOL_BUMPVERSION = "bumpversion"
    TOOL_CONVENTIONAL_CHANGELOG = "conventional-changelog"
    TOOL_POETRY = "poetry"
    TOOL_GIT = "git"
    TOOL_TWINE = "twine"
    TOOL_CONVENTIONAL_GITHUB_RELEASER = "conventional-github-releaser"

    NEEDED_TOOLS = {
        TOOL_BUMPVERSION: "Install from https://github.com/peritus/bumpversion#installation and configure setup.cfg",
        TOOL_CONVENTIONAL_CHANGELOG: (
            "Install from https://github.com/conventional-changelog/conventional-changelog/tree/master"
            + "/packages/conventional-changelog-cli#quick-start"
        ),
        TOOL_POETRY: "Install from https://github.com/sdispater/poetry#installation",
        TOOL_GIT: "Install using your OS package tools",
        TOOL_TWINE: "Install from https://github.com/pypa/twine#installation",
        TOOL_CONVENTIONAL_GITHUB_RELEASER: (
            "Install from https://github.com/conventional-changelog/releaser-tools/tree"
            + "/master/packages/conventional-github-releaser#quick-start and configure a GitHub Access token"
        ),
    }

    NEEDED_FILES = {
        "package.json": (
            f"Used by {TOOL_CONVENTIONAL_CHANGELOG}. See https://github.com/conventional-changelog/"
            + "conventional-changelog/blob/master/packages/conventional-changelog-cli/package.json"
        )
    }

    # https://github.com/peritus/bumpversion
    BUMP_VERSION = TOOL_BUMPVERSION + " {allow_dirty} {part}"
    BUMP_VERSION_SIMPLE_CHECK = f"{BUMP_VERSION} --dry-run"
    BUMP_VERSION_VERBOSE = f"{BUMP_VERSION_SIMPLE_CHECK} --verbose 2>&1"
    BUMP_VERSION_VERBOSE_FILES = f"{BUMP_VERSION_VERBOSE} | grep -i -E -e '^would'"
    BUMP_VERSION_GREP = (
        f'{BUMP_VERSION_VERBOSE} | grep -i -E -e "would commit to git.+bump" -e "^new version" | grep -E -o "\'(.+)\'"'
    )

    # https://github.com/conventional-changelog/conventional-changelog/tree/master/packages/conventional-changelog-cli
    CHANGELOG = f"{TOOL_CONVENTIONAL_CHANGELOG} -i CHANGELOG.md -p angular"

    BUILD_SETUP_PY = "python setup.py sdist bdist_wheel --universal"

    # https://poetry.eustace.io/
    POETRY_BUILD = f"{TOOL_POETRY} build"

    GIT_ADD_AND_COMMIT = TOOL_GIT + " add . && git commit -m'{}' --no-verify"
    GIT_PUSH = f"{TOOL_GIT} push"
    GIT_TAG = TOOL_GIT + " tag v{}"

    # https://github.com/pypa/twine
    # I tried using "poetry publish -u $TWINE_USERNAME -p $TWINE_PASSWORD"; the command didn't fail,
    #   but nothing was uploaded
    # I also tried setting $TWINE_USERNAME and $TWINE_PASSWORD on the environment,
    #   but then "twine upload" didn't work for some reason.
    TWINE_UPLOAD = TOOL_TWINE + " upload {repo} dist/*"

    # https://www.npmjs.com/package/conventional-github-releaser
    GITHUB_RELEASE = TOOL_CONVENTIONAL_GITHUB_RELEASER + " -p angular -v --token {}"
    GITHUB_RELEASE_ENVVAR = "CONVENTIONAL_GITHUB_RELEASER_TOKEN"

    def __init__(self, dry_run: bool):
        self.dry_run = dry_run
        self.github_access_token: Optional[str] = None

    @classmethod
    def part_option(cls):
        """Add a --part option."""
        return click.option(
            "--part",
            "-p",
            default="minor",
            type=click.Choice(["major", "minor", "patch"]),
            help="Which part of the version number to bump",
        )

    @classmethod
    def allow_dirty_option(cls):
        """Add a --allow-dirty option."""
        return click.option(
            "--allow-dirty",
            "-d",
            default=False,
            is_flag=True,
            type=bool,
            help="Allow bumpversion to run on a dirty repo",
        )

    @classmethod
    def github_access_token_option(cls):
        """Add a --github-access-token option."""
        return click.option(
            "--github-access-token",
            "-t",
            help=(
                f"GitHub access token used by {cls.TOOL_CONVENTIONAL_GITHUB_RELEASER}. If not defined, will use the value"
                + f" from the ${cls.GITHUB_RELEASE_ENVVAR} environment variable"
            ),
        )

    def check_tools(self, github_access_token: str = None) -> None:
        """Check if all needed tools and files are present."""
        all_ok = True
        for executable, help_text in self.NEEDED_TOOLS.items():
            output = shell(f"which {executable}", quiet=True, return_lines=True)
            if not output:
                click.secho(f"Executable not found on the $PATH: {executable}. {help_text}", fg="bright_red")
                all_ok = False

        for file, help_text in self.NEEDED_FILES.items():
            path = Path(file)
            if not path.exists():
                click.secho(f"File not found: {path}. {help_text}", fg="bright_red")
                all_ok = False

        if github_access_token:
            self.github_access_token = github_access_token
        else:
            error_message = "Missing access token"
            if self.GITHUB_RELEASE_ENVVAR in os.environ:
                variable = self.GITHUB_RELEASE_ENVVAR
            else:
                token_keys = {k for k in os.environ.keys() if "github_access_token".casefold() in k.casefold()}
                if len(token_keys) == 1:
                    variable = token_keys.pop()
                else:
                    variable = ""
                    error_message = f"You have multiple access tokens: {', '.join(token_keys)}"

            if variable:
                self.github_access_token = os.environ[variable]
                click.echo(f"Using environment variable {variable} as GitHub access token")
            else:
                click.secho(f"{error_message}. ", fg="bright_red", nl=False)
                click.echo(
                    f"Set the variable ${self.GITHUB_RELEASE_ENVVAR} or use"
                    + " --github-access-token to define a GitHub access token"
                )
                all_ok = False

        if self.dry_run:
            return

        if all_ok:
            click.secho(f"All the necessary tools are installed.", fg="bright_white")
        else:
            click.secho("Install the tools and create the missing files.")
            exit(1)

    @classmethod
    def _bump(cls, base_command: str, part: str, allow_dirty: bool):
        """Prepare the bump command."""
        return base_command.format(allow_dirty="--allow-dirty" if allow_dirty else "", part=part)

    def check_bumped_version(self, part: str, allow_dirty: bool) -> Tuple[str, str]:
        """Check the version that will be bumped."""
        shell(
            self._bump(self.BUMP_VERSION_SIMPLE_CHECK, part, allow_dirty),
            exit_on_failure=True,
            header="Check the version that will be bumped",
        )

        bump_cmd = self._bump(self.BUMP_VERSION_VERBOSE_FILES, part, allow_dirty)
        shell(bump_cmd, dry_run=self.dry_run, header=f"Display what files would be changed", exit_on_failure=True)
        if not self.dry_run:
            chosen_lines = shell(self._bump(self.BUMP_VERSION_GREP, part, allow_dirty), return_lines=True)
            new_version = chosen_lines[0].strip("'")
            commit_message = chosen_lines[1].strip("'")
            click.echo(f"New version: {new_version}\nCommit message: {commit_message}")
            prompt("Were all versions correctly displayed?")
        else:
            commit_message = "Bump version from X to Y"
            new_version = "<new version here>"
        return commit_message, new_version

    def actually_bump_version(self, part: str, allow_dirty: bool) -> None:
        """Actually bump the version."""
        shell(self._bump(self.BUMP_VERSION, part, allow_dirty), dry_run=self.dry_run, header=f"Bump versions")

    def recreate_setup_py(self, ctx) -> None:
        """Recreate the setup.py if it exists."""
        if Path("setup.py").exists():
            if self.dry_run:
                shell("xpoetry setup-py", dry_run=True, header="Regenerate setup.py from pyproject.toml")
            else:
                ctx.invoke(setup_py)

    def generate_changelog(self) -> None:
        """Generate the changelog."""
        shell(f"{Publisher.CHANGELOG} -s", dry_run=self.dry_run, header="Generate the changelog")

    def build_with_poetry(self) -> None:
        """Build the project with poetry."""
        if not self.dry_run:
            remove_previous_builds()

        shell(Publisher.POETRY_BUILD, dry_run=self.dry_run, header=f"Build the project with {Publisher.TOOL_POETRY}")

        if not self.dry_run:
            shell("ls -l dist")
            prompt("Was a dist/ directory created with a .tar.gz and a wheel?")

    def show_diff(self) -> None:
        """Show the diff of changed files so far."""
        diff_command = f"{Publisher.TOOL_GIT} diff"
        shell(diff_command, dry_run=self.dry_run, header="Show a diff of the changes, as a sanity check")
        if self.dry_run:
            return

        prompt(f"Is the {diff_command} correct?")

        shell(f"{Publisher.TOOL_GIT} status", dry_run=self.dry_run, header="Show the list of changed files")
        prompt(
            "Last confirmation (point of no return):\n"
            + f"Changes will be committed, files will be uploaded, a GitHub release will be created"
        )

    @classmethod
    def commit_push_tag(cls, commit_message: str, new_version: str) -> List[HeaderCommand]:
        """Prepare the commands to commit, push and tag."""
        return [
            ("Add all files and commit (skipping hooks)", Publisher.GIT_ADD_AND_COMMIT.format(commit_message)),
            ("Push", Publisher.GIT_PUSH),
            (
                f"Create the tag but don't push it yet ({Publisher.TOOL_CONVENTIONAL_GITHUB_RELEASER} will do that)",
                Publisher.GIT_TAG.format(new_version),
            ),
        ]

    @classmethod
    def upload_pypi(cls) -> List[HeaderCommand]:
        """Prepare commands to upload to PyPI."""
        return [
            ("Test upload the files to TestPyPI via Twine", Publisher.TWINE_UPLOAD.format(repo="-r testpypi")),
            ("Upload the files to PyPI via Twine", Publisher.TWINE_UPLOAD.format(repo="")),
        ]

    def release(self) -> List[HeaderCommand]:
        """Prepare release commands."""
        return [("Create a GitHub release", Publisher.GITHUB_RELEASE.format(self.github_access_token))]

    def run_commands(self, commands: List[HeaderCommand]):
        """Run a list of commands."""
        for header, command in commands:
            while True:
                process = shell(command, dry_run=self.dry_run, header=header)
                if self.dry_run or process.returncode == 0:
                    break
                prompt("Something went wrong, hit ENTER to run the same command again.", fg="red")

    def success(self, new_version: str, upload_destination: str):
        """Display a sucess message."""
        if self.dry_run:
            return
        click.secho(f"The new version {new_version} was uploaded to {upload_destination}! ✨ 🍰 ✨", fg="bright_white")

    def publish(self, pypi: bool, ctx, part: str, allow_dirty: bool, github_access_token: str = None):
        """Publish a package."""
        self.check_tools(github_access_token)
        commit_message, new_version = self.check_bumped_version(part, allow_dirty)
        self.actually_bump_version(part, allow_dirty)
        self.recreate_setup_py(ctx)
        self.generate_changelog()
        self.build_with_poetry()
        self.show_diff()

        commands = self.commit_push_tag(commit_message, new_version)
        if pypi:
            commands.extend(self.upload_pypi())
        commands.extend(self.release())

        self.run_commands(commands)
        self.success(new_version, "PyPI" if pypi else "GitHub")


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
def pypub():
    """Commands to publish packages on PyPI."""
    pass


@pypub.command()
def check():
    """Check if all needed tools and files are present."""
    Publisher(False).check_tools()


@pypub.command()
@click.option("--verbose", "-v", default=False, is_flag=True, type=bool, help="Show --help for each command")
def tools(verbose: bool):
    """Show needed tools and files for the deployment."""
    for tool, help_text in Publisher.NEEDED_TOOLS.items():
        if verbose:
            click.echo("")
        click.echo(click.style(tool, "bright_green") + f": {help_text}")
        if verbose:
            shell(f"{tool} --help")

    for file, help_text in Publisher.NEEDED_FILES.items():
        click.echo(click.style(file, "bright_green") + f": {help_text}")


@pypub.command()
@DRY_RUN_OPTION
@Publisher.part_option()
@Publisher.allow_dirty_option()
@Publisher.github_access_token_option()
@click.pass_context
def pypi(ctx, dry_run: bool, part: str, allow_dirty: bool, github_access_token: str = None):
    """Package and upload to PyPI (bump version, changelog, package, upload)."""
    Publisher(dry_run).publish(True, ctx, part, allow_dirty, github_access_token)


@pypub.command()
@DRY_RUN_OPTION
@Publisher.part_option()
@Publisher.allow_dirty_option()
@Publisher.github_access_token_option()
@click.pass_context
def github(ctx, dry_run: bool, part: str, allow_dirty: bool, github_access_token: str = None):
    """Release to GitHub only (bump version, changelog, package, upload)."""
    Publisher(dry_run).publish(False, ctx, part, allow_dirty, github_access_token)


@pypub.command()
def changelog():
    """Preview the changelog."""
    shell(f"{Publisher.CHANGELOG} -u | less")


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

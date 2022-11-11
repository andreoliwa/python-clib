"""User interface."""
import sys
import time
from pathlib import Path
from subprocess import PIPE, CalledProcessError

import click


def notify(title, message):
    """If terminal-notifier is installed, use it to display a notification."""
    from clib.files import shell

    check = "which" if sys.platform == "linux" else "command -v"
    try:
        terminal_notifier_path = shell(f"{check} terminal-notifier", check=True, stdout=PIPE).stdout.strip()
    except CalledProcessError:
        terminal_notifier_path = ""
    if terminal_notifier_path:
        shell(
            'terminal-notifier -title "{}: {} complete" -message "Successfully {} dev environment."'.format(
                Path(__file__).name, title, message
            )
        )


def prompt(message: str, fg: str = "bright_white") -> None:
    """Display a prompt with a message. Wait a little bit before, so stdout is flushed before the input message."""
    print()
    click.secho(message, fg=fg)
    time.sleep(0.2)
    input("Press ENTER to continue or Ctrl-C to abort: ")


def success(message: str) -> None:
    """Display a success message."""
    click.secho(message, fg="bright_green")


def failure(message: str, exit_code: int = None) -> None:
    """Display an error message and optionally exit."""
    click.secho(message, fg="bright_red", err=True)
    if exit_code is not None:
        sys.exit(exit_code)


def echo_dry_run(message: str, *, nl: bool = True, dry_run: bool = False, **styles) -> None:
    """Display a message with the optional dry-run prefix on each line."""
    if dry_run:
        click.secho("[dry-run] ", fg="bright_cyan", nl=False)
    click.secho(message, nl=nl, **styles)


class AliasedGroup(click.Group):
    """A click group that allows aliases.

    Taken from ``click``'s documentation: `Command Aliases <https://click.palletsprojects.com/en/7.x/advanced/#command-aliases>`_.
    """

    def get_command(self, ctx, cmd_name):
        """Get a click command."""
        rv = click.Group.get_command(self, ctx, cmd_name)
        if rv is not None:
            return rv
        matches = [x for x in self.list_commands(ctx) if x.startswith(cmd_name)]
        if not matches:
            return None
        elif len(matches) == 1:
            return click.Group.get_command(self, ctx, matches[0])
        ctx.fail("Too many matches: %s" % ", ".join(sorted(matches)))

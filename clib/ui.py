# -*- coding: utf-8 -*-
"""User interface."""
import sys
import time
from pathlib import Path
from subprocess import PIPE, CalledProcessError

import click

from clib.files import shell


def notify(title, message):
    """If terminal-notifier is installed, use it to display a notification."""
    check = "which" if sys.platform == "linux" else "command -v"
    try:
        terminal_notifier_path = shell("{} terminal-notifier".format(check), check=True, stdout=PIPE).stdout.strip()
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

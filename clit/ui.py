"""User interface."""
import sys
from pathlib import Path
from subprocess import PIPE, CalledProcessError

from clit.files import shell


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

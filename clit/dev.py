"""Development helpers."""
import os
from subprocess import call, check_output
from typing import Tuple

import click
import crayons
from plumbum import FG, RETCODE

from clit.constants import PYCHARM_APP_FULL_PATH


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
    command_line = [PYCHARM_APP_FULL_PATH] + full_paths
    print(crayons.green("Calling PyCharm with {}".format(" ".join(command_line))))
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
        print(crayons.green("Removing .pytest directory", bold=True))
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

    print(crayons.green("Running tests: time {}".format(" ".join(pytest_plus_args)), bold=True))
    rv = time_cmd[pytest_plus_args] & RETCODE(FG=True)
    exit(rv)

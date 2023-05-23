"""Development helpers."""
import os
import re
from pathlib import Path
from typing import Tuple

import click
from plumbum import FG, RETCODE
from requests_html import HTMLSession

from clib.files import shell

# Possible formats for tests:
# ___ test_name ___
# ___ Error on setup of test_name ___
# ___ test_name[Parameter] ___
TEST_NAMES_REGEX = re.compile(r"___ .*(test[^\[\] ]+)[\[\]A-Za-z]* ___")

# https://www.jetbrains.com/help/pycharm/directories-used-by-the-ide-to-store-settings-caches-plugins-and-logs.html
PYCHARM_MACOS_APP_PATH = Path("/Applications/PyCharm.app/Contents/MacOS/pycharm")
LIBRARY_LOGS_DIR = Path.home() / "Library/Logs/JetBrains"


@click.group()
def pytestx():
    """Extra commands for py.test."""


@pytestx.command()
@click.option("--delete", "-d", default=False, is_flag=True, help="Delete pytest directory first")
@click.option("--failed", "-f", default=False, is_flag=True, help="Run only failed tests")
@click.option("--count", "-c", default=0, help="Repeat the same test several times")
@click.option("--reruns", "-r", default=0, help="Re-run a failed test several times")
@click.argument("class_names_or_args", nargs=-1)
def run(delete: bool, failed: bool, count: int, reruns: int, class_names_or_args: Tuple[str]):
    """Run pytest with some shortcut options."""
    # Import locally, so we get an error only in this function, and not in other functions of this module.
    from plumbum.cmd import rm, time as time_cmd

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


@pytestx.command()
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

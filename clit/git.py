# -*- coding: utf-8 -*-
"""Git tools."""
from shlex import split

from plumbum import ProcessExecutionError
from plumbum.cmd import git

DEVELOPMENT_BRANCH = "develop"


def run_git(*args, dry_run=False, quiet=False):
    """Run a git command, print it before executing and capture the output."""
    command = git[split(" ".join(args))]
    if not quiet:
        print("{}{}".format("[DRY-RUN] " if dry_run else "", command))
    if dry_run:
        return ""
    rv = command()
    if not quiet and rv:
        print(rv)
    return rv


def branch_exists(branch):
    """Return True if the branch exists."""
    try:
        run_git("rev-parse --verify {}".format(branch), quiet=True)
        return True
    except ProcessExecutionError:
        return False


def get_current_branch():
    """Get the current branch name."""
    return run_git("rev-parse --abbrev-ref HEAD", quiet=True).strip()

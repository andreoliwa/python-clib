# -*- coding: utf-8 -*-
"""Git tools."""
from plumbum import ProcessExecutionError
from plumbum.cmd import git
from shlex import split

DEVELOPMENT_BRANCH = 'develop'


def run_git(*args, dry_run=False, quiet=False):
    """Run a git command, print it before executing and capture the output."""
    command = git[split(' '.join(args))]
    if not quiet:
        print('{}{}'.format('[DRY-RUN] ' if dry_run else '', command))
    if dry_run:
        return ''
    rv = command()
    if not quiet and rv:
        print(rv)
    return rv


def branch_exists(branch):
    """Return True if the branch exists."""
    try:
        run_git('rev-parse --verify {}'.format(branch), quiet=True)
        return True
    except ProcessExecutionError:
        return False


def prune_local_branches():
    """Remove local branches that would be pruned remotely."""
    print('Removing local branches that can be pruned remotely...')
    output = run_git('remote prune --dry-run origin')
    if not output:
        print('There are no remote branches to prune')
        return

    raw_branch_lines = output.splitlines()[2:]
    local_branches = [line.split('/', 1)[-1] for line in raw_branch_lines]
    for branch in local_branches:
        if branch_exists(branch):
            run_git('branch --delete --force {}'.format(branch))


def get_current_branch():
    """Current branch name."""
    return run_git('rev-parse --abbrev-ref HEAD', quiet=True).strip()


def vacuum():
    """Pull repo, remove remote and local merged branches."""
    print('Cleaning up git...')

    branch = get_current_branch()
    run_git('pull')
    if branch_exists(DEVELOPMENT_BRANCH):
        run_git('checkout', DEVELOPMENT_BRANCH)
        run_git('pull')

    run_git('checkout master')
    run_git('pull')

    # 1. Prune local branches
    prune_local_branches()

    # 2. Prune remote branches
    run_git('remote prune origin')
    run_git('fetch origin --prune')

    # 3. Remove local branches that were already merged
    try:
        run_git('bclean')
    except ProcessExecutionError:
        print('There are no merged local branches')

    run_git('checkout', branch)
    run_git('branch')

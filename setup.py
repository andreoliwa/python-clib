# -*- coding: utf-8 -*-
"""NOTICE: This file was generated automatically by the command: poetryx setup-py."""
from distutils.core import setup

packages = ["clib", "clib.dev"]

package_data = {"": ["*"]}

install_requires = [
    "SQLAlchemy",
    "argcomplete",
    "click",
    "colorlog",
    "plumbum",
    "prettyconf",
    "requests",
    "requests-html",
]

entry_points = {
    "console_scripts": [
        "backup-full = clib.files:backup_full",
        "docker-find = clib.docker:docker_find",
        "docker-volume = clib.docker:docker_volume",
        "pycharm-cli = clib.dev:pycharm_cli",
        "pypub = clib.dev.packaging:pypub",
        "poetryx = clib.dev.packaging:poetryx",
        "postgresx = clib.db:postgresx",
        "pytestx = clib.dev:pytestx",
    ]
}

setup_kwargs = {
    "name": "clib",
    "version": "0.10.0",
    "description": "Python CLI library, tools and scripts to help in everyday life",
    "long_description": "# python-clib\n\nPython CLI library, tools and scripts to help in everyday life.\n\n## Installation\n\nFirst, [install `pipx`](https://github.com/pipxproject/pipx#install-pipx).\n\nThen install `clib` in an isolated environment: \n\n    pipx install --spec git+https://github.com/andreoliwa/python-clib clib\n\n## Development\n\nYou can clone the repo locally and then install it:\n\n    cd ~/Code\n    git clone https://github.com/andreoliwa/python-clib.git\n    pipx install -e --spec ~/Code/python-clib/ clib\n\nThis project is not on PyPI because:\n\n- it's not that generic;\n- from the beginning, it was not built as a package to be published (it would need some adptations);\n- the code is not super clean;\n- it doesn't have proper tests;\n- etc.\n\n# Available commands\n\n[backup-full](#backup-full) |\n[docker-find](#docker-find) |\n[docker-volume](#docker-volume) |\n[pycharm-cli](#pycharm-cli) |\n[pypi](#pypi) |\n[poetryx](#poetryx) |\n[postgresx](#postgresx) |\n[pytestx](#pytestx)\n\n## backup-full\n\n    $ backup-full --help\n    Usage: backup-full [OPTIONS]\n\n      Perform all backups in a single script.\n\n    Options:\n      -n, --dry-run   Dry-run\n      -k, --kill      Kill files when using rsync (--del)\n      -p, --pictures  Backup pictures\n      --help          Show this message and exit.\n\n## docker-find\n\n    $ docker-find --help\n    usage: docker-find [-h] {scan,rm,ls,yml} ...\n\n    find docker.compose.yml files\n\n    optional arguments:\n      -h, --help        show this help message and exit\n\n    commands:\n      {scan,rm,ls,yml}\n        scan            scan directories and add them to the list\n        rm              remove directories from the list\n        ls              list yml files\n        yml             choose one of the yml files to call docker-compose on\n\n---\n\n    $ docker-find scan --help\n    usage: docker-find scan [-h] [dir [dir ...]]\n\n    positional arguments:\n      dir         directory to scan\n\n    optional arguments:\n      -h, --help  show this help message and exit\n\n---\n\n    $ docker-find rm --help\n    usage: docker-find rm [-h] dir [dir ...]\n\n    positional arguments:\n      dir         directory to remove\n\n    optional arguments:\n      -h, --help  show this help message and exit\n\n---\n\n    $ docker-find ls --help\n    usage: docker-find ls [-h]\n\n    optional arguments:\n      -h, --help  show this help message and exit\n\n---\n\n    $ docker-find yml --help\n    usage: docker-find yml [-h] yml_file ...\n\n    positional arguments:\n      yml_file            partial name of the desired .yml file\n      docker_compose_arg  docker-compose arguments\n\n    optional arguments:\n      -h, --help          show this help message and exit\n\n## docker-volume\n\n    $ docker-volume --help\n    usage: docker-volume [-h] {backup,b,restore,r} ...\n\n    backup and restore Docker volumes\n\n    optional arguments:\n      -h, --help            show this help message and exit\n\n    commands:\n      {backup,b,restore,r}\n        backup (b)          backup a Docker volume\n        restore (r)         restore a Docker volume\n\n---\n\n    $ docker-volume backup --help\n    usage: docker-volume backup [-h] backup_dir volume_name [volume_name ...]\n\n    positional arguments:\n      backup_dir   directory to store the backups\n      volume_name  Docker volume name\n\n    optional arguments:\n      -h, --help   show this help message and exit\n\n---\n\n    $ docker-volume restore --help\n    usage: docker-volume restore [-h] tgz_file [volume_name]\n\n    positional arguments:\n      tgz_file     full path of the .tgz file created by the 'backup' command\n      volume_name  volume name (default: basename of .tgz file)\n\n    optional arguments:\n      -h, --help   show this help message and exit\n\n## pycharm-cli\n\n    $ pycharm-cli --help\n    Usage: pycharm-cli [OPTIONS] [FILES]...\n\n      Invoke PyCharm on the command line.\n\n      If a file doesn't exist, call `which` to find out the real location.\n\n    Options:\n      --help  Show this message and exit.\n\n## pypi\n\n    $ pypi --help\n    Usage: pypi [OPTIONS] COMMAND [ARGS]...\n\n      Commands to publish packages on PyPI.\n\n    Options:\n      --help  Show this message and exit.\n\n    Commands:\n      changelog  Preview the changelog.\n      full       The full process to upload to PyPI (bump version, changelog,...\n\n---\n\n    $ pypi changelog --help\n    Usage: pypi changelog [OPTIONS]\n\n      Preview the changelog.\n\n    Options:\n      --help  Show this message and exit.\n\n---\n\n    $ pypi full --help\n    Usage: pypi full [OPTIONS]\n\n      The full process to upload to PyPI (bump version, changelog, package,\n      upload).\n\n    Options:\n      -p, --part [major|minor|patch]  Which part of the version number to bump\n      -d, --allow-dirty               Allow bumpversion to run on a dirty repo\n      --help                          Show this message and exit.\n\n## poetryx\n\n    $ poetryx --help\n    Usage: poetryx [OPTIONS] COMMAND [ARGS]...\n\n      Extra commands for poetry.\n\n    Options:\n      --help  Show this message and exit.\n\n    Commands:\n      setup-py  Use poetry to generate a setup.py file from pyproject.toml.\n\n---\n\n    $ poetryx setup-py --help\n    Usage: poetryx setup-py [OPTIONS]\n\n      Use poetry to generate a setup.py file from pyproject.toml.\n\n    Options:\n      --help  Show this message and exit.\n\n## postgresx\n\n    $ postgresx --help\n    usage: postgresx [-h] server_uri {backup,restore} ...\n\n    PostgreSQL helper tools\n\n    positional arguments:\n      server_uri        database server URI\n                        (postgresql://user:password@server:port)\n\n    optional arguments:\n      -h, --help        show this help message and exit\n\n    commands:\n      {backup,restore}\n        backup          backup a PostgreSQL database to a SQL file\n        restore         restore a PostgreSQL database from a SQL file\n\n---\n\n    $ postgresx backup --help\n    usage: postgresx [-h] server_uri {backup,restore} ...\n\n    PostgreSQL helper tools\n\n    positional arguments:\n      server_uri        database server URI\n                        (postgresql://user:password@server:port)\n\n    optional arguments:\n      -h, --help        show this help message and exit\n\n    commands:\n      {backup,restore}\n        backup          backup a PostgreSQL database to a SQL file\n        restore         restore a PostgreSQL database from a SQL file\n\n---\n\n    $ postgresx restore --help\n    usage: postgresx [-h] server_uri {backup,restore} ...\n\n    PostgreSQL helper tools\n\n    positional arguments:\n      server_uri        database server URI\n                        (postgresql://user:password@server:port)\n\n    optional arguments:\n      -h, --help        show this help message and exit\n\n    commands:\n      {backup,restore}\n        backup          backup a PostgreSQL database to a SQL file\n        restore         restore a PostgreSQL database from a SQL file\n\n## pytestx\n\n    $ pytestx --help\n    Usage: pytestx [OPTIONS] COMMAND [ARGS]...\n\n      Extra commands for py.test.\n\n    Options:\n      --help  Show this message and exit.\n\n    Commands:\n      results  Parse a file with the output of failed tests, then re-run only...\n      run      Run pytest with some shortcut options.\n\n---\n\n    $ pytestx results --help\n    Usage: pytestx results [OPTIONS]\n\n      Parse a file with the output of failed tests, then re-run only those\n      failed tests.\n\n    Options:\n      -f, --result-file FILENAME\n      -j, --jenkins-url TEXT\n      -s                          Don't capture output\n      --help                      Show this message and exit.\n\n---\n\n    $ pytestx run --help\n    Usage: pytestx run [OPTIONS] [CLASS_NAMES_OR_ARGS]...\n\n      Run pytest with some shortcut options.\n\n    Options:\n      -d, --delete          Delete pytest directory first\n      -f, --failed          Run only failed tests\n      -c, --count INTEGER   Repeat the same test several times\n      -r, --reruns INTEGER  Re-run a failed test several times\n      --help                Show this message and exit.\n",
    "author": "W. Augusto Andreoli",
    "author_email": "andreoliwa@gmail.com",
    "url": "https://github.com/andreoliwa/python-clib",
    "packages": packages,
    "package_data": package_data,
    "install_requires": install_requires,
    "entry_points": entry_points,
    "python_requires": ">=3.6,<4.0",
}


setup(**setup_kwargs)  # type: ignore

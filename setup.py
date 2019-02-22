# -*- coding: utf-8 -*-
"""NOTICE: This file was generated automatically by the command: poetry-setup-py."""
from distutils.core import setup

packages = ["clit"]

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
        "backup-full = clit.files:backup_full",
        "git-local-prune = clit.git:prune_local_branches",
        "git-vacuum = clit.git:vacuum",
        "pycharm-cli = clit.dev:pycharm_cli",
        "pypi = clit.dev:pypi",
        "xpoetry = clit.dev:extra_poetry",
        "xpytest = clit.dev:extra_pytest",
    ]
}

setup_kwargs = {
    "name": "clit",
    "version": "0.9.0",
    "description": "Python CLI tools and scripts to help in everyday life",
    "long_description": "==========\nclit\n==========\n\n.. TODO image:: https://badge.fury.io/py/python-clit.png\n   TODO  :target: http://badge.fury.io/py/python-clit\n\n.. TODO .. image:: https://travis-ci.org/andreoliwa/python-clit.png?branch=master\n.. TODO         :target: https://travis-ci.org/andreoliwa/python-clit\n\n.. TODO .. image:: https://pypip.in/d/python-clit/badge.png\n.. TODO         :target: https://pypi.python.org/pypi/python-clit\n\n\nSeveral general use scripts to help in everyday life.\n\n* Free software: MIT license\n\n.. TODO * Documentation: https://clit.readthedocs.org.\n\nFeatures\n--------\n\n* TODO\n",
    "author": "W. Augusto Andreoli",
    "author_email": "andreoliwa@gmail.com",
    "url": "https://github.com/andreoliwa/python-clit",
    "packages": packages,
    "package_data": package_data,
    "install_requires": install_requires,
    "entry_points": entry_points,
    "python_requires": ">=3.6,<4.0",
}


setup(**setup_kwargs)  # type: ignore

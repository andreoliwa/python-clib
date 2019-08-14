# [0.11.0](https://github.com/andreoliwa/python-clib/compare/v0.10.0...v0.11.0) (2019-04-03)

### Features

-   **pypi:** improve upload messages ([106fa43](https://github.com/andreoliwa/python-clib/commit/106fa43))
-   **pypub:** add option to create a manual release on GitHub ([baa219b](https://github.com/andreoliwa/python-clib/commit/baa219b))
-   **pypub:** display git status of files ([763f8f7](https://github.com/andreoliwa/python-clib/commit/763f8f7))
-   **pypub:** improvements to GitHub and PyPI upload process ([e4e2528](https://github.com/andreoliwa/python-clib/commit/e4e2528))

<a name="0.10.0"></a>

# [0.10.0](https://github.com/andreoliwa/python-clib/compare/0.7.0...v0.10.0) (2019-03-11)

### Bug Fixes

-   get correct Git commit message from bumpversion ([7d69b79](https://github.com/andreoliwa/python-clib/commit/7d69b79))
-   **pycharm-cli:** an error was being raised when opening files ([6e81b31](https://github.com/andreoliwa/python-clib/commit/6e81b31))
-   **pytestx:** treat invalid password on Jenkins ([8a97c71](https://github.com/andreoliwa/python-clib/commit/8a97c71))
-   error when running postgresx backup ([d574f2b](https://github.com/andreoliwa/python-clib/commit/d574f2b))

### Features

-   **pypi:** allow dirty workspace, recreat setup.py, check return codes ([34f18e8](https://github.com/andreoliwa/python-clib/commit/34f18e8))
-   **pypi:** flag to skip PyPI and publish only to GitHub ([68dca29](https://github.com/andreoliwa/python-clib/commit/68dca29))
-   **pypi:** upload to test server, remove previous builds ([f95caf8](https://github.com/andreoliwa/python-clib/commit/f95caf8))
-   add docker-find script ([c54c686](https://github.com/andreoliwa/python-clib/commit/c54c686))
-   add docker-volume script ([4b820a2](https://github.com/andreoliwa/python-clib/commit/4b820a2))
-   add new functions and classes from dotfiles ([86648da](https://github.com/andreoliwa/python-clib/commit/86648da))
-   add pypi script ([3ec86a6](https://github.com/andreoliwa/python-clib/commit/3ec86a6))
-   add postgresx script ([5dd7350](https://github.com/andreoliwa/python-clib/commit/5dd7350))
-   add pytestx script ([9ce3b43](https://github.com/andreoliwa/python-clib/commit/9ce3b43))
-   colored prompt ([56249be](https://github.com/andreoliwa/python-clib/commit/56249be))
-   use poetry to generate a setup.py file from pyproject.toml ([1154a3c](https://github.com/andreoliwa/python-clib/commit/1154a3c))

<a name="0.7.3"></a>

# 0.7.3 (2015-04-02)

-   Add CLI script to create symlinks.
-   Remove a lot of packages from the Ubuntu setup.
-   Create links for directories listed in config.ini.
-   Remove Thunderbird and Python stuff from the global setup (now using virtual environments).
-   Create symbolic links for files, with additional checks.
-   Check files with pylint also (besides flake8).

<a name="0.7.2"></a>

# 0.7.2 (2015-03-29)

-   Fix Git vacuum scripts.
-   Add better messages to the media tools, with colored logging.
-   Change Python cleaning script, Git pre-push hook and zsh theme colors.
-   Try to use pylint inside the virtualenv (with no success so far).
-   Add docstring and PEP257 compliance.
-   Add unique colored log for the whole app.
-   Fix Dropbox conflicts, add Docker machine and compose to some scripts.

<a name="0.7.1"></a>

# 0.7.1 (2015-03-25)

-   Some new scripts, VLC automation, improvements to ImmoScout parsing.

<a name="0.7.0"></a>

# 0.7.0 (2015-02-17)

-   First release, but not yet on PyPI.

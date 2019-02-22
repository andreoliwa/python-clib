"""Constants."""
import re
from pathlib import Path

SECTION_SYMLINKS_FILES = "symlinks/files"
SECTION_SYMLINKS_DIRS = "symlinks/dirs"
PYCHARM_MACOS_APP_PATH = Path("/Applications/PyCharm.app/Contents/MacOS/pycharm")
CONFIG_DIR = Path("~/.config/dotfiles/").expanduser()

# Possible formats for tests:
# ___ test_name ___
# ___ Error on setup of test_name ___
# ___ test_name[Parameter] ___
TEST_NAMES_REGEX = re.compile(r"___ .*(test[^\[\] ]+)[\[\]A-Za-z]* ___")

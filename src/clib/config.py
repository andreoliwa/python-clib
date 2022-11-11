"""Configuration helpers."""
import json
import os
from pathlib import Path
from typing import List

CONFIG_DIR = Path("~/.config/dotfiles/").expanduser()


class JsonConfig:
    """A JSON config file."""

    def __init__(self, partial_path):
        """Create or get a JSON config file inside the config directory."""
        self.full_path = CONFIG_DIR / partial_path
        self.full_path.parent.mkdir(parents=True, exist_ok=True)

    def _generic_load(self, default):
        """Try to load file data, and use a default when there is no data."""
        try:
            data = json.loads(self.full_path.read_text())
        except (json.decoder.JSONDecodeError, FileNotFoundError):
            data = default
        return data

    def load_set(self):
        """Load file data as a set."""
        return set(self._generic_load(set()))

    def dump(self, new_data):
        """Dump new JSON data in the config file."""
        if isinstance(new_data, set):
            new_data = list(new_data)
        self.full_path.write_text(json.dumps(new_data))


def cast_to_directory_list(check_existing: bool = True):
    """Cast from a string of directories separated by colons.

    Useful functions for the prettyconf module.

    Optional check existing directories: throw an error if any directory does not exist.
    """

    def cast_function(value) -> List[str]:
        """Cast function expected by prettyconf."""
        expanded_dirs = [os.path.expanduser(dir_).rstrip("/") for dir_ in value.split(":")]

        if check_existing:
            non_existent = [d for d in expanded_dirs if d and not os.path.isdir(d)]
            if non_existent:
                raise RuntimeError(
                    "Some directories were not found or are not directories: {}".format(":".join(non_existent))
                )

        return expanded_dirs

    return cast_function

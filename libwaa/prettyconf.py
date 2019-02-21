"""Useful functions for the prettyconf module."""

import os
from typing import List


def cast_to_directory_list(check_existing: bool = True):
    """Cast from a string of directories separated by colons.

    Optional check existing directories: throw an error if any directory does not exist.
    """

    def cast_function(value) -> List[str]:
        """Cast function expected by prettyconf."""
        expanded_dirs = [os.path.expanduser(dir_).rstrip("/") for dir_ in value.split(":")]

        if check_existing:
            non_existent = [d for d in expanded_dirs if not os.path.isdir(d)]
            if non_existent:
                raise RuntimeError(
                    "Some directories were not found or are not directories: {}".format(":".join(non_existent))
                )

        return expanded_dirs

    return cast_function

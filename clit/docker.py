"""Docker module."""
import json
from pathlib import Path
from typing import List

from clit.files import shell
from clit.types import JsonDict


class DockerContainer:
    """A helper for Docker containers."""

    def __init__(self, container_name: str) -> None:
        """Init instance."""
        self.container_name = container_name
        self.inspect_json: List[JsonDict] = []

    def inspect(self) -> "DockerContainer":
        """Inspect a Docker container and save its JSON info."""
        if not self.inspect_json:
            raw_info = shell(f"docker inspect {self.container_name}", quiet=True, capture_output=True).stdout
            self.inspect_json = json.loads(raw_info)
        return self

    def replace_mount_dir(self, path: Path) -> Path:
        """Replace a mounted dir on a file/dir path inside a Docker container."""
        self.inspect()
        for mount in self.inspect_json[0]["Mounts"]:
            source = mount["Source"]
            if str(path).startswith(source):
                new_path = str(path).replace(source, mount["Destination"])
                return Path(new_path)
        return path

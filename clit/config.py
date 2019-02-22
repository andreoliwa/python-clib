"""Configuration helpers."""
import json

from clit.constants import CONFIG_DIR


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

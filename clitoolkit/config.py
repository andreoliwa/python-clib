# -*- coding: utf-8 -*-
import os
import logging
from configparser import ConfigParser

# Default configuration keys used below (kept separate to make mocking easier)
DEFAULT_CONFIG = {
    'dir': os.path.expanduser('~/.config/' + os.path.basename(os.path.dirname(__file__))),
    'filename': 'config.ini',
    'dotfiles_dir': os.path.realpath(os.path.join(os.path.dirname(__file__), '../dotfiles'))
}

logger = logging.getLogger(__name__)


class Init:
    def __init__(self):
        self.full_name = os.path.join(DEFAULT_CONFIG['dir'], DEFAULT_CONFIG['filename'])
        self.config = ConfigParser()
        self.config.read(self.full_name)

    def __del__(self):
        self.save()

    def save(self):
        """Save the config file."""
        os.makedirs(DEFAULT_CONFIG['dir'], exist_ok=True)
        with open(self.full_name, 'w') as fp:
            self.config.write(fp)

    def create_links(self):
        """Create symbolic links for files and dirs, following what's stored on the config file."""
        try:
            self.config['dirs']
        except KeyError:
            self.config['dirs'] = {}

        try:
            self.config['dirs']['dotfiles']
        except KeyError:
            self.config['dirs']['dotfiles'] = DEFAULT_CONFIG['dotfiles_dir']
        dot_files_dir = self.config['dirs']['dotfiles']

        if not os.path.exists(dot_files_dir):
            logger.warning("The directory '%s' does not exist", dot_files_dir)
            return self

        try:
            self.config['file_links']
        except KeyError:
            self.config['file_links'] = {}
        file_links_section = self.config['file_links']

        cut = len(dot_files_dir) + 1
        for root, dirs, files in os.walk(dot_files_dir):
            for file in files:
                key = os.path.join(root, file)[cut:]
                target = file_links_section.get(key, fallback='')
                file_links_section[key] = target

        # TODO Warn if link exists
        # TODO Warn if a dotfile has no json config
        # TODO Warn if a json config has no real file
        # TODO Create if the target exists and the link doesn't
        return self


if __name__ == "__main__":
    Init().create_links().save()

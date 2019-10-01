"""Utilities to deal with contact data (people and places with name, address, phone)."""
from collections import defaultdict
from pathlib import Path
from tempfile import NamedTemporaryFile
from textwrap import dedent
from typing import DefaultDict, List, Optional, Set, Tuple

import click
import phonenumbers
from phonenumbers import NumberParseException
from ruamel.yaml import YAML
from ruamel.yaml.scalarstring import LiteralScalarString

from clib.files import shell
from clib.types import JsonDict

CONTACT_SEPARATOR = "---"
URL_PREFIX = "http"
KEY_CONTACTS = "contacts"


@click.group()
def contacts():
    """Utilities to deal with contact data (people and places with name, address, phone)."""
    pass


class Contact:
    """A contact with name, address, phones and notes."""

    def __init__(self, raw_original: Optional[str], contact_dict: JsonDict = None) -> None:
        data = contact_dict.copy() if contact_dict else {}

        self.name = data.pop("name", "")
        self.address: LiteralScalarString = LiteralScalarString(data.pop("address", ""))
        self.notes: LiteralScalarString = LiteralScalarString(data.pop("notes", ""))
        self.phones: Set[str] = set(data.pop("phones", []))
        self.links: Set[str] = set(data.pop("links", []))
        self.raw_original: LiteralScalarString = LiteralScalarString(
            raw_original.strip() if raw_original else data.pop("raw_original", "")
        )
        self.existing_data = data

        self.parse_contact()

    def parse_contact(self):
        """Parse contact data from a string."""
        if not self.raw_original:
            return

        contact_lines = []
        for line in self.raw_original.split("\n"):
            clean_line = line.strip()
            if not clean_line:
                continue

            formatted_phone = self.parse_phone(clean_line)
            if formatted_phone:
                self.phones.add(formatted_phone)
                continue

            if clean_line.startswith(URL_PREFIX):
                self.links.add(clean_line)
                continue
            contact_lines.append(clean_line)

        from postal.parser import parse_address

        tokens: List[Tuple[str, str]] = parse_address("\n".join(contact_lines))
        result = defaultdict(list)
        for value, variable in tokens:
            result[variable].append(value)
        self.format_address(result)

    def format_address(self, address_dict: DefaultDict):
        """Format an address as a multiline string."""
        valid = {}
        for key in ("road", "house_number", "postcode", "city", "suburb"):
            flat_value = " ".join(address_dict.pop(key, [])).strip()
            valid[key] = flat_value

        self.address = LiteralScalarString(
            dedent(
                f"""
                {valid["road"]}, {valid["house_number"]}
                {valid["suburb"]}
                {valid["postcode"]} {valid["city"]}
                """
            ).strip()
        )

        notes = address_dict.pop("house", [])
        if notes:
            self.name = notes[0]
            self.notes = LiteralScalarString("\n".join(notes[1:]))

        self.existing_data.update(address_dict)

    def as_dict(self):
        """Return the contact as a dict."""
        rv = {}
        for key in ("name", "address", "notes", "phones", "links", "raw_original"):
            value = getattr(self, key)
            if isinstance(value, set):
                value = sorted(list(value))
            if value:
                rv[key] = value
        rv.update(self.existing_data)
        return rv

    def parse_phone(self, clean_line) -> Optional[str]:
        """Try to parse a phone in a line."""
        try:
            phone = phonenumbers.parse(clean_line, "DE")
        except NumberParseException:
            return None
        if not phonenumbers.is_valid_number(phone):
            return None

        return phonenumbers.format_number(phone, phonenumbers.PhoneNumberFormat.INTERNATIONAL)


@contacts.command()
@click.argument("files", nargs=-1, type=click.Path(exists=True, file_okay=True, dir_okay=False), required=True)
def parse(files):
    """Parse a file with contacts and structure data in a YAML file."""
    yaml = YAML()
    yaml.indent(mapping=2, sequence=4, offset=2)

    for arg_file in files:
        original_file = Path(arg_file)
        structured_contacts = []
        if original_file.suffix == ".yaml":
            yaml_content = yaml.load(original_file)
            if KEY_CONTACTS not in yaml_content:
                click.secho(f"Not a valid contacts file: {original_file}. Missing 'contacts' root key.", fg="red")
                continue

            click.echo(f"Reading contacts from YAML file {original_file}")
            for contact_dict in yaml_content[KEY_CONTACTS]:
                contact = Contact(None, contact_dict)
                structured_contacts.append(contact.as_dict())
        else:
            click.echo(f"Reading contacts from text file {original_file}")
            for raw_contact_string in original_file.read_text().split(CONTACT_SEPARATOR):
                contact = Contact(raw_contact_string)
                structured_contacts.append(contact.as_dict())

        output_file = original_file.with_suffix(".yaml")
        output_dict = {KEY_CONTACTS: structured_contacts}

        if output_file == original_file:
            with NamedTemporaryFile() as fp:
                yaml.dump(output_dict, fp)
                diff = shell(
                    "colordiff --unified --ignore-case --ignore-tab-expansion --ignore-space-change"
                    f" --ignore-all-space --ignore-blank-lines {original_file} {fp.name}",
                    quiet=True,
                )
                if diff.returncode == 0:
                    click.secho("Skipping file, content has not changed", fg="green")
                    continue
                if not click.confirm("Replace this file?", default=False):
                    continue
            verb = "Replacing"
        else:
            verb = "Creating"
        click.secho(f"{verb} contacts on file {output_file}", fg="yellow")
        yaml.dump(output_dict, output_file)

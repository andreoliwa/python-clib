"""Utilities to deal with contact data (people and places with name, address, phone)."""

from collections import defaultdict
from pathlib import Path
from tempfile import NamedTemporaryFile
from textwrap import dedent
from typing import DefaultDict, List, Optional, Set, Tuple, Union

import click
import phonenumbers
from phonenumbers import NumberParseException
from ruamel.yaml import YAML, YAMLError
from ruamel.yaml.scalarstring import LiteralScalarString

from clib.files import shell
from clib.types import JsonDict

CONTACT_SEPARATOR = "---"
URL_PREFIX = "http"
KEY_CONTACTS = "contacts"


@click.group()
def contacts():
    """Utilities to deal with contact data (people and places with name, address, phone)."""


class Contact:
    """A contact with name, address, phones and notes."""

    def __init__(self, raw_original: Optional[str], contact_dict: JsonDict = None) -> None:
        data = contact_dict.copy() if contact_dict else {}

        self.name: Union[str, LiteralScalarString] = data.pop("name", "")
        self.address: LiteralScalarString = LiteralScalarString(data.pop("address", ""))
        self.notes: LiteralScalarString = LiteralScalarString(data.pop("notes", ""))
        self.phones: Set[str] = set(data.pop("phones", []))
        self.emails: Set[str] = set(data.pop("emails", []))
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

            if self.parse_phone(clean_line):
                continue
            if self.parse_email(clean_line):
                continue
            if self.parse_link(clean_line):
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
        for key in ("road", "house_number", "postcode", "city", "country"):
            flat_value = " ".join(address_dict.pop(key, [])).strip()
            valid[key] = flat_value

        templated_address = dedent(
            f"""
            {valid["road"]} {valid["house_number"]}
            {valid["postcode"]} {valid["city"]}
            {valid["country"]}
            """
        )

        # Remove empty lines
        valid_lines = []
        for line in templated_address.split("\n"):
            clean_line = line.strip(" ,\n").title()
            if not clean_line:
                continue
            valid_lines.append(clean_line)

        self.address = LiteralScalarString("\n".join(valid_lines))

        notes = address_dict.pop("house", [])
        if notes:
            first_line = notes[0].title()
            self.name = LiteralScalarString(first_line) if len(first_line) > 80 else first_line
            self.notes = LiteralScalarString("\n".join(notes[1:]).title())

        self.existing_data.update(address_dict)

    def as_dict(self):
        """Return the contact as a dict."""
        rv = {}
        for key in ("name", "address", "notes", "phones", "emails", "links", "raw_original"):
            value = getattr(self, key)
            if isinstance(value, set):
                value = sorted(value)
            if value:
                rv[key] = value
        rv.update(self.existing_data)
        return rv

    def parse_phone(self, clean_line: str) -> bool:
        """Parse a phone number."""
        try:
            phone_obj = phonenumbers.parse(clean_line, "DE")
        except NumberParseException:
            return False
        if not phonenumbers.is_valid_number(phone_obj):
            return False

        formatted_phone = phonenumbers.format_number(phone_obj, phonenumbers.PhoneNumberFormat.INTERNATIONAL)
        self.phones.add(formatted_phone)
        return True

    def parse_link(self, clean_line: str) -> bool:
        """Parse a URL link."""
        if clean_line.startswith(URL_PREFIX) or "www" in clean_line:
            self.links.add(clean_line)
            return True
        return False

    def parse_email(self, clean_line: str) -> bool:
        """Parse an email."""
        if "@" in clean_line:
            found = False
            for possible_email in clean_line.split(" "):
                if "@" in possible_email:
                    self.emails.add(possible_email)
                    found = True
            return found
        return False


@contacts.command()
@click.option("--strict", "-s", is_flag=True, default=False, help="Strict mode, don't ignore case nor whitespace")
@click.argument("files", nargs=-1, type=click.Path(exists=True, file_okay=True, dir_okay=False), required=True)
def parse(strict: bool, files):
    """Parse a file with contacts and structure data in a YAML file."""
    yaml = YAML()
    yaml.indent(mapping=2, sequence=4, offset=2)

    for arg_file in files:
        output_dict: JsonDict = {}
        original_file = Path(arg_file)
        structured_contacts = []

        yaml_content: JsonDict = {}
        if original_file.suffix == ".yaml":
            try:
                yaml_content = yaml.load(original_file)
            except YAMLError:
                click.secho(f"Not a valid YAML file: {original_file}. it will be read as a .txt file", fg="red")

        if yaml_content:
            if KEY_CONTACTS not in yaml_content:
                click.secho(f"Not a valid contacts file: {original_file}. Missing 'contacts' root key.", fg="red")
                continue

            click.echo(f"Reading contacts from YAML file {original_file}")
            for contact_dict in yaml_content[KEY_CONTACTS] or []:
                contact = Contact(None, contact_dict)
                structured_contacts.append(contact.as_dict())

            # Preserve existing extra YAML content
            output_dict.update(yaml_content)
        else:
            click.echo(f"Reading contacts from text file {original_file}")
            for raw_contact_string in original_file.read_text().split(CONTACT_SEPARATOR):
                contact = Contact(raw_contact_string)
                structured_contacts.append(contact.as_dict())

        output_file = original_file.with_suffix(".yaml")
        output_dict[KEY_CONTACTS] = structured_contacts

        if output_file == original_file:
            if not strict:
                flags = (
                    "ignore-case",
                    "ignore-tab-expansion",
                    "ignore-space-change",
                    "ignore-all-space",
                    "ignore-blank-lines",
                )
                ignore_flags = " --" + " --".join(flags)
            else:
                ignore_flags = ""
            with NamedTemporaryFile() as fp:
                yaml.dump(output_dict, fp)
                diff = shell(f"colordiff --unified{ignore_flags} {original_file} {fp.name}", quiet=True)
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

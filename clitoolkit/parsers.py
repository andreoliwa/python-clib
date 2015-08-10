# -*- coding: utf-8 -*-
"""Parsers and crawlers."""
import re
import webbrowser
from datetime import datetime
from getpass import getpass
from http.client import NOT_FOUND
from time import sleep

import click
import keyring
import requests
from bs4 import BeautifulSoup
from imapclient import IMAPClient
from sqlalchemy.orm.exc import NoResultFound

from clitoolkit import LOGGER, read_config
from clitoolkit.database import SESSION_INSTANCE, SITE_IMMOSCOUT, Residence

DESTINATION = read_config('parsers', 'destination', '')
IMAP_HOST = read_config('parsers', 'imap_host', '')
IMAP_USERNAME = read_config('parsers', 'imap_username', '')
IMAP_FOLDER = read_config('parsers', 'imap_folder', '')


def imap_charset(raw_body):
    """Find the charset from the body of a raw (bytes) email message.

    :param raw_body: Raw text, byte string.
    :return: Charset.

    :type raw_body: bytes
    :rtype: str
    """
    start = raw_body.find(b'charset')
    end = start + raw_body[start:].find(b'\r')
    charset = raw_body[start:end].split(b'=')[1].decode()
    if ';' in charset:
        charset = charset.split(';')[0]
    return charset


class ImmoScout24:

    """Parse the address from Immobilien Scout 24 ads."""

    AD_URL_TEMPLATE = 'http://www.immobilienscout24.de/expose/{id}'
    MAP_URL_TEMPLATE = 'https://www.google.de/maps/dir/{origin}/{destination}/'
    REGEX = re.compile(r'expose/([0-9]+)')

    def __init__(self, session=None):
        """Init instance."""
        self.ids = []
        self.session = session or requests.session()
        self.response = None

    def parse(self, text):
        """Parse IDs from a text or a list of URLs.

        :param text: Some text with URLs to be parsed.
        :return: List of IDs found in the text.
        """
        if isinstance(text, list):
            text = ''.join(text)

        new_ids = [int(ad_id) for ad_id in set(self.REGEX.findall(text))]

        self.ids.extend(new_ids)
        self.ids = list(set(self.ids))

        return new_ids

    def crawl(self, show_existing=True, wait_for_key=False):
        """Download and parse ads.

        :param show_existing: Show existing ads when parsing.
        :param wait_for_key: Wait for a keypress after browsing an ad.
        :return: List of Residence instances.

        :rtype [Residence]
        """
        list_of_residences = []
        for index, ad_id in enumerate(self.ids):
            progress = '[{}/{}]'.format(index + 1, len(self.ids))

            try:
                residence = SESSION_INSTANCE.query(Residence).filter(
                    Residence.source_site == SITE_IMMOSCOUT).filter(Residence.source_id == ad_id).one()
                if not show_existing:
                    LOGGER.warning('%s Already exists in the database: %s', progress, residence)
                    continue
            except NoResultFound:
                residence = Residence(source_site=SITE_IMMOSCOUT, source_id=ad_id)

            residence.url = self.AD_URL_TEMPLATE.format(id=ad_id)
            soup = BeautifulSoup(self.download_html(residence.url), "html.parser")

            residence.active = (self.response.status_code != NOT_FOUND)
            address = soup.find(attrs={'data-qa': 'is24-expose-address'})
            if address is not None:
                # Take the first non blank line found in the address div
                street = [line.strip() for line in address.find_all(text=True) if line.strip()][0]
                street = ' '.join(street.split())

            SESSION_INSTANCE.add(residence)
            list_of_residences.append(residence)
            if not residence.active:
                SESSION_INSTANCE.commit()
                LOGGER.error('%s Not found in the website: %s', progress, residence.url)
                continue

            neighborhood_content = [text_only.strip() for text_only in address.children if isinstance(text_only, str)]
            neighborhood = [zipcode.split(',')[0] for zipcode in neighborhood_content if zipcode][0]

            if 'Die vollständige Adresse' in neighborhood:
                full_address = ' '.join(street.split())
            else:
                full_address = '{}, {}'.format(street, neighborhood)

            residence.address = full_address
            residence.last_seen = datetime.now()
            SESSION_INSTANCE.commit()

            self.browse(progress, 'Google Maps', self.MAP_URL_TEMPLATE.format(
                origin=full_address.replace(' ', '+'), destination=DESTINATION))
            self.browse(progress, 'AD', residence.url)
            if wait_for_key:
                # https://bitbucket.org/logilab/pylint/issue/110/false-positive-w0141-built-in-input
                input("Press ENTER to continue...")  # pylint: disable=bad-builtin
        return list_of_residences

    @staticmethod
    def browse(progress, description, url):
        """Open the URL in the browser, and shows a description on the command line.

        :param progress: Progress indicator.
        :param description: Description of the URL.
        :param url: URL of the ad.
        """
        LOGGER.info('%s %s: %s', progress, description, url)
        webbrowser.open(url)
        sleep(.2)

    def download_html(self, ad_url):
        """Download the HTML of a URL.

        :param ad_url: URL of the ad.
        :return:
        """
        self.response = self.session.get(ad_url)
        return self.response.text

    @classmethod
    def read_emails(cls, ask_password=False):
        """Read email messages with Immo Scout ads.

        :param ask_password: Force a prompt for the password.
        :return: List of emails bodies.

        :rtype: [str]
        """
        password = keyring.get_password(IMAP_HOST, IMAP_USERNAME)
        if not password or ask_password:
            password = getpass(prompt='Type your email password: ')
        if not password:
            LOGGER.error('Empty password.')
            return ''

        server = IMAPClient(IMAP_HOST, use_uid=True, ssl=True)
        server.login(IMAP_USERNAME, password)
        keyring.set_password(IMAP_HOST, IMAP_USERNAME, password)
        server.select_folder(IMAP_FOLDER)
        messages = server.search('UNSEEN')
        LOGGER.info("%d unread messages in folder '%s'.", len(messages), IMAP_FOLDER)

        emails = []
        response = server.fetch(messages, ['BODY[TEXT]', 'RFC822.SIZE'])
        for msg_id, data in response.items():
            size = data[b'RFC822.SIZE']
            LOGGER.info('Reading message ID %d (size %d).', msg_id, size)
            raw_body = data[b'BODY[TEXT]']
            try:
                body = raw_body.decode(imap_charset(raw_body))
            except LookupError as err:
                LOGGER.error(err)
                body = ''
            emails.append(body)
        return emails

    @staticmethod
    @click.command()
    @click.option('--file', '-f', 'text_file', type=click.File(), multiple=True,
                  help='Text file containing ad IDs to be parsed.')
    @click.option('--show-existing', '-s', is_flag=True, default=False,
                  help='Show existing ads when parsing.')
    @click.option('--email', '-e', is_flag=True, default=False, help='Read ads from emails.')
    @click.version_option()
    @click.argument('urls', nargs=-1)
    def main(text_file, show_existing, email, urls):
        """Parse Immobilien Scout 24 ads from URLs and/or text files given in the command line."""
        obj = ImmoScout24()
        obj.parse([one_file.read() for one_file in text_file])
        obj.parse([url for url in urls])
        if email:
            obj.parse(obj.read_emails())

        LOGGER.info('%d unique IDs.', len(obj.ids))
        obj.crawl(show_existing, True)

# -*- coding: utf-8 -*-
"""Parsers and (later) crawlers."""
from datetime import datetime
import re
import webbrowser
from time import sleep

import click
import requests
from bs4 import BeautifulSoup
from sqlalchemy.orm.exc import NoResultFound

from clitoolkit import LOGGER
from clitoolkit.database import Residence, SITE_IMMOSCOUT, SESSION_INSTANCE


class ImmoScout24:

    """Parse the address from Immobilien Scout 24 ads."""

    AD_URL = 'http://www.immobilienscout24.de/expose/{id}'
    MAP_URL = 'https://www.google.de/maps/dir/{origin}/{destination}/'
    DEFAULT_DESTINATION = 'Saarbrücker+Straße+20,+D-10405+Berlin,+Deutschland'

    def __init__(self, text):
        """Init object.

        :param text: Some text with URLs to be parsed.
        :return:
        """
        self.full_address = ''
        self.found = False
        self.ids = self.extract_ids(text)

    @staticmethod
    def extract_ids(text):
        """Extract IDs from a text (or a list of URLs).

        :param text: Text to be inspected.
        :return:
        """
        if isinstance(text, list):
            text = ''.join(text)

        regex = re.compile('expose/([0-9]+)')
        return [int(ad_id) for ad_id in set(regex.findall(text))]

    def parse(self, show_existing=True):
        """Download and parse the stored URLs.

        :param show_existing: Show existing ads when parsing.
        """
        for ad_id in self.ids:
            ad_url = self.AD_URL.format(id=ad_id)
            soup = BeautifulSoup(self.download_html(ad_url))

            self.found = True
            address = soup.find(attrs={'data-qa': "is24-expose-address"})
            if address is None:
                error = soup.find('div', {'id': 'oss-error'})
                if 'nicht gefunden' in str(error):
                    self.found = False
            else:
                # Take the first non blank line found in the address div
                street = [line.strip() for line in address.find_all(text=True) if line.strip()][0]
                street = ' '.join(street.split())

            try:
                residence = SESSION_INSTANCE.query(Residence).filter(
                    Residence.source_site == SITE_IMMOSCOUT).filter(Residence.source_id == ad_id).one()
                if not show_existing:
                    LOGGER.warning('Already exists in the database: %s', residence)
                    continue
            except NoResultFound:
                residence = Residence(source_site=SITE_IMMOSCOUT, source_id=ad_id)

            residence.url = ad_url
            residence.active = self.found
            SESSION_INSTANCE.add(residence)
            SESSION_INSTANCE.commit()
            if not self.found:
                LOGGER.error('Not found in the website: %s', ad_url)
                continue

            neighborhood_content = [text_only.strip() for text_only in address.children if isinstance(text_only, str)]
            neighborhood = [zipcode.split(',')[0] for zipcode in neighborhood_content if zipcode][0]

            if 'Die vollständige Adresse' in neighborhood:
                self.full_address = ' '.join(street.split())
            else:
                self.full_address = '{}, {}'.format(street, neighborhood)

            map_url = self.MAP_URL.format(
                origin=self.full_address.replace(' ', '+'),
                destination=self.DEFAULT_DESTINATION)

            residence.address = self.full_address
            residence.last_seen = datetime.now()
            SESSION_INSTANCE.commit()

            self.browse(map_url, 'Google Maps')
            self.browse(ad_url, 'AD')
        return self

    @staticmethod
    def browse(url, description):
        """Open the URL in the browser, and shows a description on the command line.

        :param url:
        :param description:
        """
        LOGGER.info('%s: %s', description, url)
        webbrowser.open(url)
        sleep(.2)

    @staticmethod
    def download_html(ad_url):
        """Download the HTML of a URL.

        :param ad_url: URL of the ad.
        :return:
        """
        response = requests.get(ad_url)
        return response.text


@click.command()
@click.option('--text-file', '-t', type=click.File(), multiple=True, help='Text file containing ad IDs to be parsed.')
@click.option('--show-existing', '-s', is_flag=True, default=False,
              help='Show existing ads when parsing (default False).')
@click.version_option()
@click.argument('urls', nargs=-1)
def main_immoscout(text_file, show_existing, urls):
    """Parse Immobilien Scout 24 ads from URLs and/or text files given in the command line."""
    text = [one_file.read() for one_file in text_file] + [url for url in urls]
    immo = ImmoScout24('\n'.join(text))
    LOGGER.info('%d unique IDs.', len(immo.ids))
    immo.parse(show_existing)

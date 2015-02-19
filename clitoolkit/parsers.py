# -*- coding: utf-8 -*-
"""
Parsers and (later) crawlers
"""
import argparse
import logging
import re
from time import sleep
import webbrowser

from bs4 import BeautifulSoup
import requests

logger = logging.getLogger(__name__)
logging.basicConfig(format='[%(name)s:%(levelname)s] %(message)s')


class ImmoScout24:
    """Parse the address from Immobilien Scout 24 ads.
    """
    AD_URL = 'http://www.immobilienscout24.de/expose/{id}'
    MAP_URL = 'https://www.google.de/maps/dir/{origin}/{destination}/'
    DEFAULT_DESTINATION = 'Saarbrücker+Straße+20,+D-10405+Berlin,+Deutschland'

    def __init__(self, text):
        self.full_address = ''
        self.found = False
        self.urls = self.normalize_urls(text)

    def normalize_urls(self, text):
        """Extract IDs and form URLs from a text (or a list of URLs).

        :param text: Text to be inspected.
        :return:
        """
        if isinstance(text, list):
            text = ''.join(text)

        regex = re.compile('expose/([0-9]+)')
        valid_urls = []
        for ad_id in set(regex.findall(text)):
            valid_urls.append(self.AD_URL.format(id=ad_id))
        return valid_urls

    def parse(self):
        """Download and parse the stored URLs.
        """
        for ad_url in self.urls:
            soup = BeautifulSoup(self.download_html(ad_url))

            self.found = True
            address = soup.find(attrs={'data-qa': "is24-expose-address"})
            if address is None:
                error = soup.find('div', {'id': 'oss-error'})
                if 'nicht gefunden' in str(error):
                    self.found = False
                    logger.error('Not found: %s', ad_url)
            elif address.strong is None:
                logger.error('No strong address? %s', ad_url)
                self.found = False
            else:
                street = address.strong.string.strip()

            if not self.found:
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

            self.browse(ad_url, 'AD')
            self.browse(map_url, 'Google Maps')
        return self

    @staticmethod
    def browse(url, description):
        """Open the URL in the browser, and shows a description on the command line.

        :param url:
        :param description:
        """
        logger.warning('%s: %s', description, url)
        webbrowser.open(url)
        sleep(.2)

    @classmethod
    def main(cls):
        """Function to be called when invoked at the command line.
        """
        parser = argparse.ArgumentParser()
        parser.add_argument('urls', nargs='+')
        args = parser.parse_args()
        ImmoScout24(args.urls).parse()

    @staticmethod
    def download_html(ad_url):
        """Download the HTML of a URL.

        :param ad_url: URL of the ad.
        :return:
        """
        response = requests.get(ad_url)
        return response.text

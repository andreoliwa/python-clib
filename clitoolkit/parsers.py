# -*- coding: utf-8 -*-
"""
Parsers and (later) crawlers
"""
import argparse
import re
from time import sleep
import webbrowser

from bs4 import BeautifulSoup
import requests


class ImmoScout24:
    """
    Parse the address from Immobilien Scout 24 ads
    """
    AD_URL = 'http://www.immobilienscout24.de/expose/{id}'
    MAP_URL = 'https://www.google.de/maps/dir/{origin}/{destination}/'
    DEFAULT_DESTINATION = 'Saarbrücker+Straße+20,+D-10405+Berlin,+Deutschland'

    def __init__(self, text):
        self.urls = self.extract_urls(text)

    def extract_urls(self, text):
        if isinstance(text, list):
            text = ''.join(text)

        regex = re.compile('expose/([0-9]+)')
        valid_urls = []
        for ad_id in set(regex.findall(text)):
            valid_urls.append(self.AD_URL.format(id=ad_id))
        return valid_urls

    def open_urls(self):
        for ad_url in self.urls:
            response = requests.get(ad_url)
            soup = BeautifulSoup(response.text)

            address = soup.find(attrs={'data-qa': "is24-expose-address"})
            street = address.strong.string.strip()
            neighborhood_content = [text_only.strip() for text_only in address.children if isinstance(text_only, str)]
            neighborhood = [zipcode.split(',')[0] for zipcode in neighborhood_content if zipcode][0]

            full_address = '{}, {}'.format(street, neighborhood)
            map_url = self.MAP_URL.format(
                origin=full_address.replace(' ', '+'),
                destination=self.DEFAULT_DESTINATION)

            print()
            self.open_url(ad_url, 'AD')
            self.open_url(map_url, 'Google Maps')

    @staticmethod
    def open_url(url, description):
        print('{}: {}'.format(description, url))
        webbrowser.open(url)
        sleep(.5)

    @classmethod
    def main(cls):
        parser = argparse.ArgumentParser()
        parser.add_argument('urls', nargs='+')
        args = parser.parse_args()
        ImmoScout24(args.urls).open_urls()

#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Tests for the `parsers` module.
"""
import os
from tempfile import TemporaryDirectory
import webbrowser
from zipfile import ZipFile

from clitoolkit.parsers import ImmoScout24


TEMP_DIR = TemporaryDirectory()


def setup_module():
    """Open the zip file with samples into a temp directory."""
    with ZipFile(os.path.join(os.path.dirname(__file__), 'immoscout_samples.zip')) as zip_file:
        zip_file.extractall(TEMP_DIR.name)


def teardown_module():
    """Clean the temp directory."""
    TEMP_DIR.cleanup()


def test_extract_urls_string():
    """Extract URLs from a string."""
    assert len(ImmoScout24().parse(
        'http://forward.immobilienscout24.de/9004EXPXXUA/expose/79605539?PID=63188280'
        'http://www.immobilienscout24.de/expose/79605539?PID=63188280&ftc=9004EXPXXUA&_s_cclid=1423869828'
        'http://forward.immobilienscout24.de/9004EXPXXUA/expose/79573194?PID=63188280'
        'http://forward.immobilienscout24.de/9004EXPXXUA/expose/79564822?PID=63188280')) == 3


def test_extract_urls_list():
    """Extract URLs from a list."""
    assert len(ImmoScout24().parse([
        'http://forward.immobilienscout24.de/9004EXPXXUA/expose/79605539?PID=63188280',
        'http://www.immobilienscout24.de/expose/79564822?PID=63188280&ftc=9004EXPXXUA&_s_cclid=1423869828'])) == 2


def load_file_into_string(partial_filename):
    """Load a sample HTML file into a string.

    :param partial_filename:
    :return:
    """
    full_name = os.path.join(TEMP_DIR.name, partial_filename + '.html')
    with open(full_name) as handle:
        return handle.read()


def mock_immo_scout(monkeypatch, function_name):
    """Mock the Immobilien Scout class for test purposes.

    :param monkeypatch:
    :param function_name:
    :return:
    """

    def mockreturn(self, ad_url):
        """Mock the download function.

        :param ad_url:
        :return:
        """
        assert self
        assert ad_url
        return load_file_into_string(function_name)

    monkeypatch.setattr(ImmoScout24, 'download_html', mockreturn)
    monkeypatch.setattr(webbrowser, 'open', lambda x: None)
    obj = ImmoScout24()
    obj.parse('http://forward.immobilienscout24.de/9004EXPXXUA/expose/79605539?PID=63188280')
    return obj.crawl()


def test_street_and_neighborhood(monkeypatch):
    """Full ad with street and neighborhood.

    :param monkeypatch:
    """
    immo_ads = mock_immo_scout(monkeypatch, test_street_and_neighborhood.__name__)
    assert len(immo_ads) == 1
    assert immo_ads[0].active
    assert immo_ads[0].address == 'Husemannstraße 5, 10435 Berlin'


def test_not_found(monkeypatch):
    """Ad not found.

    :param monkeypatch:
    """
    immo_ads = mock_immo_scout(monkeypatch, test_not_found.__name__)
    assert len(immo_ads) == 1
    assert not immo_ads[0].active
    assert immo_ads[0].address == 'Husemannstraße 5, 10435 Berlin'


def test_no_street(monkeypatch):
    """Ad without street, only with neighborhood.

    :param monkeypatch:
    """
    immo_ads = mock_immo_scout(monkeypatch, test_no_street.__name__)
    assert len(immo_ads) == 1
    assert immo_ads[0].active
    assert immo_ads[0].address == '10555 Berlin'

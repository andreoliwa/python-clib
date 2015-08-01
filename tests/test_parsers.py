#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Tests for the `parsers` module.
"""
import logging
import webbrowser
from clitoolkit import LOGGER

from clitoolkit.parsers import ImmoScout24

# Turn off error logging during testing
LOGGER.setLevel(logging.CRITICAL)


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


def mock_immo_scout(monkeypatch, betamax_session, ad_id):
    """Mock the Immobilien Scout class for test purposes.

    :param monkeypatch:
    :param function_name:
    :return:
    """
    monkeypatch.setattr(webbrowser, 'open', lambda x: None)
    obj = ImmoScout24()
    obj.session = betamax_session
    obj.parse('http://www.immobilienscout24.de/expose/{}'.format(ad_id))
    return obj.crawl()


def test_street_and_neighborhood(monkeypatch, betamax_session):
    """Full ad with street and neighborhood."""
    immo_ads = mock_immo_scout(monkeypatch, betamax_session, 80812783)
    assert len(immo_ads) == 1
    assert immo_ads[0].active
    assert immo_ads[0].address == 'Köbisstraße 3, 10785 Berlin, Tiergarten (Tiergarten), Köbisstraße 3'


def test_not_found(monkeypatch, betamax_session):
    """Ad not found."""
    immo_ads = mock_immo_scout(monkeypatch, betamax_session, 79605539)
    assert len(immo_ads) == 1
    assert not immo_ads[0].active
    assert immo_ads[0].address == '10555 Berlin'


def test_no_street(monkeypatch, betamax_session):
    """Ad without street, only with neighborhood."""
    immo_ads = mock_immo_scout(monkeypatch, betamax_session, 77817301)
    assert len(immo_ads) == 1
    assert immo_ads[0].active
    assert immo_ads[0].address == '10969 Berlin, 10969 Berlin'

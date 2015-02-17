#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Tests for the `parsers` module.
"""
import unittest
from clitoolkit.parsers import ImmoScout24


class TestImmoScout24(unittest.TestCase):
    def test_extract_urls_string(self):
        obj = ImmoScout24(
            'http://forward.immobilienscout24.de/9004EXPXXUA/expose/79605539?PID=63188280'
            'http://www.immobilienscout24.de/expose/79605539?PID=63188280&ftc=9004EXPXXUA&_s_cclid=1423869828'
            'http://forward.immobilienscout24.de/9004EXPXXUA/expose/79573194?PID=63188280'
            'http://forward.immobilienscout24.de/9004EXPXXUA/expose/79564822?PID=63188280')
        assert len(obj.links) == 3

    def test_extract_urls_list(self):
        obj = ImmoScout24([
            'http://forward.immobilienscout24.de/9004EXPXXUA/expose/79605539?PID=63188280',
            'http://www.immobilienscout24.de/expose/79564822?PID=63188280&ftc=9004EXPXXUA&_s_cclid=1423869828'])
        assert len(obj.links) == 2

if __name__ == '__main__':
    unittest.main()

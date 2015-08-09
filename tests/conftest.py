# -*- coding: utf-8 -*-
"""This module is always executed by pytest."""
import os

import pytest
import requests
from betamax.recorder import Betamax


@pytest.yield_fixture()
def betamax_session(request):
    """Record all HTTP requests to reuse them during tests, and avoid repeated calls."""
    session = requests.Session()
    cassette_dir = os.path.join(os.path.dirname(__file__), 'betamax',
                                request.function.__module__.replace('.', os.path.sep))
    os.makedirs(cassette_dir, 0o755, True)
    vcr = Betamax(session, cassette_dir, dict(record_mode='once'))
    vcr.use_cassette(request.function.__name__)
    vcr.__enter__()
    yield session
    vcr.__exit__()

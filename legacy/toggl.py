#!/usr/bin/python3
# -*- coding: utf-8 -*-
# PYTHON_ARGCOMPLETE_OK
"""
Playing with the Toggl API.
"""

def main():
    """
    Entry point, C-style.
    """
    which_day = '2014-12-16'

    import keyring
    api_token = keyring.get_password('toggl', 'api_token')
    if api_token == None:
        # http://stackoverflow.com/questions/2052390/how-do-i-manually-throw-raise-an-exception-in-python/24065533#24065533
        raise ValueError("The API token must be in the keyring. Call keyring.get_password('toggl', 'api_token', 'BLABLABLA')." \
            " The token can be found here: https://www.toggl.com/app/profile")

    import requests
    payload = {'user_agent': 'wagnerandreoli@gmail.com', 'workspace_id': '182438', 'since': which_day, 'until': which_day, \
        'client_ids': '15795092', 'order_field': 'date', 'order_desc': 'off', 'page': '1'}
    # https://github.com/toggl/toggl_api_docs/blob/master/reports/detailed.md
    req = requests.get('https://toggl.com/reports/api/v2/details', auth=(api_token, 'api_token'), params=payload)
    result = req.json()

    last_entry = result['total_count']

    # http://stackoverflow.com/questions/969285/how-do-i-translate-a-iso-8601-datetime-string-into-a-python-datetime-object
    import dateutil.parser

    start = dateutil.parser.parse(result['data'][0]['start'])
    print('Start: {:s}'.format(start.strftime('%c')))

    end = dateutil.parser.parse(result['data'][last_entry - 1]['end'])
    print('End: {:s}'.format(end.strftime('%c')))

    import datetime
    # work_hours_per_day = datetime.time(9)

    # http://stackoverflow.com/questions/3426870/calculating-time-difference
    office_presence = end - start
    print(office_presence)

    # http://stackoverflow.com/questions/441147/how-can-i-subtract-a-day-from-a-python-date
    print(office_presence - datetime.timedelta(hours=9))

if __name__ == '__main__':
    main()

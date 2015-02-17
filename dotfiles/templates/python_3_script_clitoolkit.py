#!/usr/bin/python3
# -*- coding: utf-8 -*-
# PYTHON_ARGCOMPLETE_OK
"""
TODO Your help text here.
"""


def do_something(args):
    """
    TODO Do something.
    """
    print(args.files)
    print('Something done')


def do_another_hing(args):
    """
    TODO Do something.
    """
    if args.flag:
        print('Flag was set')
    print('Another thing done')


def main():
    """
    Entry point, C-style.
    """
    import argparse
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(description='')

    something_command = subparsers.add_parser('something', help='do something')
    something_command.set_defaults(func=do_something)
    something_command.add_argument('files', nargs=argparse.REMAINDER, help='some list of files')

    another_thing_command = subparsers.add_parser('another-thing', help='do another thing')
    another_thing_command.set_defaults(func=do_another_hing)
    another_thing_command.add_argument('-f', '--flag', action='store_true', help='some flag')

    import argcomplete
    argcomplete.autocomplete(parser)
    args = parser.parse_args()
    if hasattr(args, 'func'):
        args.func(args)
        return

    parser.print_usage()

if __name__ == '__main__':
    main()

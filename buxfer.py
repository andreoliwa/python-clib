#!/usr/bin/python3
# -*- coding: utf-8 -*-
# PYTHON_ARGCOMPLETE_OK
"""
A script with several commands to help with Buxfer finance management.
"""
import argcomplete
import argparse
import datetime
import dateutil.relativedelta
import fnmatch
import os
import re
import shlex
import subprocess

USED_TSV_FILES = []


def convert_pdf_to_tsv(args):
    """
    Converts one or more PDF credit card statements to TSV files.
    """
    for file in args.file_or_dir:
        expanded = os.path.abspath(file)
        if os.path.isfile(expanded):
            convert_one_pdf(expanded, args)
        elif os.path.isdir(expanded):
            print("Recursively searching PDF files in the '%s' directory..." % expanded)
            files = []
            for root, dirnames, filenames in os.walk(expanded):  # pylint: disable=W0612
                for filename in fnmatch.filter(filenames, '*.pdf'):
                    files.append(os.path.join(root, filename))
            for file in sorted(files):
                convert_one_pdf(file, args)
        else:
            print("ERROR: The file or directory '%s' does not exist!" % expanded)
    return True


def pdf_contents(pdf_filename):
    """
    Read PDF contents into a string.
    """
    tmp_file = '/tmp/buxfer.py.tmp'
    conversion_cmd = 'pdftotext -layout "%s" "%s"' % (pdf_filename, tmp_file)
    print("Converting PDF with external program... (%s)" % conversion_cmd)
    if subprocess.call(shlex.split(conversion_cmd), stderr=subprocess.STDOUT) > 0:
        print('ERROR: File was not converted')
    if not os.path.isfile(tmp_file):
        print("ERROR: Temp file %s doesn't exist" % tmp_file)
    with open(tmp_file, "r") as handle:
        string = handle.read().replace('\n', ' ')
    os.remove(tmp_file)
    return string


def prepare_tsv_file(pdf_filename, args):
    """
    Determine the name of the TSV file based on the PDF filename.
    Also:
    - create the TSV dir if not found;
    - remove the previous TSV file if found.
    """
    bank_dir = os.environ['G_BANK_STATEMENTS_DIR']
    tsv_dir = os.path.join(bank_dir, 'buxfer', 'new')
    if not os.path.isdir(tsv_dir):
        os.makedirs(tsv_dir)

    if args.join_by_parent:
        basename = os.path.dirname(pdf_filename).replace(bank_dir, '').replace(os.path.sep, '-').strip(' -')
    else:
        basename = os.path.basename(os.path.splitext(pdf_filename)[0])
    fullname = os.path.join(tsv_dir, basename + '.tsv')

    # Remove a TSV file only when it is used for the first time
    if fullname not in USED_TSV_FILES:
        USED_TSV_FILES.append(fullname)
        if os.path.isfile(fullname):
            print("  Removing the TSV file '%s' before filling it..." % fullname)
            os.remove(fullname)

    return fullname


def convert_one_pdf(pdf_filename, args):
    """
    Convert a single PDF file to a TSV.
    """
    if os.path.splitext(pdf_filename)[1].lower() != '.pdf':
        print("  ERROR: File '%s' is not a PDF" % pdf_filename)
        return False

    string = pdf_contents(pdf_filename)

    # Find statement date
    regex = re.compile(r"Data de fechamento|Vencimento[^0-9]+([0-9]{2}/[0-9]{2}/[0-9]{4})", re.IGNORECASE)
    matches = regex.findall(string)
    if not len(matches):
        print('  No statement date was found: %s' % string)
        return False
    statement_date = matches[0]

    # Find expenses
    regex = re.compile(r"([0-9]{2}/[0-9]{2})[ -]+([^\(\)]+?)[ 0,]+([0-9]{1,},[0-9]{2})")
    transactions = regex.findall(string)
    if len(transactions) == 0:
        print('  No transactions were found: %s' % string)
        return False

    # Find last payment
    regex = re.compile(r"(?P<description>Pagamento efetuado) em (?P<date>[0-9/]+)[ -]+(?P<value>[0-9.,]+)")
    matches = regex.search(string)
    if matches is None:
        # Remove the payment among the transactions (it used to be like this in older statements)
        matches = [i for i, v in enumerate(transactions) if 'pagamento efetuado' in v[1].lower()]
        if len(matches):
            transactions.pop(matches[0])

        regex = re.compile(r"(?P<date>[0-9/]+)[ -]+(?P<description>Pagamento efetuado) +(?P<value>[0-9.,]+)", re.IGNORECASE)
        matches = regex.search(string)

    if matches is None:
        print('  WARNING: No payment was found')
    else:
        payment = matches.groupdict()
        transactions.append((payment['date'], payment['description'], '+' + payment['value']))

    print('  Statement from %s with %d transaction(s)' % (statement_date, len(transactions)))
    tsv_filename = prepare_tsv_file(pdf_filename, args)
    # Always append to the TSV file; the prepare_tsv_file() removes the file at the first use
    with open(tsv_filename, "a") as handle:
        for (date, description, br_value) in transactions:
            eng_value = br_value.replace('.', '').replace(',', '.')
            if eng_value[0] == '+':
                eng_value = eng_value[1:]
            else:
                eng_value = '-' + eng_value

            handle.write('%s;%s;%s\n' % (description, eng_value, formatted_date(date, statement_date)))

    print("  File '%s' saved" % tsv_filename)
    return True


def formatted_date(transaction_date, statement_date):
    """
    Calculate transaction year from statement, and return formatted date.
    """
    if len(transaction_date) == 5:
        date_with_year = transaction_date + statement_date[5:]
    else:
        date_with_year = transaction_date

    date_obj = datetime.datetime.strptime(date_with_year, "%d/%m/%Y")
    if date_obj.isoformat()[:10] > datetime.datetime.strptime(statement_date, "%d/%m/%Y").isoformat()[:10]:
        date_obj -= dateutil.relativedelta.relativedelta(years=1)

    return date_obj.isoformat()[:10]


def main():
    """
    Entry point, C-style.
    """
    parser = argparse.ArgumentParser(description='A script with several commands to help with Buxfer finance management.')

    subparsers = parser.add_subparsers(description='')

    pdf_command = subparsers.add_parser('pdf-to-tsv', help='converts one or more PDF credit card statements to TSV files')
    pdf_command.set_defaults(func=convert_pdf_to_tsv)
    pdf_command.add_argument('file_or_dir', nargs='+', help='PDF file to convert to TSV, or directory to be searched recursively')
    pdf_command.add_argument('-p', '--join-by-parent', help="join results in a single TSV file, grouped by the parent directory's name", action='store_true')

    argcomplete.autocomplete(parser)
    args = parser.parse_args()
    if hasattr(args, 'func'):
        if args.func(args):
            return

    parser.print_usage()

if __name__ == '__main__':
    main()

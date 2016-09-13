from django.core.management.base import BaseCommand, CommandError
from match.models import Address

import csv

class Command(BaseCommand):
    help = 'Import a list of addresses from a file'

    def add_arguments(self, parser):
        # Positional arguments
        parser.add_argument('filename')

    def handle(self, *args, **options):
        # read a file and copy its contents as test addresses

        with open(options['filename'], 'r') as address_file:
            tsvin = csv.reader(address_file, delimiter='\t')

            for row in tsvin:
                l = len(row)
                print row
                print len(row)
                address = Address.objects.create(
                    line1 = row[1] if l > 1 else '',
                    line2 = row[2] if l > 2 else '',
                    line3 = row[3] if l > 3 else '',
                    line4 = row[4] if l > 4 else '',
                    line5 = row[5] if l > 5 else '',
                    line6 = row[6] if l > 6 else '',
                    line7 = row[7] if l > 7 else ''
                )

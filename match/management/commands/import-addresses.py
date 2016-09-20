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

        Address.objects.all().delete()

        with open(options['filename'], 'r') as address_file:
            tsvin = csv.reader(address_file, delimiter='\t')

            for row in tsvin:
                Address.objects.create(
                    test_id = row[0],
                    address = ', '.join(row[1:])
                )

from django.core.management.base import BaseCommand, CommandError
from match.models import Address, AppInfo

import csv
import sys

class Command(BaseCommand):
    help = 'Import a list of addresses stdin'

    def add_arguments(self, parser):
         # Positional arguments
         parser.add_argument('title')


    def handle(self, *args, **options):

        # Set the test address set title
        AppInfo.objects.all().delete()
        AppInfo.objects.create(
            key = 'title',
            value = options['title']
        )

        # copy test addresses from stdin
        Address.objects.all().delete()
        tsvin = csv.reader(sys.stdin, delimiter='\t')
        for row in tsvin:
            Address.objects.create(
                test_id = row[0],
                name = row[1],
                address = ', '.join(row[2:])
            )

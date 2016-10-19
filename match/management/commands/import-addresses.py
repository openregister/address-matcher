from django.core.management.base import BaseCommand, CommandError
from match.models import Address

import csv
import sys

class Command(BaseCommand):
    help = 'Import a list of addresses stdin'

    def handle(self, *args, **options):
        # read a file and copy its contents as test addresses

        Address.objects.all().delete()

        tsvin = csv.reader(sys.stdin, delimiter='\t')

        for row in tsvin:
            Address.objects.create(
                test_id = row[0],
                address = ', '.join(row[1:])
            )

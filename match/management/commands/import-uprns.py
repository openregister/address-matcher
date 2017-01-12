from django.core.management.base import BaseCommand, CommandError
from match.models import RegisterAddress

import csv
import sys

class Command(BaseCommand):
    help = 'Import a list of users from stdin'

    def handle(self, *args, **options):

        csvin = csv.reader(sys.stdin, delimiter='\t')

        for row in csvin:
            RegisterAddress.objects.get_or_create(
                uprn = row[0],
                name = row[1],
                parent_address_name = row[2],
                street_name = row[3],
                street_town = row[4]
            )

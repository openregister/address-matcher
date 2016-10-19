from django.core.management.base import BaseCommand, CommandError
from match.models import User

import csv
import sys

class Command(BaseCommand):
    help = 'Import a list of users from stdin'

    def handle(self, *args, **options):
        # read a file and copy its contents as test users

        tsvin = csv.reader(sys.stdin, delimiter='\t')

        for row in tsvin:
            User.objects.create(
                name = row[0]
            )

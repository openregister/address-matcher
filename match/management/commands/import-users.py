from django.core.management.base import BaseCommand, CommandError
from match.models import User

import csv
import sys

class Command(BaseCommand):
    help = 'Import a list of users from stdin'

    def handle(self, *args, **options):
        # read a file and copy its contents as test users

        User.objects.all().delete()

        csvin = csv.reader(sys.stdin, delimiter=',')

        for row in csvin:
            User.objects.create(
                name = row[0],
                score = row[1]
            )

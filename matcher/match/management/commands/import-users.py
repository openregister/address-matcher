from django.core.management.base import BaseCommand, CommandError
from match.models import User

import csv

class Command(BaseCommand):
    help = 'Import a list of users from a file'

    def add_arguments(self, parser):
        # Positional arguments
        parser.add_argument('filename')

    def handle(self, *args, **options):
        # read a file and copy its contents as test users

        with open(options['filename'], 'r') as user_file:
            tsvin = csv.reader(user_file, delimiter='\t')

            for row in tsvin:
                User.objects.create(
                    name = row[0]
                )

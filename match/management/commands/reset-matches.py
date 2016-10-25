from django.core.management.base import BaseCommand, CommandError
from match.models import Match

import sys

class Command(BaseCommand):
    help = 'Reset all match data'

    def handle(self, *args, **options):
        Match.objects.all().delete()

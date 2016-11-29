from django.core.management.base import BaseCommand, CommandError
from match.models import Match, User

import sys

class Command(BaseCommand):
    help = 'Reset all match data'

    def handle(self, *args, **options):
        Match.objects.all().delete()

        for user in User.objects.all():
            user.score = 0
            user.save()

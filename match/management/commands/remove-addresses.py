from django.core.management.base import BaseCommand, CommandError
from match.models import Match, Address

import sys

class Command(BaseCommand):
    help = 'Remove unmatched test addresses'

    def add_arguments(self, parser):
         # Positional arguments
         parser.add_argument('count')

    def handle(self, *args, **options):

        count = int(options['count'])
        matches = Match.objects.all()
        addresses = Address.objects.all()

        a = []
        for m in matches:
            a.append(m.test_address.id)
        matched_address_ids = set(a)

        for address in addresses:
            if address.id not in matched_address_ids:
                address.delete()
                count = count - 1
                if count == 0:
                    break;

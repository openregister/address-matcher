from django.core.management.base import BaseCommand, CommandError
from match.models import Address
from postal.parser import parse_address
from elasticsearch import Elasticsearch

import json
import os
import csv
import random
import sys
import re

class Command(BaseCommand):
    help = 'Import a list of addresses stdin'

    def add_arguments(self, parser):
        parser.add_argument("-s", "--seed", dest="seed", required=True)



    def handle(self, *args, **options):

        random.seed(int(options['seed']))
        tests = Address.objects.all()
        length = len(tests)

        for r in range(0, 4):
            print ("\n\n\n")
            test = tests[random.randint(0, length-1)]



            full_test = "%s, %s" % (test.name, test.address)
            print(full_test)
            self.brain(full_test)




    def brain(self, test_address):

        # Escape chars for ElasticSearch
        # test_address = re.sub(
        #     r'([+-=&|><!(){}\[\]^"~*?:\\/\'])',
        #     r'\\\1',
        #     test_address)

        parsed = parse_address(test_address)
        dparse2 = dict(zip(dict(parsed).values(),dict(parsed).keys()))
        parent_address_name = dparse2.get('house', '')
        name = dparse2.get('house_number', '')
        street_name = dparse2.get('road', '')
        street_town = dparse2.get('city', '')

        queryObject_new = {
            "size": 9,
            "_source": ["parent-address-name", "street-name", "street-town", "name", "address"],
            "query": {
                "bool": {
                    "should": [
                        { "match": { "parent-address-name": parent_address_name }},
                        { "match": { "name": name }},
                        { "match": { "street-name": street_name }},
                        { "match": { "street-town": street_town }},
                        { "match": { "_all": test_address }}
                    ]
                }
            }
        }

        queryObject_old = {
            "size": 9,
            "_source": ["parent-address-name", "street-name", "street-town", "name", "address"],
            "query": {
                "match": {
                    "_all": test_address
                }
            }
        }

#        print(queryObject_old)


        elasticHost = os.getenv('ELASTICSEARCH_HOST', 'localhost:9200')
        es = Elasticsearch([elasticHost])

        result_new = es.search(index="flattened", body=json.dumps(queryObject_new))
        result_old = es.search(index="flattened", body=json.dumps(queryObject_old))

        # candidate_addresses = []
        # for candidate in result['hits']['hits']:
        #     c = candidate['_source']
        #     newCandidate = {
        #         'uprn': c['address'],
        #         'name': c['name'],
        #         'street-name': c['street-name'],
        #         'parent-address-name': c['parent-address-name'],
        #         'street-town': c['street-town']
        #     }
        #     candidate_addresses.append(newCandidate)

        # return JsonResponse(candidate_addresses, safe=False)

        print('== OLD ==============================================')
        self.format_candidate(result_old)
        print('== NEW ==============================================')
        self.format_candidate(result_new)



    def format_candidate(self, results):
        for candidate in results['hits']['hits']:
            score = candidate['_score']
            c = candidate['_source']
            print('%s, %s, %s, %s - %f' % (c['name'], c['parent-address-name'], c['street-name'], c['street-town'], score))

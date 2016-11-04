from django.shortcuts import render
from django.http import HttpResponse, JsonResponse
from django.template import loader
from django.db.models import Count
from random import randint
from hashlib import md5
from models import Address, Match, User
from elasticsearch import Elasticsearch
import os
import json
import re
import random


def index(request):
    template = loader.get_template('main.html')
    context = {}
    return HttpResponse(template.render(context, request))


def count_matches(min_matches):
    # return the number of addresses
    # query: select count(*) from (select test_address_id, count(id) from match_match group by test_address_id) as derived where count = matches;
    return;



def scores(request):
    matches = Match.objects.all()
    users = User.objects.all()
    addresses = Address.objects.all()

    stats = {}
    stats['users'] = []
    for user in users:
        user_stats = { 'name': user.name, 'user_id': user.pk}
        user_matches = Match.objects.filter(user__id = user.pk)
        nb_user_matches = len(user_matches)
        user_stats['nb_matches'] = nb_user_matches
        user_stats['score'] = user_score(nb_user_matches)
        if user_stats['score'] > 0:
            stats['users'].append(user_stats)

    stats['users'].sort(key=lambda x: x['score'], reverse=True)

    stats['nb_addresses'] = Address.objects.count()
    stats['nb_matches'] = Match.objects.count()
    stats['nb_addresses_matched'] = len(matches.annotate(
        Count('test_address__id', distinct=True)))


    template = loader.get_template('scores.html')

    return HttpResponse(template.render(stats, request))


def randomBool(dummy):
    rnd = randint(0,100)
    return rnd > 50


def degraded_address(address):
    words = address.split()
    missing_words = filter(randomBool, words)
    return ' '.join(missing_words)


def brain(request):
    test_address = request.GET.get('q', '')
    test_address = re.sub(
        r'([+-=&|><!(){}\[\]^"~*?:\\/\'])',
        r'\\\1',
        test_address)

    queryObject = {
        "size": 9,
        "_source": ["parent-address-name", "street-name", "street-town", "name", "address"],
        "query": {
            "match": {
                "_all": test_address
            }
        }
    }

    elasticHost = os.getenv('ELASTICSEARCH_HOST', 'localhost:9200')
    es = Elasticsearch([elasticHost])
    result = es.search(index="flattened", body=json.dumps(queryObject))

    candidate_addresses = []
    for candidate in result['hits']['hits']:
        c = candidate['_source']
        newCandidate = {
            'uprn': c['address'],
            'name': c['name'],
            'street-name': c['street-name'],
            'parent-address-name': c['parent-address-name'],
            'street-town': c['street-town']
        }
        candidate_addresses.append(newCandidate)

    return JsonResponse(candidate_addresses, safe=False)


def random_test_addresses(request):
    number_requested = int(request.GET.get('n', 5))
    last = Address.objects.count() - 1
    addresses = []
    for i in range(0, number_requested):
        index = random.randint(0, last)
        address = Address.objects.all()[index]
        addresses.append({
            'id': address.id,
            'name' : address.name,
            'address': address.address
        })
    return JsonResponse(addresses, safe=False)


def user_score(nb_matches):
    return nb_matches

def stats(request):
    stats = {}
    stats['nb_matches'] = Match.objects.count()
    stats['users'] = []
    for user in User.objects.all():
        user_stats = { 'name': user.name, 'user_id': user.pk}
        user_matches = Match.objects.filter(user__id = user.pk)
        nb_user_matches = len(user_matches)

        user_stats['nb_matches'] = nb_user_matches
        user_stats['score'] = user_score(nb_user_matches)
        stats['users'].append(user_stats)

    return JsonResponse(stats)

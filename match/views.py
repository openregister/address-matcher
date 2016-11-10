from django.shortcuts import render
from django.http import HttpResponse, JsonResponse
from django.template import loader
from django.db.models import Count
from django.utils.safestring import mark_safe
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


def count_matches():
    # compute how many times each address is referred to in matches
    addresses = Address.objects.all()
    matches = Match.objects.all()

    # dictionary: address_id -> int (reference count)
    count_matches = {}

    for address in addresses:
        count_matches[address.id] = 0;

    for match in matches:
        count_matches[match.test_address_id] = count_matches[match.test_address_id] + 1

    return count_matches


def occurrence_dict(counts):
    # generate dictionary that gives the number of addresses
    # for each occurrence count:
    # count -> how many addresses have that count
    addresses = Address.objects.all()
    matches = Match.objects.all()

    occurrence_nbaddresses = {}
    for occurrence in range(0, len(matches)):
        occurrence_nbaddresses[occurrence] = \
            len({k: v for k, v in counts.iteritems() if v == occurrence})

    non_zero = [["Addresses with " + str(k) + " matches", v] for k, v in occurrence_nbaddresses.iteritems() if v != 0]


    return mark_safe(json.dumps(non_zero))

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

    stats['occurrences'] = occurrence_dict(count_matches())
    stats['nb_pass'] = len(Match.objects.filter(uprn__exact = "_unknown_"))

    stats['nb_pass_ratio'] = round(100*float(stats['nb_pass']) / stats['nb_matches']) if stats['nb_matches'] > 0 else 0


    template = loader.get_template('scores.html')

    return HttpResponse(template.render(stats, request))


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

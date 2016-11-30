from django.shortcuts import render
from django.http import HttpResponse, JsonResponse
from django.template import loader
from django.db.models import Count
from django.utils.safestring import mark_safe
from django.views.decorators.csrf import csrf_exempt
from datetime import datetime
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

def wordy_match(nb_matches):
    if nb_matches == 0:
        return "Addresses not yet matched"
    elif nb_matches == 1:
        return "Addresses matched once"
    elif nb_matches == 2:
        return "Addresses matched twice"
    else:
        return "Addresses matched " + str(nb_matches) + " times"


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

    non_zero = [[wordy_match(k), v] for k, v in occurrence_nbaddresses.iteritems() if v != 0]
    return non_zero


def make_users_stats():
    matches = Match.objects.all()
    users = User.objects.all()
    users_stats = []
    for user in users:
        user_stats = { 'name': user.name, 'id': user.pk}
        user_matches = Match.objects.filter(user__id = user.pk)
        nb_user_matches = len(user_matches)
        user_stats['score'] = user.score
        users_stats.append(user_stats)
    return users_stats


def make_stats():
    matches = Match.objects.all()
    users = User.objects.all()
    addresses = Address.objects.all()
    stats = {}
    stats['users'] = filter(lambda x: x['score'] != 0, make_users_stats())
    stats['nb_addresses'] = Address.objects.count()
    stats['nb_matches'] = Match.objects.count()
    stats['occurrences'] = occurrence_dict(count_matches())
    stats['nb_pass'] = len(Match.objects.filter(uprn__exact = "_unknown_"))
    stats['nb_pass_ratio'] = round(100*float(stats['nb_pass']) / stats['nb_matches']) if stats['nb_matches'] > 0 else 0
    return stats;



def scores(request):
    template = loader.get_template('scores.html')
    stats = make_stats()
    stats['occurrences'] = mark_safe(json.dumps(stats['occurrences']))
    return HttpResponse(template.render(stats, request))


def scores_json(request):
    return JsonResponse(make_stats())


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


@csrf_exempt
def send(request):
    user = User.objects.get(pk=request.POST['user'])
    test = Address.objects.get(pk=request.POST['test_address'])
    uprn = request.POST['uprn']
    Match.objects.create(
        test_address = Address.objects.get(pk=request.POST['test_address']),
        user = user,
        uprn = uprn,
        date = datetime.now()
    )

    # update users' score
    nb_previous_matches = len(Match.objects.filter(
        test_address=test
    ).filter(
        uprn=uprn
    ).exclude(
        user=user
    ))

    # If there have been 3 or more similar matches, score that - 1
    # Otherwise, score 1 point
    if nb_previous_matches >= 3:
        match_score = nb_previous_matches - 1
    else:
        match_score = 1

    user.score = user.score + match_score
    user.save()

    # return user scores for immediate display
    response = {
        'users': make_users_stats(),
        'last_match_score': match_score
    }
    return JsonResponse(response, safe=False)


# Get the next test addresses for a given users
def random_test_addresses(request):
    num = int(request.GET.get('n', 5))
    user_id = int(request.GET.get('userid', 0))

    # find latest match from this user
    if len(Match.objects.all()) == 0:
        # No match yet, just pick first n address
        address = Address.objects.first()
    else:
        latest_user_match = Match.objects.filter(user_id=user_id).order_by('-date').first()
        if latest_user_match == None:
            latest_user_match = Match.objects.first()
        address = latest_user_match.test_address;

    addresses = []
    for i in range(0, num):
        addresses.append({
            'id': address.id,
            'name' : address.name,
            'address': address.address
        })
        address = address.get_next()

    return JsonResponse(addresses, safe=False)

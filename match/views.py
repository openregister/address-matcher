from django.shortcuts import render
from django.http import HttpResponse, JsonResponse
from django.template import loader
from django.db.models import Count
from random import randint
from hashlib import md5
from models import Address, Match, User
import random


def index(request):
    template = loader.get_template('main.html')
    context = {}
    return HttpResponse(template.render(context, request))


def scores(request):
    matches = Match.objects.all()
    users = User.objects.all()
    addresses = Address.objects.all()

    stats = {}
    stats['nb_matches'] = Match.objects.count()
    stats['users'] = []
    for user in users:
        user_stats = { 'name': user.name, 'user_id': user.pk}
        user_matches = Match.objects.filter(user__id = user.pk)
        nb_user_matches = len(user_matches)

        user_stats['nb_matches'] = nb_user_matches
        user_stats['score'] = user_score(nb_user_matches)
        stats['users'].append(user_stats)
    stats['users'].sort(key=lambda x: x['score'], reverse=True)

    stats['nb_addresses'] = Address.objects.count()
    stats['nb_matches'] = Match.objects.count()
    stats['nb_addresses_matched'] = len(matches.annotate(
        Count('test_address__id', distinct=True)))

    stats['addresses'] = []

    matched_addresses = []
    for address in addresses:
        address_matches = Match.objects.filter(
            test_address__id = address.pk)
        if len(address_matches) > 0:
            ma = {'address': address, 'nb_matches': len(address_matches) }
            matched_addresses.append(ma)
    stats['matched_addresses'] = sorted(matched_addresses,
        key=lambda x: x['nb_matches'], reverse=True)[:3]



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
    candidate_addresses = []
    m = md5()
    for i in range(0, 9):
        address = degraded_address(test_address)
        hash = m.update(address)
        candidate_addresses.append({
            'address': address,
            'uprn': m.hexdigest()[:6]
        })
    candidate_addresses.sort(lambda x,y: len(y['address'])-len(x['address']))
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

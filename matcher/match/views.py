from django.shortcuts import render
from django.http import HttpResponse, JsonResponse
from random import randint
from hashlib import md5

def index(request):
    return HttpResponse("Hello, world. You're at the match index.")

def randomBool(dummy):
    rnd = randint(0,100)
    return rnd > 20

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
            'uprn': m.hexdigest()
        })


    return JsonResponse({
        'q':test_address,
        'candidates': candidate_addresses
    })

from __future__ import unicode_literals

from django.db import models

class Address(models.Model):
    line1 = models.CharField(max_length=200)
    line2 = models.CharField(max_length=200)
    line3 = models.CharField(max_length=200)
    line4 = models.CharField(max_length=200)
    line5 = models.CharField(max_length=200)
    line6 = models.CharField(max_length=200)


class Match(models.Model):
    test_address = models.ForeignKey(Address)
    uprn = models.CharField(max_length=20)
    confidence = models.FloatField()
    date = models.DateField()


class User(models.Model):
    name = models.CharField(max_length=200)
    matches = models.ForeignKey(Match)


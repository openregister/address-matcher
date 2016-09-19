from __future__ import unicode_literals

from django.db import models
from datetime import datetime

class Address(models.Model):
    test_id = models.CharField(max_length=50, blank=True)
    address = models.CharField(max_length=512, blank=True)

    def __str__(self):
        return self.test_id + ': ' + self.address

class User(models.Model):
    name = models.CharField(max_length=200)

class Match(models.Model):
    test_address = models.ForeignKey(Address)
    user = models.ForeignKey(User)
    uprn = models.CharField(max_length=20)
    date = models.DateTimeField(default=datetime.now)

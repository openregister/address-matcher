from __future__ import unicode_literals

from django.db import models
from datetime import datetime


class AppInfo(models.Model):
    key = models.CharField(max_length=128)
    value = models.CharField(max_length=255)

    def __str__(self):
        return self.key + ": " + self.value


class Address(models.Model):
    test_id = models.CharField(max_length=50, blank=True)
    name = models.CharField(max_length=256, blank=True)
    address = models.CharField(max_length=512, blank=True)

    def __str__(self):
        return "%s (%s)" % (self.name, self.test_id)


class User(models.Model):
    name = models.CharField(max_length=200)

    def __str__(self):
        return self.name


class Match(models.Model):
    test_address = models.ForeignKey(Address)
    user = models.ForeignKey(User)
    uprn = models.CharField(max_length=20)
    date = models.DateTimeField(default=datetime.now)

    def __str__(self):
        return self.user.name + " thinks " + self.test_address.test_id + " is " + self.uprn

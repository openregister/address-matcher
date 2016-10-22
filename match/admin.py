from django.contrib import admin

from .models import Address, User, Match, AppInfo

admin.site.register(Address)
admin.site.register(User)
admin.site.register(Match)
admin.site.register(AppInfo)

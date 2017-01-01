from django.conf.urls import url, include
from rest_framework import routers, serializers, viewsets
from models import User, Match, Address, AppInfo

from . import views


# Serializers define the API representation.
class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = "__all__"


class MatchSerializer(serializers.ModelSerializer):
    class Meta:
        model = Match
        fields = "__all__"


class AddressSerializer(serializers.ModelSerializer):
    class Meta:
        model = Address
        fields = "__all__"


class AppInfoSerializer(serializers.ModelSerializer):
    class Meta:
        model = AppInfo
        fields = "__all__"


# ViewSets define the view behavior.
class UserViewSet(viewsets.ModelViewSet):
    queryset = User.objects.all()
    serializer_class = UserSerializer


class MatchViewSet(viewsets.ModelViewSet):
    queryset = Match.objects.all()
    serializer_class = MatchSerializer


class AddressViewSet(viewsets.ModelViewSet):
    queryset = Address.objects.all()
    serializer_class = AddressSerializer


class AppInfoViewSet(viewsets.ModelViewSet):
    queryset = AppInfo.objects.all()
    serializer_class = AppInfoSerializer



# Routers provide an easy way of automatically determining the URL conf.
router = routers.DefaultRouter()
router.register(r'users', UserViewSet)
router.register(r'matches', MatchViewSet)
router.register(r'addresses', AddressViewSet)
router.register(r'appinfo', AppInfoViewSet)

# Wire up our API using automatic URL routing.
# Additionally, we include login URLs for the browsable API.
urlpatterns = [
    url(r'^brain/$', views.brain, name='brain'),
    url(r'^test-addresses/$', views.random_test_addresses, name='test-addresses'),
    url(r'^main/$', views.index, name='main'),
    url(r'^send/$', views.send, name='matches2'),
    url(r'^scores/$', views.scores, name='scores'),
    url(r'^tests/$', views.tests, name='tests'),
    url(r'^test/(?P<id>[0-9]+)/$', views.test, name='test'),
    url(r'^help/$', views.help, name='help'),
    url(r'^scores.json$', views.scores_json),
    url(r'^', include(router.urls)),
    url(r'^api-auth/', include('rest_framework.urls', namespace='rest_framework'))
]

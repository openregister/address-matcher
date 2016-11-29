#!/bin/bash

USERS_LIST=./data/sample-users.tsv
NAME_ADDRESSES="Charity Commission"
TEST_ADDRESSES=./data/test-addresses-01.tsv

export ELASTICSEARCH_HOST=http://3kda-fd.:23wk-jdf@ec2-52-209-186-220.eu-west-1.compute.amazonaws.com:8000

docker-compose build
docker-compose run web ./manage.py makemigrations
docker-compose run web ./manage.py migrate
docker-compose run web ./manage.py createsuperuser
docker-compose run web ./manage.py import-users < $USERS_LIST
docker-compose run web ./manage.py import-addresses "$NAME_ADDRESSES" < $TEST_ADDRESSES
docker-compose up

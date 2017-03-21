# address-matcher
UI for matching addresses


# Running locally

Reqirements:
- python 2.7
- postgresql

```
$ sudo -u postgres bash -c "psql -c \"create user matcher with password 'matcher' createdb;\""
$ sudo -u postgres bash -c "psql -c \"create database matcher owner matcher;\""
$ virtualenv venv
$ source venv/bin/activate
$ pip install -r requirements.txt
$ export DATABASE_URL=postgres://matcher:matcher@localhost:5432/matcher
$ export ELASTICSEARCH_HOST=[URL of the elasticsearch address matching server]
$ ./manage.py migrate
$ ./manage.py import-users < data/sample-users.csv
$ ./manage.py import-addresses "My test addresses" < data/test-addresses-01.tsv
$ ./manage.py runserver
```

## Deploying on Heroku

Following https://devcenter.heroku.com/articles/deploying-python#build-your-app-and-run-it-locally

Check that
```
$ heroku local web
```
works. Then:
```
$ heroku login
$ heroku create
$ heroku config:set DISABLE_COLLECTSTATIC=1
$ heroku config:set ELASTICSEARCH_HOST="http://xyz:8000"
$ git push heroku master
$ heroku run python manage.py migrate
$ heroku run ./manage.py import-users < data/sample-users.csv
$ heroku run ./manage.py import-addresses "Title of your address set" < data/test-addresses-01.tsv
$ heroku open
```

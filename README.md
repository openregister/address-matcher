# address-matcher
UI for matching addresses


# Running locally

```
$ virtualenv venv
$ source venv/bin/activate
$ pip install -r requirements.txt
$ export DATABASE_URL=postgres://matcher:matcher@localhost:5432/matcher
$ ./manage.py import-users /app/data/sample-users.tsv
$ ./manage.py import-addresses /app/data/test-addresses-01.tsv
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
$ heroku run ./manage.py import-users /app/data/sample-users.tsv
$ heroku run ./manage.py import-addresses "Title of your address set" /app/data/test-addresses-01.tsv
$ heroku open
```

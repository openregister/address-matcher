# address-matcher
UI for matching addresses


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
$ git push heroku master
$ heroku run python manage.py migrate
$ heroku run ./manage.py import-users /app/data/sample-users.tsv
$ heroku run ./manage.py import-addresses /app/data/test-addresses-01.tsv
$ heroku open


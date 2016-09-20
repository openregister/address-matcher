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
$ heroku open


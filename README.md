Resque Example Application - WIP
========================================

Some useful info goes here...

Install the Heroku toolbelt.  You'll need the heroku and foreman gems, and git.

Redis Installation (OS X)
----------------------------------------
    brew install redis

Setup the app
----------------------------------------
    bundle install

Set up .env for local development
----------------------------------------
    cp .env.example .env

Redis Startup
----------------------------------------
    redis-server

Start up the app locally
----------------------------------------
    foreman start

Set up a heroku app
----------------------------------------
    heroku create --stack cedar
    heroku addons:add redistogo:nano
    git push heroku
    heroku scale web=1 resque=1

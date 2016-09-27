# Botmetrics

Botmetrics is the easy, secure, open-source way for you to measure and
engage with your chat-bot users.

Botmetrics works natively with Messenger, Slack and Kik bots with
support for other messaging platforms coming soon.

[![CircleCI](https://circleci.com/gh/botmetrics/botmetrics/tree/master.svg?style=svg)](https://circleci.com/gh/botmetrics/botmetrics/tree/master)

## Analytics

With Botmetrics, you can get analytics for your bot with very little
code, and native SDKs available in

* [Node.JS](https://github.com/botmetrics/botmetrics.js)
* [Ruby](https://github.com/botmetrics/botmetrics-rb)
* [Go](https://github.com/botmetrics/go-botmetrics)

![Metrics](https://github.com/botmetrics/botmetrics/raw/master/app/assets/images/homepage/metrics.png)

## Insights

You can gain more insight into the users using your bot and perform
sophisticated queries to find out who they are.

![Analyze](https://github.com/botmetrics/botmetrics/raw/master/app/assets/images/homepage/analyze.png)

## Notifications

You can gain more insight into the users using your bot and send then
re-engagement notifications based on pre-selected criteria.

![Notifications](https://github.com/botmetrics/botmetrics/raw/master/app/assets/images/homepage/notifications.png)

## Quick Installation

You can deploy Botmetrics with one click to your Heroku account.

[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy?template=https://github.com/botmetrics/botmetrics)

One-click deployment to Amazon AWS, Google Cloud and Microsoft Azure is
coming soon!

## Installation on your own Linux server

1. Make sure you have Ruby 2.3.1 installed along with Rubygems (make
   sure you have `libxslt-dev`, `libxml2-dev`, `libpq-dev` installed on
your machine).
2. Setup the `.env` file by running `cp .env-example .env`
3. Replace `JSON_WEB_TOKEN_SECRET` with your own randomized secret.
4. Replace `DATABASE_URL` and `REDIS_URL` with URLs to your Postgres and Redis database URLs respectively. (Postgres and Redis can be on the same machine or different machines).
5. Run `./script/server` to start the server.

## Development

1. `cp .env-example .env`
2. Start Redis & Postgres (there's a `./script/redis` and
   `./script/dbstart` command that lets you do this easily)
3. Run `./script/dbreset` to reset the database (creates a new one,
   loads schema and runs `rake db:seed`)
4. Run `./script/server` to start the server
5. Visit [localhost:3000](http://localhost:3000)

## Contributing

* Join the [Slack](https://slack.getbotmetrics.com) channel to ask questions
* Open a [GitHub Issue](https://github.com/botmetrics/botmetrics/issues/new) for bugs/feature requests
* Create a [GitHub Pull Request](https://help.github.com/articles/using-pull-requests/) to submit patches


## Wiki

Extra information can be found in the [wiki](https://github.com/botmetrics/botmetrics/wiki).

## CircleCI

[![CircleCI](https://circleci.com/gh/botmetrics/botmetrics/tree/master.svg?style=svg)](https://circleci.com/gh/botmetrics/botmetrics/tree/master)

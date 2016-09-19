# Botmetrics

Botmetrics is the easy, secure, open-source way for you to measure and
engage with your chat-bot users.

Botmetrics works natively with Messenger, Slack and Kik bots with
support for other messaging platforms coming soon.

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

## Development

1. `cp .env-example .env`
2. Start Redis & Postgres (there's a `./script/redis` and
   `./script/dbstart` command that lets you do this easily)
3. Run `./script/dbreset` to reset the database (creates a new one,
   loads schema and runs `rake db:seed`)
4. Run `./script/server` to start the server
5. Visit [localhost:9000](http://localhost:9000)


## CircleCI

[![Circle CI](https://circleci.com/gh/botmetrics/botmetrics.svg?style=svg&circle-token=363a196aec860f76e2ab58360a13f0621d043b9e)](https://circleci.com/gh/botmetrics/botmetrics)

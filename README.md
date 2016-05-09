## Setup

1. `cp .env-example .env`
2. Start Redis & Postgres (there's a `./script/redis` and
   `./script/dbstart` command that lets you do this easily)
3. Run `./script/dbreset` to reset the database (creates a new one,
   loads schema and runs `rake db:seed`)
4. Put `relax` in your $PATH: You can download it from
   [here](https://dl.equinox.io/zerobotlabs/relax/beta).
5. Run `./script/server` to start the server
6. Visit [localhost:9000](http://localhost:9000)

## CircleCI

[![Circle CI](https://circleci.com/gh/zerobotlabs/bot_metrics.svg?style=svg&circle-token=363a196aec860f76e2ab58360a13f0621d043b9e)](https://circleci.com/gh/zerobotlabs/bot_metrics)

## Setting up Production Database

1. Add a `production` remote: `git remote add production <heroku-url>`
2. Install [Parity gem](https://github.com/thoughtbot/parity): `gem install parity`
3. Restore from production: `development restore production`
4. Save the password for the user `admins@asknestor.me` to "password123"
   or something similar using Rails console and login to the website.

## Some Things to Look Out For

1. Please trim trailing whitespace
2. Every time you run `rake db:migrate`, the Postgres driver will add
   trailing spaces to `db/structure.sql`. What I do is hit Save on
`db/structure.sql` in my editor which trims all the trailing whitespace.

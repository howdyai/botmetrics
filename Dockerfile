FROM ruby:2.3.1

MAINTAINER Botmetrics <hello@getbotmetrics.com>

RUN apt-get update -qq && apt-get install -y build-essential

# for postgres
RUN apt-get install -y libpq-dev

# for nokogiri
RUN apt-get install -y libxml2-dev libxslt1-dev

# for a JS runtime
RUN apt-get install -y nodejs

# for psql
RUN apt-get install -y postgresql-client-9.4

ENV APP_HOME /botmetrics

RUN mkdir $APP_HOME

WORKDIR $APP_HOME

ADD Gemfile* $APP_HOME/

RUN bundle install --binstubs

ADD . $APP_HOME

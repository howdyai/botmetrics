FROM convox/rails
MAINTAINER Botmetrics <hello@getbotmetrics.com>

RUN apt-get install -yq wget postgresql-client-9.5

# copy only the files needed for bundle install
COPY Gemfile      /app/Gemfile
COPY Gemfile.lock /app/Gemfile.lock
RUN RAILS_ENV=production bundle install

# copy only the files needed for assets:precompile
COPY Rakefile                       /app/Rakefile
COPY config/database.yml.sample     /app/config/database.yml
COPY config                         /app/config
COPY public                         /app/public
COPY app/assets                     /app/app/assets
COPY vendor                         /app/vendor
COPY app/lib/json_web_token.rb      /app/app/lib/json_web_token.rb
COPY app/lib/jwt_strategy.rb        /app/app/lib/jwt_strategy.rb
COPY app/services/relax_service.rb  /app/app/services/relax_service.rb
COPY app/models/user.rb             /app/app/models/user.rb

RUN RAILS_ENV=production SECRET_KEY_BASE=secrud rake assets:precompile

# copy the rest of the app
COPY . /app

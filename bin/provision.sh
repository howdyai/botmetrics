sudo update-locale LC_ALL="en_US.utf8"

# Add PG sources
echo "deb http://apt.postgresql.org/pub/repos/apt/ precise-pgdg main" | sudo tee -a /etc/apt/sources.list.d/pgdb.list
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -

# Add Ruby sources
sudo apt-add-repository ppa:brightbox/ruby-ng

sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y git \
                        redis-server \
                        imagemagick \
                        nodejs \
                        libpq-dev \
                        postgresql-9.4 \
                        openjdk-7-jre-headless \
                        ruby2.3 \
                        ruby2.3-dev

sudo su postgres -c "createuser -d -R -S $USER"

sudo gem install bundler

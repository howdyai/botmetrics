web: bundle exec passenger start -p $PORT --max-pool-size 3 --min-instances 1
worker: bundle exec sidekiq -q default -q mailers -v
relax_worker: bundle exec rake relax:listen_for_events
clock: bundle exec clockwork clockwork.rb
relax_server: bin/relax

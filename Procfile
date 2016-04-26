web: bundle exec passenger start -p $PORT --max-pool-size 3 --min-instances 1
worker: bundle exec sidekiq -q default -v
relax_worker: bundle exec rake relax:listen_for_events

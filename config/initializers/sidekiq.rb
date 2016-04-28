redis_url = ENV['REDISCLOUD_URL'] || ENV['REDIS_URL']

Sidekiq.configure_server do |config|
  config.redis = { url: redis_url, namespace: 'sidekiq' }

  if(database_url = ENV['DATABASE_URL']).present?
    ENV['DATABASE_URL'] = "#{database_url}?pool=20"
    ActiveRecord::Base.establish_connection(ENV['DATABASE_URL'])
  end
end

Sidekiq.configure_client do |config|
  config.redis = { url: redis_url, namespace: 'sidekiq', size: 2 }
end

require 'sidekiq'

Sidekiq.configure_client do |config|
  config.redis = {db: 1}
end

require 'sidekiq/web'

Sidekiq::Web.use Rack::Auth::Basic do |username, password|
  [username, password] == ["admin", "t3vm3oMGZbec8awyxXFp"]
 end

run Sidekiq::Web
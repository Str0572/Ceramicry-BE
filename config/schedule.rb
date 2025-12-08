set :output, "log/cron.log"
set :environment, ENV.fetch("RAILS_ENV", "development")

every 30.minutes do
  runner "ShiprocketSyncOpenShipmentsJob.perform_later"
end

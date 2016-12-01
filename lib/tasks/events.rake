namespace :botmetrics do
  desc "Rollup Events"
  task :rollup_events => :environment do
    Event.rollup!
  end
end

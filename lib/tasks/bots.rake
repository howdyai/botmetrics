namespace :botmetrics do
  desc "Setup dashboard names"
  task :fix_dashboard_names => :environment do
    Dashboard.where("dashboard_type <> 'custom'").each do |dashboard|
      dashboard.update_attribute(:name, Dashboard.name_for(dashboard.dashboard_type))
      puts "saved Dashboard #{dashboard.id} with #{dashboard.name}"
    end
  end

  desc "setup facebook dashboards"
  task :setup_facebook_dashboards => :environment do
    Bot.where(provider: 'facebook').find_each do |bot|
      owner = bot.owners.first
      if owner.blank?
        raise ArgumentError, "omg owner blank for bot: #{bot.inspect}"
      end

      bot.create_default_dashboards_with!(owner)
    end
  end

  desc "setup kik dashboards"
  task :setup_kik_dashboards => :environment do
    Bot.where(provider: 'kik').find_each do |bot|
      owner = bot.owners.first
      if owner.blank?
        raise ArgumentError, "omg owner blank for bot: #{bot.inspect}"
      end

      bot.create_default_dashboards_with!(owner)
    end
  end
end


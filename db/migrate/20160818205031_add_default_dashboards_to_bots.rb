class AddDefaultDashboardsToBots < ActiveRecord::Migration
  def up
    Bot.find_each do |bot|
      owner = bot.owners.first
      if owner.blank?
        raise ArgumentError, "omg owner blank for bot: #{bot.inspect}"
      end

      bot.create_default_dashboards_with!(owner)
    end
  end

  def down
    Bot.find_each do |bot|
      bot.dashboards.destroy_all
    end
  end
end

class NestorBot < ActiveRecord::Base
  establish_connection ENV['NESTOR_DATABASE_URL']
  self.table_name = 'bots'
  belongs_to :nestor_team, class_name: 'NestorTeam', foreign_key: 'team_id'
end

class NestorTeam < ActiveRecord::Base
  establish_connection ENV['NESTOR_DATABASE_URL']
  self.table_name = 'teams'
end

namespace :botmetrics do
  desc "enable bots"
  task :set_right_dates => :environment do
    real_total_count = 0
    total_count = 0
    disabled_count = 0
    total_disabled_count = 0
    not_found = 0

    NestorBot.find_each do |bot|
      id = bot.bot_user_id
      created_at = bot.created_at
      updated_at = bot.updated_at

      bi = BotInstance.find_by(token: bot.token)
      real_total_count += 1
      next if bi.blank?

      bi.update_attribute(:created_at, created_at)
      bi.users.update_all(created_at: created_at)

      puts "setting created_at for bot for bi: #{bi.uid} #{bi.created_at}"
      total_count += 1

      if bi.state == 'disabled'
        total_disabled_count += 1
        disabled_event = bi.events.find_by(event_type: 'bot_disabled')
        if disabled_event.present?
          disabled_event.update_attribute(:created_at, updated_at)
          puts "setting created_at for bot_disabled for bi: #{bi.uid} #{disabled_event.created_at}"
          disabled_count += 1
        end

        if bi.instance_attributes[:team_id].blank?
          nestor_team = bot.nestor_team
          if bi.uid.blank?
            bi.uid = bot.bot_user_id
            puts "saved bi.uid with #{bi.uid}"
          end

          bi.instance_attributes[:team_id] = nestor_team.uid
          bi.instance_attributes[:team_url] = nestor_team.url
          bi.instance_attributes[:team_name] = nestor_team.name
          bi.save
          puts "saved instance_attributes: #{bi.reload.instance_attributes}"
        end
      end
    end

    puts "real_total_count: #{real_total_count} total: #{total_count}, disabled: #{disabled_count}, total disabled count: #{total_disabled_count}, not_found = #{not_found}"
  end
end

class MigrateJsonColumnsToJsonb < ActiveRecord::Migration
  def up
    execute %(
      ALTER TABLE "users"
      ALTER COLUMN "mixpanel_properties" TYPE jsonb USING mixpanel_properties::jsonb,
      ALTER COLUMN "mixpanel_properties" SET DEFAULT '{}'::JSONB,
      ALTER COLUMN "mixpanel_properties" SET NOT NULL,
      ALTER COLUMN "mixpanel_properties" DROP DEFAULT
    )
    execute %(
      ALTER TABLE "bot_users"
      ALTER COLUMN "user_attributes" TYPE jsonb USING user_attributes::jsonb,
      ALTER COLUMN "user_attributes" SET DEFAULT '{}'::JSONB,
      ALTER COLUMN "user_attributes" SET NOT NULL,
      ALTER COLUMN "user_attributes" DROP DEFAULT
    )
  end

  def down
    execute %(
      ALTER TABLE "users"
      ALTER COLUMN "mixpanel_properties" TYPE json USING mixpanel_properties::json,
      ALTER COLUMN "mixpanel_properties" SET DEFAULT '{}'::JSON,
      ALTER COLUMN "mixpanel_properties" SET NOT NULL,
      ALTER COLUMN "mixpanel_properties" DROP DEFAULT
    )
    execute %(
      ALTER TABLE "bot_users"
      ALTER COLUMN "user_attributes" TYPE json USING user_attributes::json,
      ALTER COLUMN "user_attributes" SET DEFAULT '{}'::JSON,
      ALTER COLUMN "user_attributes" SET NOT NULL,
      ALTER COLUMN "user_attributes" DROP DEFAULT
    )
  end
end

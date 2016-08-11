class FixInstanceAttributesNameOnBotInstance < ActiveRecord::Migration
  def up
    execute "ALTER TABLE bot_instances DROP CONSTRAINT validate_attributes_name"
    execute "ALTER TABLE bot_instances ADD CONSTRAINT validate_attributes_name
                   CHECK (
                          (
                            (instance_attributes->>'name') IS NOT NULL
                            AND length(instance_attributes->>'name') > 0
                            AND provider = 'facebook'
                            AND state = 'enabled'
                          )
                          OR
                          (
                            state = 'pending'
                            AND instance_attributes IS NOT NULL
                          )
                          OR
                          (
                            state = 'disabled'
                            AND instance_attributes IS NOT NULL
                          )
                          OR provider <> 'facebook'
                         )"
  end

  def down
    execute "ALTER TABLE bot_instances DROP CONSTRAINT validate_attributes_name"
    execute "ALTER TABLE bot_instances ADD CONSTRAINT validate_attributes_name
                   CHECK (
                          (
                            (instance_attributes->>'name') IS NOT NULL
                            AND length(instance_attributes->>'name') > 0
                            AND provider = 'facebook'
                            AND state <> 'pending'
                          )
                          OR
                          (
                            state = 'pending'
                            AND instance_attributes IS NOT NULL
                          )
                          OR provider <> 'facebook'
                         )"
  end
end

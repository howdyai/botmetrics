class ModifyMessageConstraintsForFacebookAndKik < ActiveRecord::Migration
  def up
    execute "ALTER TABLE messages DROP CONSTRAINT validate_attributes_team_id"
    execute "ALTER TABLE messages DROP CONSTRAINT validate_attributes_channel_user"

    execute(
    "ALTER TABLE messages ADD CONSTRAINT validate_attributes_team_id
      CHECK (
        (
          provider = 'slack'
          AND (message_attributes->>'team_id') IS NOT NULL
          AND length(message_attributes->>'team_id') > 0
        ) OR
        provider = 'facebook'
        OR
        provider = 'kik'
      )"
    )
    execute(
    "ALTER TABLE messages ADD CONSTRAINT validate_attributes_channel_user
      CHECK (
        (
          provider = 'slack'
          AND (message_attributes->>'channel') IS NOT NULL
          AND length(message_attributes->>'channel') > 0
          AND (message_attributes->>'user') IS NULL
        )
        OR
        (
          (provider = 'slack' OR provider = 'facebook' OR provider = 'kik')
          AND (message_attributes->>'user') IS NOT NULL
          AND length(message_attributes->>'user') > 0
          AND (message_attributes->>'channel') IS NULL
        )
      )"
    )
  end

  def down
    execute "ALTER TABLE messages DROP CONSTRAINT validate_attributes_team_id"
    execute "ALTER TABLE messages DROP CONSTRAINT validate_attributes_channel_user"

    execute(
    "ALTER TABLE messages ADD CONSTRAINT validate_attributes_team_id
      CHECK (
        provider = 'slack'
        AND (message_attributes->>'team_id') IS NOT NULL
        AND length(message_attributes->>'team_id') > 0
      )"
    )
    execute(
    "ALTER TABLE messages ADD CONSTRAINT validate_attributes_channel_user
      CHECK (
        (
          provider = 'slack'
          AND (message_attributes->>'channel') IS NOT NULL
          AND length(message_attributes->>'channel') > 0
          AND (message_attributes->>'user') IS NULL
        )
        OR
        (
          provider = 'slack'
          AND (message_attributes->>'user') IS NOT NULL
          AND length(message_attributes->>'user') > 0
          AND (message_attributes->>'channel') IS NULL
        )
      )"
    )

  end
end

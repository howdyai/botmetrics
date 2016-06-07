class AlterValidateMethodConstraintForQueries < ActiveRecord::Migration
  def up
    execute("ALTER TABLE queries DROP CONSTRAINT validate_method")
    execute("ALTER TABLE queries ADD CONSTRAINT validate_method
      CHECK (
        (
          provider = 'slack'
          AND (
            field = 'nickname'
            OR field = 'email'
            OR field = 'full_name'
          )
          AND (
            method = 'equals_to'
            OR method = 'contains'
          )
        )
        OR
        (
          provider = 'slack'
          AND (
            field = 'interaction_count'
          )
          AND (
            method = 'equals_to'
            OR method = 'greater_than'
            OR method = 'lesser_than'
            OR method = 'between'
          )
        )
        OR
        (
          provider = 'slack'
          AND (
            field = 'interacted_at'
            OR field = 'user_created_at'
          )
          AND (
            method = 'between'
          )
        )
      )"
    )
  end

  def down
    execute("ALTER TABLE queries DROP CONSTRAINT validate_method")
    execute(
      "ALTER TABLE queries ADD CONSTRAINT validate_method
      CHECK (
        (
          provider = 'slack'
          AND (
            field = 'nickname'
            OR field = 'email'
            OR field = 'full_name'
          )
          AND (
            method = 'equals_to'
            OR method = 'contains'
          )
        )
        OR
        (
          provider = 'slack'
          AND (
            field = 'interaction_count'
          )
          AND (
            method = 'equals_to'
            OR method = 'between'
          )
        )
        OR
        (
          provider = 'slack'
          AND (
            field = 'interacted_at'
            OR field = 'user_created_at'
          )
          AND (
            method = 'between'
          )
        )
      )"
    )
  end
end

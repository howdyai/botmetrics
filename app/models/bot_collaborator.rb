class BotCollaborator < ActiveRecord::Base
  validates_presence_of :bot_id, :user_id, :collaborator_type

  belongs_to :user
  belongs_to :bot
  validates_uniqueness_of :user_id, scope: :bot_id
end

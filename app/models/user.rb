class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  has_many :bot_collaborators
  has_many :bots, through: :bot_collaborators

  validates_uniqueness_of :api_key, if: Proc.new { |u| u.api_key.present? }

  before_create :init_email_preferences

  store_accessor :email_preferences, :created_bot_instance

  def to_param
    'me'
  end

  def set_api_key!
    self.api_key = JsonWebToken.encode({'user_id' => self.id}, 10.years.from_now)
  end

  private

    def init_email_preferences
      self.email_preferences = { created_bot_instance: '1' }
    end
end

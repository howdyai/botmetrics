class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  has_many :bot_collaborators
  has_many :bots, through: :bot_collaborators

  validates_uniqueness_of :api_key, if: Proc.new { |u| u.api_key.present? }

  scope :subscribed_to, ->(email_preference) do
    where('email_preferences @> ?', { email_preference => '1' }.to_json)
  end

  before_create :init_email_preferences

  store_accessor :email_preferences, :created_bot_instance, :disabled_bot_instance

  def to_param
    'me'
  end

  def set_api_key!
    self.api_key = JsonWebToken.encode({'user_id' => self.id}, 10.years.from_now)
  end

  private

    def init_email_preferences
      self.email_preferences['created_bot_instance']  ||= '1'
      self.email_preferences['disabled_bot_instance'] ||= '1'
    end
end

class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  has_many :team_memberships
  has_many :teams, through: :team_memberships

  validates_uniqueness_of :api_key, if: Proc.new { |u| u.api_key.present? }

  def to_param
    'me'
  end

  def set_api_key!
    self.api_key = JsonWebToken.encode({'user_id' => self.id}, 10.years.from_now)
  end
end

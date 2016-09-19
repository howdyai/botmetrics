class Setting < ActiveRecord::Base
  HOSTNAME = 'hostname'.freeze

  validates_presence_of :key, :value
  validates_uniqueness_of :key
  validates_presence_of :key, in: [HOSTNAME]

  attr_accessor :hostname
  validates_url :hostname, url: true

  def self.hostname
    Setting.find_by(key: HOSTNAME).try(:value)
  end

  def hostname=(hostname)
    @hostname = hostname
    self.key = HOSTNAME
    self.value = hostname
  end

  def to_param
    'me'
  end
end

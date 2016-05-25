class FeatureToggle
  def self.active?(feature_name, users, &block)
    block.call if can_execute?(feature_name, Array(users))
  end

  def self.can_execute?(feature_name, users)
    return true  if !Rails.env.production?
    return false if users.blank?

    feature_env = ENV["FEATURE_#{feature_name.upcase}"]

    if feature_env == 'ENABLE' && users.map(&:email).include?('admins@asknestor.me')
      true
    else
      false
    end
  end
end

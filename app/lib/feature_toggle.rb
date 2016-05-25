class FeatureToggle
  def self.active?(feature_name, user, &block)
    block.call if can_execute?(feature_name, user)
  end

  def self.can_execute?(feature_name, user)
    return true  if !Rails.env.production?
    return false if user.blank?

    feature_env = ENV["FEATURE_#{feature_name.upcase}"]

    if feature_env == 'ENABLE' && user.email == 'admins@asknestor.me'
      true
    else
      false
    end
  end
end

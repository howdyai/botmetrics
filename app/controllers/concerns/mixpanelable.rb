module Mixpanelable
  extend ActiveSupport::Concern

  included do
    before_filter :set_mixpanel_cookie_information
  end

  def set_mixpanel_cookie_information
    if (mp_cookies = cookies['mp_getbotmetrics'])
      @mixpanel_attributes = JSON.parse(mp_cookies)
    else
      @mixpanel_attributes = {}
    end
  end
end


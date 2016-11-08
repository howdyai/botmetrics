require 'rails_helper'

RSpec.describe ShortLink, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to :bot_user }
    it { is_expected.to belong_to :bot_instance }
  end

  it "has a link"
  it "has a slug"

end

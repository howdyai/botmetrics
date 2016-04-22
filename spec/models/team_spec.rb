require 'spec_helper'

describe Team do
  describe 'validations' do
    subject { create :team }

    it { should validate_presence_of :name }
    it { should validate_uniqueness_of :uid }
  end
end

RSpec.describe Queries::Finder do
  describe '#for_type' do
    it 'returns Queries::Slack.new when slack' do
      instance = Queries::Finder.for_type 'slack'
      expect(instance).to be_a Queries::Slack
    end

    it 'returns Queries::Null.new when nil' do
      instance = Queries::Finder.for_type nil
      expect(instance).to be_a Queries::Null
    end
  end
end

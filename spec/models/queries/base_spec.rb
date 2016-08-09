RSpec.describe Queries::Base do
  subject { Queries::Base.new }

  describe '#is_number_query?' do
    it 'query is a number' do
      expect(subject.is_number_query?('interaction_count')).to be true
    end

    it 'query isn`t a number' do
      expect(subject.is_number_query?('interacted_at')).to be false
    end

    it 'query doesn`t exist' do
      expect(subject.is_number_query?('fake')).to be false
    end
  end

  describe '#is_datetime_query?' do
    it 'query is a number' do
      expect(subject.is_datetime_query?('interacted_at')).to be true
    end

    it 'query isn`t a number' do
      expect(subject.is_datetime_query?('interaction_count')).to be false
    end

    it 'query doesn`t exist' do
      expect(subject.is_datetime_query?('fake')).to be false
    end
  end

  describe '#string_methods' do
    let(:values) { Hash['equals_to', 'Equals To', 'contains', 'Contains'] }

    it 'should return proper values' do
      expect(subject.string_methods).to eql values
    end
  end

  describe '#number_methods' do
    let(:values) { Hash['equals_to', 'Equals To', 'lesser_than', 'Lesser Than', 'greater_than', 'Greater Than', 'between', 'Between'] }

    it 'should return proper values' do
      expect(subject.number_methods).to eql values
    end
  end

  describe '#datetime_methods' do
    let(:values) { Hash['lesser_than', 'Less Than', 'greater_than', 'More Than', 'between', 'Between'] }

    it 'should return proper values' do
      expect(subject.datetime_methods).to eql values
    end
  end
end

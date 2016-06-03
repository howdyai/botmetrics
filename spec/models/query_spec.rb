RSpec.describe Query do
  context 'constants' do
    context 'FIELDS' do
      it 'keys include' do
        expect(Query::FIELDS.keys).to match_array %w(
          nickname email full_name interaction_count interacted_at user_created_at)
      end
    end
  end

  context 'associations' do
    it { is_expected.to belong_to :query_set }
  end

  context 'validations' do
    it { is_expected.to validate_presence_of :field }
    it { is_expected.to validate_inclusion_of(:field).in_array(Query::FIELDS.keys) }
    it { is_expected.to validate_presence_of :method }
    it { is_expected.to validate_inclusion_of(:method).in_array(Query::STRING_METHODS.keys | Query::NUMBER_METHODS.keys) }

    context 'value' do
      context 'method is not "between"' do
        subject { Query.new(method: ['equals_to', 'contains'].sample) }
        it { is_expected.to validate_presence_of :value }
      end

      context 'method is "between"' do
        subject { Query.new(method: 'between') }
        it { is_expected.to_not validate_presence_of :value }
      end
    end

    context 'min_value' do
      context 'method is not "between"' do
        subject { Query.new(method: ['equals_to', 'contains'].sample) }
        it { is_expected.to_not validate_presence_of :min_value }
      end

      context 'method is "between"' do
        subject { Query.new(method: 'between') }
        it { is_expected.to validate_presence_of :min_value }
      end
    end

    context 'max_value' do
      context 'method is not "between"' do
        subject { Query.new(method: ['equals_to', 'contains'].sample) }
        it { is_expected.to_not validate_presence_of :max_value }
      end

      context 'method is "between"' do
        subject { Query.new(method: 'between') }
        it { is_expected.to validate_presence_of :max_value }
      end
    end
  end
end

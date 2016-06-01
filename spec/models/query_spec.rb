RSpec.describe Query do
  context 'associations' do
    it { is_expected.to belong_to :query_set }
  end

  context 'validations' do
    it { is_expected.to validate_presence_of :field }
    it { is_expected.to validate_inclusion_of(:field).in_array(Query::FIELDS.keys) }
    it { is_expected.to validate_presence_of :method }
    it { is_expected.to validate_inclusion_of(:method).in_array(Query::METHODS.keys) }
    it { is_expected.to validate_presence_of :value }
  end

  describe '#sql_params' do
    context 'method equals to' do
      let(:query) { Query.new(field: 'nickname', method: 'equals_to', value: 'john') }

      it 'transforms for query params' do
        expect(query.sql_params).to eq [
                                         "bot_users.user_attributes->>:field = :value",
                                         field: 'nickname',
                                         value: 'john'
                                       ]
      end
    end

    context 'method equals to' do
      let(:query) { Query.new(field: 'nickname', method: 'contains', value: 'john') }

      it 'transforms for query params' do
        expect(query.sql_params).to eq [
                                         "bot_users.user_attributes->>:field ILIKE :value",
                                         field: 'nickname',
                                         value: "%john%"
                                       ]
      end
    end
  end
end

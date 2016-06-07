RSpec.describe QuerySet do
  context 'associations' do
    it { is_expected.to belong_to :bot }

    it { is_expected.to have_many :queries }
    it { is_expected.to accept_nested_attributes_for :queries }
  end

  context 'validations' do
    it { is_expected.to validate_presence_of :bot_id }
    it { is_expected.to validate_presence_of :instances_scope }
    it { is_expected.to validate_inclusion_of(:instances_scope).in_array(%w(legit enabled)) }
    it { is_expected.to validate_presence_of :time_zone }
  end

  describe '#to_form_params' do
    let(:query_set) { build(:query_set, :with_slack_queries, bot_id: 1) }

    it 'works' do
      expect(query_set.to_form_params).
        to match({ query_set: hash_including(:bot_id, :instances_scope, :time_zone, :queries_attributes) })

      expect(query_set.to_form_params[:query_set][:queries_attributes].keys[0]).to be_kind_of String

      expect(query_set.to_form_params[:query_set][:queries_attributes].values[0]).
        to match(hash_including(:provider, :field, :method, :value))
    end
  end
end

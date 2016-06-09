RSpec.describe QuerySetBuilder do
  describe '#query_set' do
    let(:builder) do
      QuerySetBuilder.new(
        bot:             bot,
        instances_scope: instances_scope,
        time_zone:       time_zone,
        params:          params,
        default:         default,
        session:         my_session
      )
    end

    context 'basic options' do
      let(:bot)             { build(:bot, provider: 'slack') }
      let(:instances_scope) { 'enabled' }
      let(:time_zone)       { 'Pacific/Asia' }
      let(:default)         { Hash.new }
      let(:params)          { Hash.new }
      let(:my_session)      { Hash.new }

      it 'returns a QuerySet object' do
        query_set = builder.query_set

        expect(query_set.bot).to             eq bot
        expect(query_set.instances_scope).to eq instances_scope
        expect(query_set.time_zone).to       eq time_zone

        expect(query_set.queries.size).to eq 1

        query = query_set.queries.first
        expect(query.provider).to eq 'slack'
        expect(query.field).to    be_nil
        expect(query.method).to   be_nil
        expect(query.value).to    be_nil
      end
    end

    context 'default query' do
      let(:bot)             { build(:bot, provider: 'slack') }
      let(:instances_scope) { 'enabled' }
      let(:time_zone)       { 'Pacific/Asia' }
      let(:params)          { Hash.new }
      let(:my_session)      { Hash.new }

      let(:default)         { { provider: 'slack', field: 'interaction_count', method: 'lesser_than', value: '10' } }

      it 'returns a QuerySet object' do
        query_set = builder.query_set

        expect(query_set.bot).to             eq bot
        expect(query_set.instances_scope).to eq instances_scope
        expect(query_set.time_zone).to       eq time_zone

        expect(query_set.queries.size).to eq 1

        query = query_set.queries.first
        expect(query.provider).to eq 'slack'
        expect(query.field).to    eq 'interaction_count'
        expect(query.method).to   eq 'lesser_than'
        expect(query.value).to    eq '10'
      end
    end

    context 'params and session are present' do
      let(:bot)             { build(:bot, provider: 'slack') }
      let(:instances_scope) { 'enabled' }
      let(:time_zone)       { 'Pacific/Asia' }
      let(:default)         { nil }

      let(:params) do
        { query_set: {
          queries_attributes: { '0' => { provider: 'slack', field: 'email', method: 'contains', value: 'win' } }
        } }
      end

      let(:my_session) do
        { query_set: {
          queries_attributes: { '0' => { provider: 'slack', field: 'nickname', method: 'equals_to', value: 'john' } }
        } }
      end

      it 'returns a QuerySet object with params taking precedence' do
        query_set = builder.query_set

        expect(query_set.bot).to             eq bot
        expect(query_set.instances_scope).to eq instances_scope
        expect(query_set.time_zone).to       eq time_zone

        expect(query_set.queries.size).to eq 1

        query = query_set.queries.first
        expect(query.provider).to eq 'slack'
        expect(query.field).to    eq 'email'
        expect(query.method).to   eq 'contains'
        expect(query.value).to    eq 'win'
      end
    end

    context 'only params is present' do
      let(:bot)             { build(:bot, provider: 'slack') }
      let(:instances_scope) { 'enabled' }
      let(:time_zone)       { 'Pacific/Asia' }
      let(:default)         { nil }
      let(:my_session)      { nil }

      let(:params) do
        { query_set: {
          queries_attributes: { '0' => { provider: 'slack', field: 'nickname', method: 'equals_to', value: 'john' } }
        } }
      end

      it 'returns a QuerySet object' do
        query_set = builder.query_set

        expect(query_set.bot).to             eq bot
        expect(query_set.instances_scope).to eq instances_scope
        expect(query_set.time_zone).to       eq time_zone

        expect(query_set.queries.size).to eq 1

        query = query_set.queries.first
        expect(query.provider).to eq 'slack'
        expect(query.field).to    eq 'nickname'
        expect(query.method).to   eq 'equals_to'
        expect(query.value).to    eq 'john'
      end
    end

    context 'only session is present' do
      let(:bot)             { build(:bot, provider: 'slack') }
      let(:instances_scope) { 'enabled' }
      let(:time_zone)       { 'Pacific/Asia' }
      let(:default)         { nil }
      let(:params)          { nil }

      let(:my_session) do
        { query_set: {
          queries_attributes: { '0' => { provider: 'slack', field: 'nickname', method: 'equals_to', value: 'john' } }
        } }
      end

      it 'returns a QuerySet object' do
        query_set = builder.query_set

        expect(query_set.bot).to             eq bot
        expect(query_set.instances_scope).to eq instances_scope
        expect(query_set.time_zone).to       eq time_zone

        expect(query_set.queries.size).to eq 1

        query = query_set.queries.first
        expect(query.provider).to eq 'slack'
        expect(query.field).to    eq 'nickname'
        expect(query.method).to   eq 'equals_to'
        expect(query.value).to    eq 'john'
      end
    end
  end
end

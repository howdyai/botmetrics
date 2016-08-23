RSpec.describe SetMixpanelPropertyJob do
  describe '#perform' do
    let!(:user)     { create :user, email: 'i@mclov.in', full_name: 'Mc Lovin' }
    let!(:mixpanel) { instance_double('Mixpanel::Tracker') }
    let!(:people)   { instance_double('Mixpanel::People')  }

    before do
      allow(Mixpanel::Tracker).to receive(:new).and_return(mixpanel)
      allow(mixpanel).to receive(:people).and_return(people)

      allow(people).to receive(:set)
    end

    context 'when user exists' do
      it "should set the appropriate Mixpanel attributes" do
        SetMixpanelPropertyJob.new.perform(user.id, :current_blog, 'Wordpress')
        expect(people).to have_received(:set).with(user.id, {current_blog: 'Wordpress'}, nil, {'$ignore_time' => false})
      end

      it "should identify the user and set all attributes passed as an hash" do
        SetMixpanelPropertyJob.new.perform(user.id, { current_blog: 'Wordpress', bitly: true })
        expect(people).to have_received(:set).with(user.id, {current_blog: 'Wordpress', bitly: true}, nil, {'$ignore_time' => false})
      end

      it "should pass along the $ignore_time attribute correctly" do
        SetMixpanelPropertyJob.new.perform(user.id, {current_blog: 'Wordpress', bitly: true, '$ignore_time' => true})
        expect(people).to have_received(:set).with(user.id, {current_blog: 'Wordpress', bitly: true}, nil, {'$ignore_time' => true})
      end
    end
  end
end

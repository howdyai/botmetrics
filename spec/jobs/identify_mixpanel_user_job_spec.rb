require 'spec_helper'

describe IdentifyMixpanelUserJob do
  describe '#perform' do
    let!(:user)     { create :user, email: 'i@mclov.in', first_name: 'Mc', last_name: 'Lovin', full_name: 'Mc Lovin' }
    let!(:mixpanel) { instance_double('Mixpanel::Tracker') }
    let!(:people)   { instance_double('Mixpanel::People')  }

    before do
      allow(Mixpanel::Tracker).to receive(:new).and_return(mixpanel)
      allow(mixpanel).to receive(:people).and_return(people)

      allow(mixpanel).to receive(:alias)
      allow(people).to receive(:set)
    end

    context "user has not done anything" do
      it "should identify the user and set some attributes" do
        IdentifyMixpanelUserJob.new.perform(user.id)
        expect(people).to have_received(:set).with(user.id,
                                                     {
                                                       '$email' => user.email,
                                                       created: user.created_at.as_json,
                                                       ip: user.current_sign_in_ip,
                                                       '$full_name' => user.full_name,
                                                       '$first_name' => user.first_name,
                                                       '$last_name' => user.last_name
                                                     })
      end
    end

    context "mixpanel attributes have been passed, including an old_distinct_id" do
      it "should identify the user and alias him as well" do
        IdentifyMixpanelUserJob.new.perform(user.id, distinct_id: "old_distinct_id", :$initial_referrer => "$direct")
        expect(mixpanel).to have_received(:alias).with(user.id, 'old_distinct_id')
        expect(people).to have_received(:set).with(user.id,
                                                     {
                                                       '$email' => user.email,
                                                       created: user.created_at.as_json,
                                                       ip: user.current_sign_in_ip,
                                                       '$full_name' => user.full_name,
                                                       '$first_name' => user.first_name,
                                                       '$last_name' => user.last_name,
                                                       :$initial_referrer => "$direct"
                                                     })
      end
    end

    context "user has mixpanel properties associated with (for e.g. utm_source, etc)" do
      before do
        user.mixpanel_properties = {'utm_source' => '@gruber', 'utm_medium' => 'twitter'}
        user.save
      end

      it "should identify the user and set some mixpanel properties" do
        IdentifyMixpanelUserJob.new.perform(user.id)
        expect(people).to have_received(:set).with(user.id,
                                                     {
                                                       '$email' => user.email,
                                                       created: user.created_at.as_json,
                                                       ip: user.current_sign_in_ip,
                                                       '$full_name' => user.full_name,
                                                       '$first_name' => user.first_name,
                                                       '$last_name' => user.last_name,
                                                       'utm_source' => '@gruber',
                                                       'utm_medium' => 'twitter'
                                                     })
      end
    end
  end
end

RSpec.describe TrackMixpanelEventJob do
  describe '#perform' do
    let!(:user)     { create :user, email: 'i@mclov.in', first_name: 'Mc', last_name: 'Lovin', full_name: 'Mc Lovin' }
    let!(:mixpanel) { instance_double('Mixpanel::Tracker') }

    before do
      allow(Mixpanel::Tracker).to receive(:new).and_return(mixpanel)
      allow(mixpanel).to receive(:track)
    end

    context 'with an active user account' do
      it "should track the event with the user's ID set as a default property" do
        TrackMixpanelEventJob.new.perform('Site Created', user.id)
        expect(mixpanel).to have_received(:track).with(user.id, 'Site Created', '$email' => user.email,
                                                                                '$full_name' => user.full_name,
                                                                                '$first_name' => user.first_name,
                                                                                '$last_name' => user.last_name
                                                                )
      end

      it "should track the event with the user's ID set as a default property along with other properties passed" do
        TrackMixpanelEventJob.new.perform('Site Created', user.id, { plan_id: 1 })
        expect(mixpanel).to have_received(:track).with(user.id, 'Site Created', '$email' => user.email,
                                                                                '$full_name' => user.full_name,
                                                                                '$first_name' => user.first_name,
                                                                                '$last_name' => user.last_name,
                                                                                plan_id: 1)
      end

      context 'when user has mixpanel properties set' do
        before do
          user.mixpanel_properties = {'initial_referrer' => '$direct', 'utm_source' => 'twitter'}
          user.save
        end

        it "should track the event with the user's ID set as a default property along with mixpanel properties stored as part of the user's profile" do
          TrackMixpanelEventJob.new.perform('Site Created', user.id)
          expect(mixpanel).to have_received(:track).with(user.id, 'Site Created', '$email' => user.email,
                                                                                  '$full_name' => user.full_name,
                                                                                  '$first_name' => user.first_name,
                                                                                  '$last_name' => user.last_name,
                                                                                 'initial_referrer' => '$direct',
                                                                                 'utm_source' => 'twitter')
        end
      end
    end
  end
end

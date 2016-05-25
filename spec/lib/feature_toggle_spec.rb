RSpec.describe FeatureToggle do
  describe '#active?' do
    let(:user) { nil }

    def runner
      FeatureToggle.active?(:feature, user) do
        'works'
      end
    end

    context 'not production' do
      before { allow(Rails.env).to receive(:production?) { false } }

      it { expect(runner).to eq 'works' }
    end

    context 'production' do
      before { allow(Rails.env).to receive(:production?) { true } }

      context 'current_user is blank' do
        it { expect(runner).to be_nil }
      end

      context 'current_user is not blank' do
        context 'ENABLE && admin' do
          let(:user) { double(:user, email: 'admins@asknestor.me') }

          before { ENV['FEATURE_FEATURE'] = 'ENABLE' }
          after  { ENV['FEATURE_FEATURE'] = nil }

          it { expect(runner).to eq 'works' }
        end

        context 'ENABLE only' do
          let(:user) { double(:user, email: 'abc@example.com') }

          before { ENV['FEATURE_FEATURE'] = 'ENABLE' }
          after  { ENV['FEATURE_FEATURE'] = nil }

          it { expect(runner).to be_nil }
        end

        context 'admin only' do
          let(:user) { double(:user, email: 'admins@asknestor.me') }

          context 'nil' do
            before { ENV['FEATURE_FEATURE'] = nil  }

            it { expect(runner).to be_nil }
          end

          context 'OTHERS' do
            before { ENV['FEATURE_FEATURE'] = 'DISABLE'  }
            after  { ENV['FEATURE_FEATURE'] = nil }

            it { expect(runner).to be_nil }
          end
        end
      end
    end
  end
end

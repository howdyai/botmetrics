require 'rails_helper'

describe BotInstance do
  describe 'validations' do
    subject { create :bot_instance }

    it { should validate_presence_of :token }
    it { should validate_presence_of :bot_id }
    it { should validate_presence_of :provider }
    it { should validate_uniqueness_of :token }
    it { should validate_uniqueness_of :uid }

    it { should allow_value('slack').for(:provider) }
    it { should allow_value('kik').for(:provider) }
    it { should allow_value('facebook').for(:provider) }
    it { should allow_value('telegram').for(:provider) }
    it { should_not allow_value('test').for(:provider) }

    it { should allow_value('pending').for(:state) }
    it { should allow_value('enabled').for(:state) }
    it { should allow_value('disabled').for(:state) }
    it { should_not allow_value('test').for(:state) }

    context 'conditional uid not null' do
      let!(:bi) { build :bot_instance }

      it "should be invalid if state = 'enabled' and uid IS NULL" do
        bi.state = 'enabled'
        expect(bi).to_not be_valid
        expect(bi.errors[:uid]).to eql ["can't be blank"]
      end

      it "should be valid if state = 'enabled' and uid IS NOT NULL" do
        bi.state = 'enabled'
        bi.uid = 'udeadbeef1'
        expect(bi).to be_valid
      end

      it "should be invalid if state = 'disabled' and uid IS NULL" do
        bi.state = 'disabled'
        expect(bi).to_not be_valid
        expect(bi.errors[:uid]).to eql ["can't be blank"]
      end

      it "should be valid if state = 'disabled' and uid IS NOT NULL" do
        bi.state = 'disabled'
        bi.uid = 'udeadbeef1'
        expect(bi).to be_valid
      end
    end
  end

  describe 'associations' do
    it { should belong_to  :bot }
    it { should have_many  :users }
  end
end

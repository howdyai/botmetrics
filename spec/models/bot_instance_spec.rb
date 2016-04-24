require 'rails_helper'

describe BotInstance do
  describe 'associations' do
    it { should belong_to  :bot }
    it { should have_many  :users }
  end

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

    context 'team_id is not null' do
      let!(:bi) { build :bot_instance, uid: 'UNESTOR1', instance_attributes: { 'team_url': 'https://test.com', 'team_name': 'Dead Team'} }

      it "should be invalid if state = 'enabled' and team_id IS NULL" do
        bi.state = 'enabled'
        expect(bi).to_not be_valid
        expect(bi.errors[:instance_attributes]).to eql ["team_id can't be blank"]
      end

      it "should be valid if state = 'enabled' and team_id IS NOT NULL" do
        bi.state = 'enabled'
        bi.instance_attributes['team_id'] = 'TDEADBEEF1'
        expect(bi).to be_valid
      end

      it "should be invalid if state = 'disabled' and team_id IS NULL" do
        bi.state = 'disabled'
        expect(bi).to_not be_valid
        expect(bi.errors[:instance_attributes]).to eql ["team_id can't be blank"]
      end

      it "should be valid if state = 'disabled' and team_id IS NOT NULL" do
        bi.state = 'enabled'
        bi.instance_attributes['team_id'] = 'TDEADBEEF1'
        expect(bi).to be_valid
      end
    end

    context 'team_name is not null' do
      let!(:bi) { build :bot_instance, uid: 'UNESTOR1', instance_attributes: { 'team_url': 'https://test.com', 'team_id': 'TDEADBEEF1'} }

      it "should be invalid if state = 'enabled' and team_name IS NULL" do
        bi.state = 'enabled'
        expect(bi).to_not be_valid
        expect(bi.errors[:instance_attributes]).to eql ["team_name can't be blank"]
      end

      it "should be valid if state = 'enabled' and team_name IS NOT NULL" do
        bi.state = 'enabled'
        bi.instance_attributes['team_name'] = 'Dead Team'
        expect(bi).to be_valid
      end

      it "should be invalid if state = 'disabled' and team_name IS NULL" do
        bi.state = 'disabled'
        expect(bi).to_not be_valid
        expect(bi.errors[:instance_attributes]).to eql ["team_name can't be blank"]
      end

      it "should be valid if state = 'disabled' and team_name IS NOT NULL" do
        bi.state = 'enabled'
        bi.instance_attributes['team_name'] = 'Dead Team'
        expect(bi).to be_valid
      end
    end

    context 'team_url is not null' do
      let!(:bi) { build :bot_instance, uid: 'UNESTOR1', instance_attributes: { 'team_id': 'TDEADBEEF1', 'team_name': 'Dead Team'} }

      it "should be invalid if state = 'enabled' and team_url IS NULL" do
        bi.state = 'enabled'
        expect(bi).to_not be_valid
        expect(bi.errors[:instance_attributes]).to eql ["team_url can't be blank"]
      end

      it "should be valid if state = 'enabled' and team_url IS NOT NULL" do
        bi.state = 'enabled'
        bi.instance_attributes['team_url'] = 'https://test.slack.com'
        expect(bi).to be_valid
      end

      it "should be invalid if state = 'disabled' and team_url IS NULL" do
        bi.state = 'disabled'
        expect(bi).to_not be_valid
        expect(bi.errors[:instance_attributes]).to eql ["team_url can't be blank"]
      end

      it "should be valid if state = 'disabled' and team_url IS NOT NULL" do
        bi.state = 'enabled'
        bi.instance_attributes['team_url'] = 'https://test.slack.com'
        expect(bi).to be_valid
      end
    end

    context 'conditional uid not null' do
      let!(:bi) { build :bot_instance, instance_attributes: { team_id: 'TDEADBEEF1', 'team_url': 'https://test.com', 'team_name': 'Dead Team'} }

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
end

require 'rails_helper'

RSpec.describe SettingsController, type: :controller do
  let!(:user) { create :user }
  before      { sign_in user }

  describe 'GET new' do
    def do_request
      get :new
    end

    context "there isn't a setting saved" do
      it 'should render template :new' do
        do_request
        expect(response).to render_template :new
      end
    end

    context "there is a setting saved" do
      let!(:setting) { create :setting, hostname: 'http://localhost:3000' }

      it 'should redirect to bots_path' do
        do_request
        expect(response).to redirect_to bots_path
      end
    end
  end

  describe 'POST create' do
    def do_request(hostname)
      post :create, setting: { hostname: hostname }
    end

    context 'valid hostname' do
      it 'should create a new setting' do
        expect {
          do_request('http://localhost:3000')
        }.to change(Setting, :count).by(1)

        setting = Setting.last
        expect(setting.key).to eql 'hostname'
        expect(setting.value).to eql 'http://localhost:3000'
      end

      it 'should redirect to bots_path' do
        expect {
          do_request('http://localhost:3000')
        }.to change(Setting, :count).by(1)

        expect(response).to redirect_to bots_path
      end
    end

    context 'invalid hostname' do
      it 'should not create a Setting' do
        expect {
          do_request('ftp://localhost:3000')
        }.to_not change(Setting, :count)
      end

      it 'should render template :new' do
        do_request('ftp://localhost:3000')
        expect(response).to render_template :new
      end
    end
  end
end

require 'sidekiq/web'

Rails.application.routes.draw do
  devise_for :users, controllers: { registrations: :registrations }

  resources :bots, only: [:index, :show, :new, :create, :edit, :update] do
    member do
      get :new_bots
      get :disabled_bots
      get :users
      get :messages
      get :messages_to_bot
      get :messages_from_bot
    end

    resources :instances, only: [:new, :create], controller: :bot_instances do
      member do
        get :setting_up
      end
    end
  end

  resources :users, only: [:show] do
    member do
      patch :regenerate_api_key
    end
  end

  root 'static#index'

  get '/.well-known/acme-challenge/:id' => 'static#letsencrypt'

  Sidekiq::Web.use Rack::Auth::Basic do |username, password|
    username == ENV["SIDEKIQ_USERNAME"] && password == ENV["SIDEKIQ_PASSWORD"]
  end

  mount Sidekiq::Web, at: "/sidekiq"
end

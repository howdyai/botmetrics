Rails.application.routes.draw do
  devise_for :users, controllers: { registrations: :registrations }

  resources :teams, only: [:show] do
    resources :bots, only: [:show, :new, :create] do
      resources :instances, only: [:new, :create], controller: :bot_instances do
        member do
          get :setting_up
        end
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
end

Rails.application.routes.draw do
  devise_for :users, controllers: { registrations: :registrations }

  resources :teams, only: [:show] do
    resources :bots, only: [:show] do
      resources :instances, only: [:new, :create], controller: :bot_instances
    end
  end

  root 'static#index'
end

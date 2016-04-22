Rails.application.routes.draw do
  devise_for :users, controllers: { registrations: :registrations }

  resources :teams, only: [:show] do
    resources :bots, only: [:show] do
      resources :bot_instances, only: [:new, :create]
    end
  end

  root 'static#index'
end

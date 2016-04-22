Rails.application.routes.draw do
  devise_for :users, controllers: { registrations: :registrations }

  resources :teams, only: [:show]

  root 'static#index'
end

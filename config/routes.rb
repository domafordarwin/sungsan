Rails.application.routes.draw do
  # Authentication
  resource :session, only: %i[new create destroy]
  resource :password, only: %i[edit update]

  # Members
  resources :members do
    member do
      patch :toggle_active
    end
  end

  # Profile (본인)
  resource :profile, only: [:show]

  # Admin
  namespace :admin do
    resources :users
  end

  # Dashboard (root)
  root "dashboard#index"

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end

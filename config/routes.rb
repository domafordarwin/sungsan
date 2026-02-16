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

  # Events
  resources :events do
    collection do
      get :bulk_new
      post :bulk_create
      delete :destroy_recurring
    end
    resources :assignments, only: %i[create destroy] do
      collection do
        get :recommend
      end
      member do
        post :substitute
      end
    end
    resource :attendance, controller: "attendance_records", only: [:edit, :update]
  end

  # Notifications
  resources :notifications, only: [:index, :show, :new, :create]

  # Response (토큰 기반, 인증 불필요)
  get "respond/:token", to: "responses#show", as: :response
  patch "respond/:token", to: "responses#update"
  get "respond/:token/completed", to: "responses#completed", as: :completed_response

  # Profile (본인)
  resource :profile, only: [:show]

  # Admin
  namespace :admin do
    resources :users
    resources :roles do
      member do
        patch :toggle_active
      end
    end
    resources :event_types do
      member do
        patch :toggle_active
      end
      resources :event_role_requirements, only: %i[create update destroy]
    end
  end

  # Dashboard (root)
  root "dashboard#index"

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end

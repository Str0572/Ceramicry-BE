Rails.application.routes.draw do
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    post 'signup', to: 'accounts#signup'
    post 'login', to: 'auth#login'
    post 'forgot_password', to: 'accounts#forgot_password'
    post 'otp_confirmation', to: 'accounts#otp_confirmation'
    post 'reset_password', to: 'accounts#reset_user_password'
    post 'change_password', to: 'accounts#change_password'
    resources :accounts, only: [:index, :show, :update] do
      resources :addresses, only: [:index, :show, :create, :update, :destroy]
    end
    resources :offers, only: [:index], param: :code do
      post :apply, on: :member
    end
    resources :products do
      resources :variants
      resources :reviews, only: [:index, :create]
    end
    resources :categories, param: :slug do
      resources :subcategories
    end
    get '/all_subcategory', to: 'subcategories#all_subcategory'

    get '/cart', to: 'carts#current_cart'
    post '/cart/add_item', to: 'carts#add_item'
    patch '/cart/update_item', to: 'carts#update_item'
    delete '/cart/remove_item', to: 'carts#remove_item'

    resources :orders do
      collection do
        post :checkout
        post :order_review
        get :status_options
      end
      member do
        patch :cancel
        patch :request_return
        get :track
        post :add_notes
      end
    end
    resources :subscribes, only: [:create]

  end
end

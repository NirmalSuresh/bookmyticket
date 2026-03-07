Rails.application.routes.draw do
  post '/set_city', to: 'application#set_city', as: :set_city
  get 'booking_steps/city'
  get 'booking_steps/theater'
  get 'booking_steps/date'
  get 'booking_steps/time'
  devise_for :users
  get "up" => "rails/health#show", as: :rails_health_check

  # Letter opener web routes for viewing sent emails in development
  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?
  
  # Test email route
  get '/test_email', to: 'application#test_email'
  get '/test_auto_email', to: 'application#test_auto_email'
  get '/show_test_email', to: 'application#show_test_email'
  
  # Clear email session route
  post '/clear_email_session', to: 'application#clear_email_session'

  resources :movies do
    resources :bookings, only: [:new, :create] do
      member do
        get :payment
        get :payment_success
        get :payment_failed
      end
    end
  end
  
  resources :bookings, only: [:show, :index] do
  collection do
    get :demo_booking
  end
end
  resources :screens, only: [:show]
  
  namespace :admin do
    resources :theaters do
      resources :screens
      resources :showtimes
    end
    root 'theaters#index'
  end
  
  # Step-by-step booking flow
  get 'book/:movie_id', to: 'booking_steps#city', as: 'book_movie'
  get 'book/:movie_id/city', to: 'booking_steps#city'
  get 'book/:movie_id/theater', to: 'booking_steps#theater'
  get 'book/:movie_id/date', to: 'booking_steps#date'
  get 'book/:movie_id/time', to: 'booking_steps#time'
  
  root "movies#index"
end

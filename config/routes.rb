Rails.application.routes.draw do
  devise_for :users

  # City selector
  post "/set_city", to: "application#set_city", as: :set_city

  # Booking wizard steps — /book/:movie_id/city|theater|date|time
  scope "/book/:movie_id" do
    get "city",    to: "booking_steps#city",    as: :book_movie
    get "theater", to: "booking_steps#theater", as: :book_movie_theater
    get "date",    to: "booking_steps#date",    as: :book_movie_date
    get "time",    to: "booking_steps#time",    as: :book_movie_time
  end

  # Legacy routes (keep for compatibility)
  get "booking_steps/city"
  get "booking_steps/theater"
  get "booking_steps/date"
  get "booking_steps/time"

  # Bookings
  resources :movies, only: [:index, :show] do
    resources :bookings, only: [:new, :create, :show] do
      member do
        get  :payment
        post :payment_success
        post :payment_failed
      end
    end
  end

  resources :bookings, only: [:index, :show] do
    member do
      patch :cancel
    end
  end

  # Movie routes with root
  root "movies#index"
end

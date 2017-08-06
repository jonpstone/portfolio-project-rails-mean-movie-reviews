Rails.application.routes.draw do
  root 'home#index' , as: 'home'
  get '/home/admin_area', to: 'home#admin_area'

  resources :users
  resources :genres
  resources :profiles, only: [:index, :show]

  resources :comments do
    resources :comments
  end

  resources :reviews do
    resources :comments
  end

  resources :writers do
    resources :reviews, only: [:new, :create]
  end
end

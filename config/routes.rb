Rails.application.routes.draw do
  root 'home#index' , as: 'home'
  get '/home/admin_area', to: 'home#admin_area'

  get '/signin', to: 'sessions#new'
  post '/sessions/create', to: 'sessions#create'
  delete '/signout', to: 'sessions#destroy'

  get '/auth/facebook/callback', to: 'sessions#create'

  resources :users, :genres

  resources :comments do
    resources :comments
  end

  resources :reviews do
    resources :comments
  end

  resources :writers do
    resources :reviews
  end
end

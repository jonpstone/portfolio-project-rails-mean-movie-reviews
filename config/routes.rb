Rails.application.routes.draw do
  root 'home#index' , as: 'home'
  get '/home/admin_area', to: 'home#admin_area'
  get '/about', to: 'home#about'
  get '/search', to: 'reviews#search'

  get '/auth/facebook/callback', to: 'sessions#create'
  get '/signin', to: 'sessions#new'
  post '/sessions/create', to: 'sessions#create'
  delete '/signout', to: 'sessions#destroy'

  resources :users, :genres

  resources :reviews do
    resources :comments
  end

  resources :writers do
    resources :reviews
  end
end

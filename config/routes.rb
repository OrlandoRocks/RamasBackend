Rails.application.routes.draw do
  post '/login', to: 'auth#login'
  post '/logout', to: 'auth#logout'
  post '/signup', to: 'users#create'
  post '/s3_presigned_url', to: 's3_presigned_url#create'
  get '/member-data', to: 'members#show'
  get '/users', to: 'members#index'

  resources :residentials
  resources :clients
  # Define your application router per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
end

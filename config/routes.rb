# frozen_string_literal: true

Rails.application.routes.draw do
  post '/login', to: 'auth#login'
  post '/logout', to: 'auth#logout'
  post '/signup', to: 'users#create'
  post '/s3_presigned_url', to: 's3_presigned_url#create'
  get '/member-data', to: 'members#show'
  get '/users', to: 'members#index'
  get '/contracts/:id/payments', to: 'contracts#payments'
  get '/residentials-data', to: 'members#residentials'

  resources :residentials
  resources :lands
  resources :clients
  resources :expenses
  resources :contracts
  resources :payments
  # Define your application router per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
end

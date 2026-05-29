# frozen_string_literal: true

Rails.application.routes.draw do
  post '/login', to: 'auth#login'
  post '/logout', to: 'auth#logout'
  post '/signup', to: 'users#signup'
  post '/s3_presigned_url', to: 's3_presigned_url#create'
  get '/member-data', to: 'members#show'
  resources :users, only: %i[index show create update destroy]
  get '/contracts/:id/payments', to: 'contracts#payments'
  get '/residentials-data', to: 'members#residentials'
  get '/balance', to: 'balances#all_residentials'
  get '/get_balance_data', to: 'balances#get_balance_data'
  get '/residentials-list', to: 'balances#residentials_list'
  get '/dashboard/pending_payments', to: 'dashboard#pending_payments'

  resources :residentials do
    member do
      get :geojson
      get :lands_geojson
    end
  end
  resources :lands do
    collection do
      post :import_shapefile
    end
  end
  resources :clients do
    member do
      get "documents/:document_type", to: "client_documents#show", as: :document
    end
  end
  resources :expenses
  resources :contracts
  resources :payments

  resources :geo_layers do
    collection do
      get :geojson
      post :import_shapefile
      post :preview_shapefile
    end
  end
  # Define your application router per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
end

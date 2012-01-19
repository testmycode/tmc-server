TmcServer::Application.routes.draw do

  resources :sessions, :only => [:new, :create, :destroy]

  match '/signin',  :to => 'sessions#new'
  match '/signout', :to => 'sessions#destroy'
  
  resource :user
  
  resources :participants
  
  resources :emails, :only => [:index]
  
  resources :stats, :only => [:index]
  
  resources :password_reset_keys
  match '/reset_password/:code' => 'password_reset_keys#show', :via => :get, :as => 'reset_password'
  match '/reset_password/:code' => 'password_reset_keys#destroy', :via => :delete

  resources :courses do
    member do
      get 'refresh'
      post 'refresh'
    end

    resources :points, :only => [:index, :show] do
      member do
        get 'refresh_gdocs'
      end
    end

    resources :exercises, :except => [:destroy, :create] do
      resources :submissions, :only => [:create, :index]
      resource :solution, :only => [:show]
    end
  end

  resources :submissions, :only => [:show, :update] do
    resource :result, :only => :create
  end

  root :to => "courses#index"

end

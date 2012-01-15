SandboxServer::Application.routes.draw do

  resources :sessions, :only => [:new, :create, :destroy]

  match '/signin',  :to => 'sessions#new'
  match '/signout', :to => 'sessions#destroy'
  
  resource :user
  
  resources :participants, :only => [:index]
  
  resources :emails, :only => [:index]
  
  resources :stats, :only => [:index]

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

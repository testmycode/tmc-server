SandboxServer::Application.routes.draw do

  resources :sessions, :only => [:new, :create, :destroy]

  match '/signin',  :to => 'sessions#new'
  match '/signout', :to => 'sessions#destroy'
  
  resource :profile

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
    end
  end

  resources :submissions, :only => [:show, :update]

  root :to => "courses#index"

end

SandboxServer::Application.routes.draw do

  resources :sessions, :only => [:new, :create, :destroy]

  match '/signin',  :to => 'sessions#new'
  match '/signout', :to => 'sessions#destroy'

  resources :courses do
    member do
      get 'refresh'
      post 'refresh'
    end
    resources :points, :only => :index

    resources :exercises, :except => [:destroy, :create] do
      resources :submissions, :only => [:create, :index]
    end
  end

  resources :submissions, :only => [:show]

  match '/upload_points', :to => 'points#upload_to_gdocs'

  root :to => "courses#index"

end

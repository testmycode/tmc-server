SandboxServer::Application.routes.draw do

  resources :test_case_runs

  resources :test_suite_runs

  resources :sessions, :only => [:new, :create, :destroy]

  match '/signin',  :to => 'sessions#new'
  match '/signout', :to => 'sessions#destroy'

  resources :courses do
    member do
      get 'refresh'
      post 'refresh'
      get 'points'
    end
    resources :exercises, :except => [:destroy, :create] do
      resources :exercise_returns, :as => 'returns'
    end
  end

  resources :points

  match '/upload_points', :to => 'points#upload_to_gdocs'

  root :to => "courses#index"

end

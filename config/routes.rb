TmcServer::Application.routes.draw do
  resources :sessions, :only => [:new, :create, :destroy]

  match '/signin',  :to => 'sessions#new'
  match '/signout', :to => 'sessions#destroy'
  match '/login',  :to => 'sessions#new'
  match '/logout', :to => 'sessions#destroy'

  resource :auth, :only => [:show]

  # Make POST an alternative to GET /auth.t[e]xt
  match '/auth.text', :method => :post, :to => 'auths#show'
  match '/auth.txt', :method => :post, :to => 'auths#show'

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

    resources :stats, :only => [:index, :show]
    resources :exercises, :only => [:index]
    resources :submissions, :only => [:index]
    resources :reviewed_submissions, :only =>[:index]
    resources :feedback_questions, :only => [:index, :new, :create]
    resources :feedback_answers, :only => [:index]
    match 'feedback_answers/chart/:type' => 'feedback_answers_charts#show', :via => :get, :as => 'feedback_answers_chart'
    resources :reviews, :only => [:index]
    resource :unlock, :only => [:show, :create]
    resource :course_notifications, :only => [:create, :index, :show, :new]
  end

  resources :exercises, :only => [:show] do
    resources :submissions, :only => [:create]
    resource :solution, :only => [:show]
    resources :feedback_answers, :only => [:index]
  end

  resources :submissions, :only => [:show, :update] do
    resource :result, :only => [:create]
    resources :feedback_answers, :only => [:create]
    resources :files, :only => [:index], to: redirect('/submissions/%{submission_id}#files')
    resources :reviews, :only => [:index, :new, :create]
  end

  get 'paste/:paste_key', to: 'submissions#show', as: 'paste'
  resources :reviews, :only => [:update, :destroy]

  match '/exercises/:exercise_id/submissions' => 'submissions#update_by_exercise', :via => :put, :as => 'exercise_update_submissions'

  resources :feedback_questions, :only => [:show, :update, :destroy] do
    resource :position, :only => [:update]
  end

  resources :feedback_answers, :only => [:show]

  resource :page_presence, :only => [:update]

  resource :feedback_replies, :only => [:create]

  root :to => "courses#index"

end

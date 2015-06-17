TmcServer::Application.routes.draw do
  resources :organizations, path: 'org' do
    member do
      post 'accept'
      post 'reject'
      get 'reject_reason_input'
    end

    collection do
      get 'list_requests'
    end

    resources :teachers, only: [:index, :new, :create, :destroy]
    get 'course_templates', to: 'course_templates#list_for_teachers'
    get 'course_templates/:id', to: 'course_templates#prepare_course', as: 'prepare_course'

    resources :courses do
      member do
        get 'refresh'
        post 'refresh'
        get 'courses', to: 'courses#show_json', format: 'json', as: 'one_course_json'
        get 'manage_deadlines'
        post 'save_deadlines'
        post 'enable'
        post 'disable'
        get 'manage_unlocks'
        post 'save_unlocks'
      end

      resources :assistants, only: [:index, :new, :create]

      resources :points, only: [:index, :show] do
        member do
          get 'refresh_gdocs'
        end
      end

      get 'help'

      resources :stats, only: [:index, :show]
      resources :exercise_status, only: [:show]
      resources :exercises, only: [:index]
      resources :submissions, only: [:index]
      resources :reviewed_submissions, only: [:index]
      resources :feedback_questions, only: [:index, :new, :create]
      resources :feedback_answers, only: [:index]
      get 'feedback_answers/chart/:type' => 'feedback_answers_charts#show', :as => 'feedback_answers_chart'
      resources :reviews, only: [:index]
      resource :unlock, only: [:show, :create]
      resource :course_notifications, only: [:create, :index, :show, :new]
    end
  end

  resources :course_templates, except: :show do
    member do
      post 'toggle_hidden', to: 'course_templates#toggle_hidden'
    end
  end

  resources :sessions, only: [:new, :create, :destroy]

  get '/signin', to: 'sessions#new'
  delete '/signout', to: 'sessions#destroy'
  get '/login', to: 'sessions#new'
  get '/logout', to: 'sessions#destroy'

  resource :auth, only: [:show]

  # Make POST an alternative to GET /auth.t[e]xt
  post '/auth.text', to: 'auths#show'
  post '/auth.txt', to: 'auths#show'

  resource :user

  resources :participants

  resources :emails, only: [:index]

  resources :stats, only: [:index]

  resources :password_reset_keys
  get '/reset_password/:code' => 'password_reset_keys#show', :as => 'reset_password'
  delete '/reset_password/:code' => 'password_reset_keys#destroy'

  resources :exercises, only: [:show] do
    resources :submissions, only: [:create]
    resource :solution, only: [:show]
    resources :feedback_answers, only: [:index]
  end

  resources :submissions, only: [:show, :update] do
    resource :result, only: [:create]
    resources :feedback_answers, only: [:create]
    resources :files, only: [:index]
    resources :reviews, only: [:index, :new, :create]
    resources :full_zip, only: [:index]
  end

  get 'paste/:paste_key', to: 'submissions#show', as: 'paste'
  resources :reviews, only: [:update, :destroy]

  put '/exercises/:exercise_id/submissions' => 'submissions#update_by_exercise', :as => 'exercise_update_submissions'

  resources :feedback_questions, only: [:show, :update, :destroy] do
    resource :position, only: [:update]
  end

  resources :feedback_answers, only: [:show]

  resource :page_presence, only: [:update]

  resource :feedback_replies, only: [:create]

  if SiteSetting.value('pghero_enabled')
    constraints CanAccessPgHero do
      mount PgHero::Engine, at: 'pghero'
    end
  end

  root to: 'organizations#index'
end

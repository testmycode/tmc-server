TmcServer::Application.routes.draw do
  use_doorkeeper

  namespace :setup do
    resources :start, only: [:index]

    resources :organizations, only: [:index, :new, :create, :edit, :update], path: '' do
      resources :course_chooser, only: [:index]

      resource :course, only: [:new, :create], controller: :course_details, path_names: {new: 'new/:template_id'} do
        get 'new/custom', to: 'course_details#custom'
      end
      resources :courses, only: [] do
        resource :course_details, only: [:edit, :update]
        resource :course_timing, only: [:index, :show, :edit, :update]
        resources :course_assistants, only: [:index, :create, :destroy]
        resources :course_finisher, only: [:index, :create]
      end
    end
  end

  namespace :api, :constraints => {:format => /(html|json|js|)/} do
    namespace :beta, defaults: {format: 'json'} do
      get '/demo', to: 'demo#index'
      resources :participant, only: [:index] do
        member do
          get 'courses'
        end
        collection do
          get 'courses'
        end
      end
      resources :course_id_information, only: [:index]
      resources :stats, only: [] do
        collection do
          get 'submission_queue_times'
          get 'submission_processing_times'
        end
      end
    end

    namespace :v8, defaults: {format: 'json'} do
      resources :apidocs, only: :index, path: 'documentation'

      resources :users, only: :show

      resources :organizations, param: :slug, path: 'org', only: [:index] do
        resources :courses, module: :organizations, param: :name, only: :show do
          resources :points, module: :courses, only: :index
          resources :users, module: :courses, only: [] do
            resources :points, module: :users, only: :index
          end

          resources :exercises, module: :courses, param: :name, only: :index do
            resources :points, module: :exercises, only: :index
            resources :users, module: :exercises, only: [] do
              resources :points, module: :users, only: :index
            end
            get 'download', on: :member
          end

          resources :submissions, module: :courses, only: :index
          resources :users, module: :courses, only: [] do
            resources :submissions, module: :users, only: :index
          end
        end
      end

      resources :courses, only: :show do
        resources :points, module: :courses, only: :index
        resources :users, module: :courses, only: [] do
          resources :points, module: :users, only: :index
        end

        resources :exercises, module: :courses, param: :name, only: :index do
          resources :points, module: :exercises, only: :index
          resources :users, module: :exercises, only: [] do
            resources :points, module: :users, only: :index
          end
        end

        resources :submissions, module: :courses, only: :index
        resources :users, module: :courses, only: [] do
          resources :submissions, module: :users, only: :index
        end
      end

      namespace :core, defaults: {format: 'json'} do
        resources :courses, only: [:show] do
          resource :unlock, module: :courses, only: [:create]
          resources :reviews, module: :courses, only: [:index, :update]
        end
        resources :submissions, only: [] do
          resources :reviews, module: :submissions, only: [:create]
          get 'download', on: :member
        end
        resources :exercises, only: [:show] do
          resources :submissions, module: :exercises, only: [:create]
          resource :solution, module: :exercises, only: [] do
            get 'download', on: :member
          end
          get 'download', on: :member
        end
        resources :organizations, param: :slug, path: 'org', only: [] do
          resources :courses, module: :organizations, only: :index
        end
      end

      resources :application, param: :name, only: [] do
        resources :credentials, module: :application, only: :index
      end
    end
  end

  resources :organizations, except: [:destroy, :create, :edit, :update], path: 'org' do

    resources :exercises, only: [:show] do
      member do
        post 'toggle_submission_result_visibility'
      end
      resources :submissions, only: [:create]
      resource :solution, only: [:show]
      resources :feedback_answers, only: [:index]
    end
    member do
      post 'verify'
      post 'disable'
      get 'disable_reason_input'
      post 'toggle_visibility'
    end

    collection do
      get 'list_requests'
    end

    resources :participants, only: [:index]

    resources :teachers, only: [:index, :create, :destroy]

    get 'course_templates', to: 'course_templates#list_for_teachers'

    resources :courses, except: [:new, :create] do
      member do
        get 'refresh'
        post 'refresh'
        post 'enable'
        post 'disable'
        get 'courses', to: 'courses#show_json', format: 'json', as: 'one_course_json'
        get 'students', to: 'courses#student_emails'
        resources :emails, only: [:index]
        get 'manage_deadlines'
        post 'save_deadlines'
        get 'manage_unlocks'
        post 'save_unlocks'
        get 'manage_exercises'
        post 'toggle_submission_result_visibility'
      end

      resources :points, only: [:index, :show] do
        member do
          get 'refresh_gdocs'
        end
      end

      resources :exercises, only: [:index] do
        collection do
          post 'set_disabled_statuses'
        end
      end

      get 'help'

      resources :stats, only: [:index, :show]
      resources :exercise_status, only: [:show]
      resources :submissions, only: [:index]
      resources :reviewed_submissions, only: [:index]
      resources :feedback_questions, only: [:index, :new, :create]
      resources :feedback_answers, only: [:index]
      get 'feedback_answers/chart/:type' => 'feedback_answers_charts#show', :as => 'feedback_answers_chart'
      resources :reviews, only: [:index]
      resource :unlock, only: [:show, :create]
      resource :course_notifications, only: [:create, :index, :show, :new]
      resources :migrate_to_other_course, only: [:show] do
        member do
          post :migrate
        end
      end
    end

    resources :stats, only: [:index]
  end

  resources :course_templates do
    member do
      post 'toggle_hidden', to: 'course_templates#toggle_hidden'
      post 'refresh'
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

  resources :participants do
    resources :certificates, only: [:index]
    collection do
      get 'me', to: 'participants#me'
    end
  end

  resources :certificates, only: [:show, :create]

  resources :emails, only: [:index]

  resources :stats, only: [:index]

  resources :password_reset_keys
  get '/reset_password/:token' => 'password_reset_keys#show', :as => 'reset_password'
  delete '/reset_password/:token' => 'password_reset_keys#destroy'

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

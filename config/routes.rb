# frozen_string_literal: true

TmcServer::Application.routes.draw do
  use_doorkeeper_openid_connect
  use_doorkeeper

  mount ActionCable.server => '/cable'

  namespace :setup do
    resources :start, only: [:index]

    resources :organizations, only: %i[index new create edit update], path: '' do
      resources :course_chooser, only: [:index]

      resource :course, only: %i[new create], controller: :course_details, path_names: { new: 'new/:template_id' } do
        get 'new/custom', to: 'course_details#custom'
      end
      resources :courses, only: [] do
        resource :course_details, only: %i[edit update]
        resource :course_timing, only: %i[index show edit update]
        resources :course_assistants, only: %i[index create destroy]
        resources :course_finisher, only: %i[index create]
      end
    end
  end

  namespace :api, constraints: { format: /(html|json|js|)/ } do
    namespace :beta, defaults: { format: 'json' } do
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

    namespace :v8, defaults: { format: 'json' } do
      resources :apidocs, only: :index, path: 'documentation'

      namespace :users do
        resources :password_reset, only: [:create]
        resources :basic_info_by_usernames, only: :create
        resources :basic_info_by_emails, only: :create
        resources :basic_info_by_ids, only: :create
        resources :recently_changed_user_details, only: :index
      end

      resources :users, only: %i[show create update destroy] do
        resources :request_deletion, only: [:create], module: :users
        resources :assistantships, module: :users, only: :index
        resources :teacherships, module: :users, only: :index
        post :set_password_managed_by_courses_mooc_fi, on: :member
        get :get_user_with_email, on: :collection
      end

      resources :user_app_datum, only: [:index]
      resources :user_field_value, only: [:index]

      resources :organizations, param: :slug, path: 'org', only: %i[index show] do
        resources :courses, module: :organizations, param: :name, only: :show do
          resources :points, module: :courses, only: :index
          resources :users, module: :courses, only: [] do
            resources :points, module: :users, only: :index
            resources :progress, module: :users, only: :index
          end

          resources :exercises, module: :courses, param: :name, only: %i[index show], constraints: { name: /.*/ } do
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

          get 'eligible_students', to: 'courses/studyright_eligibility#eligible_students'
        end
        resources :memberships, module: :organizations, only: [:create, :index]
      end

      resources :courses, only: :show do
        resources :points, module: :courses, only: :index
        resources :users, module: :courses, only: [] do
          resources :points, module: :users, only: :index
        end

        resources :all_courses_with_this_template, module: :courses, only: :index

        resources :exercises, module: :courses, param: :name, only: :index do
          resources :points, module: :exercises, only: :index
          resources :users, module: :exercises, only: [] do
            resources :points, module: :users, only: :index
          end
        end

        resources :submissions, module: :courses, only: :index

        namespace :submissions, module: :courses do
          resources :last_hour, module: :submissions, only: :index
        end

        resources :users, module: :courses, only: [] do
          resources :submissions, module: :users, only: :index
        end
      end

      resources :exercises, only: [] do
        resources :model_solutions, only: [:index], module: :exercises
        resources :users, module: :exercises, only: [] do
          resources :submissions, module: :users, only: :index
        end
      end

      namespace :core, defaults: { format: 'json' } do
        resources :courses, only: [:show] do
          resource :unlock, module: :courses, only: [:create]
          resources :reviews, module: :courses, only: %i[index update]
        end
        resources :submissions, only: [:show] do
          resources :reviews, module: :submissions, only: [:create]
          resources :feedback, module: :submissions, only: [:create]
          get 'download', on: :member
        end
        namespace :exercises, defaults: { format: 'json' } do
          resource :details, only: [:show]
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

  resources :organizations, except: %i[destroy create edit update], path: 'org' do
    member do
      post 'verify'
      post 'disable'
      get 'disable_reason_input'
      post 'toggle_visibility'
      get 'all_courses'
    end

    collection do
      get 'list_requests'
    end

    get 'course_templates', to: 'course_templates#list_for_teachers'

    resources :exercises, only: [:show] do
      member do
        post 'toggle_submission_result_visibility'
      end
      resources :submissions, only: [:create]
      resource :solution, only: [:show]
      resources :feedback_answers, only: [:index]
    end

    resources :participants, only: [:index]

    resources :teachers, only: %i[index create destroy]

    resources :courses, except: %i[new create] do
      member do
        get 'refresh'
        post 'refresh'
        post 'enable'
        post 'disable'
        post 'toggle_hidden'
        post 'toggle_code_review_requests'
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

      resources :points, only: %i[index show]

      resources :exercises, only: [:index] do
        collection do
          post 'set_disabled_statuses'
        end
      end

      get 'help'

      resources :stats, only: %i[index show]
      resources :exercise_status, only: [:show]
      resources :submissions, only: [:index]
      resources :reviewed_submissions, only: [:index]
      resources :feedback_questions, only: %i[index new create]
      resources :feedback_answers, only: [:index]
      get 'feedback_answers/chart/:type' => 'feedback_answers_charts#show', :as => 'feedback_answers_chart'
      resources :reviews, only: [:index]
      resource :unlock, only: %i[show create]
      resource :course_notifications, only: %i[create index show new]
      resources :migrate_to_other_course, only: [:show] do
        member do
          post :migrate
        end
      end
    end

    resources :stats, only: [:index]
  end

  resources :courses do
    resources :migrate_to_other_course, controller: 'migrate_to_other_course', only: [:show] do
      member do
        post :migrate
      end
    end
  end

  resources :course_templates do
    member do
      post 'toggle_hidden', to: 'course_templates#toggle_hidden'
      post 'refresh'
    end
  end

  resources :sessions, only: %i[new create destroy]

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
    resource :settings, only: [:show, :update] do
      post 'dangerously_destroy_user', to: 'settings#dangerously_destroy_user'
      get 'verify_dangerously_destroying_user', to: 'settings#verify_dangerously_destroying_user'
      delete 'dangerously_destroy_user', to: 'settings#dangerously_destroy_user'
      get 'user_has_submissions', to: 'settings#user_has_submissions'
    end
    resources :certificates, only: [:index]
    collection do
      get 'me', to: 'participants#me'
    end
    member do
      get 'password_reset_link', to: 'participants#password_reset_link'
    end
  end

  get '/users/:user_id/verify/:id', to: 'users#confirm_email', as: 'confirm_email'
  post '/users/:user_id/send_verification_email', to: 'users#send_verification_email', as: 'send_verification_email'

  resources :users, only: [:index]

  post '/users/:user_id/send_destroy_email', to: 'users#send_destroy_email', as: 'send_destroy_email'
  get '/users/:user_id/destroy/:id', to: 'users#verify_destroying_user', as: 'verify_destroying_user'
  delete '/users/:user_id/destroy/:id', to: 'users#destroy_user', as: 'destroy_user'

  resources :certificates, only: %i[show create]

  resources :emails, only: [:index]

  resources :stats, only: [:index]

  resources :password_reset_keys
  get 'reset_password', to: 'password_reset_keys#new', as: 'reset_password_pretty'
  get '/reset_password/:token' => 'password_reset_keys#show', :as => 'reset_password'
  delete '/reset_password/:token' => 'password_reset_keys#destroy'

  resources :exercises, only: [:show] do
    resources :submissions, only: [:create]
    resource :solution, only: [:show]
    resources :feedback_answers, only: [:index]
  end

  resources :submissions, only: %i[show update] do
    resource :result, only: [:create]
    resources :feedback_answers, only: [:create]
    resources :files, only: [:index]
    resources :reviews, only: %i[index new create]
    resources :full_zip, only: [:index]
    get 'difference_with_solution', to: 'submissions#difference_with_solution'
  end

  get 'paste/:paste_key', to: 'submissions#show', as: 'paste'
  resources :reviews, only: %i[update destroy]

  put '/exercises/:exercise_id/submissions' => 'submissions#update_by_exercise', :as => 'exercise_update_submissions'

  resources :feedback_questions, only: %i[show update destroy] do
    resource :position, only: [:update]
  end

  resources :feedback_answers, only: [:show]

  resource :page_presence, only: [:update]

  resource :feedback_replies, only: [:create]

  resources :status, only: [:index]

  resources :model_solution_token_useds, only: [:index, :show]

  if SiteSetting.value('pghero_enabled')
    constraints CanAccessPgHero do
      mount PgHero::Engine, at: 'pghero'
    end
  end

  root to: 'organizations#index'
end

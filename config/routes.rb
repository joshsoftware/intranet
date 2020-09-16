require 'sidekiq/web'
Rails.application.routes.draw do

  mount RedactorRails::Engine => '/redactor_rails'

  get '/auto-opt-in' => 'light/users#auto_opt_in', as: 'users/auto_opt_in'
  get '/thank_you' => 'light/users#thank_you', as: 'users/thank_you'
  post '/opt_in' => 'light/users#opt_in', as: 'users/opt_in'
  devise_for :users, controllers: { omniauth_callbacks: "omniauth_callbacks" }
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  resources :policies
  resources :holiday_lists
  resources :designations
  resources :entry_passes do
    collection do
      get :report, defaults: { format: :csv }
    end
  end

  get 'holiday_list', to: 'holiday_lists#holiday_list'
  get '/unsubscribe' => 'light/users#unsubscribe', as: 'users/unsubscribe'
  #get '/unsubscribe/:id' => 'light/users#unsubscribe', as: 'users/unsubscribe'
  match '/subscribe' => 'light/users#subscribe', as: 'users/subscribe', via: [:get, :post]
  get '/remove' => 'light/users#remove', as: 'users/remove'
  get '/web-version/:id' => 'light/newsletters#web_version', as: 'newsletter/web_version'

  devise_scope :user do
    match :invite_user, to: 'users#invite_user', via: [:get, :post]
    match '/admin', to: 'devise/sessions#new', via: [:get]
    match '/screamout/iframe_contents/new' => 'screamout/iframe_contents#new', via: [:get]
  end

  unauthenticated :user do
    match '/screamout/contents' => 'home#store_url', via: [:get]
  end

  authenticate :user do
    mount Sidekiq::Web => '/sidekiq'
    mount Light::Engine => '/newsletter'
    mount Screamout::Engine => '/screamout'
  end

  get 'contacts' => 'admins#contacts_from_site', as: 'site_contacts'

  get 'calendar' => 'home#calendar', as: :calendar
  get 'resource_list', to: 'users#resource_list'
  get 'resource_list_download',to: 'users#resource_list_download'
  resources :leave_applications, only: [:index, :edit, :update]
  resources :users, except: [:new, :create, :destroy] do
    resources :leave_applications, except: [:view_leave_status, :index, :edit, :update]
    member do
      match :public_profile, via: [:get, :put]
      match :private_profile, via: [:get, :put]
      get :download_document
      get '/get_feed/:feed_type' => 'users#get_feed'
    end
  end

  resources :vendors do
    collection do
      post :import_vendors
    end
  end

  put 'available_leave/:id' => 'users#update_available_leave', as: :update_available_leave
  get 'view/leave_applications' => 'leave_applications#view_leave_status', as: :view_leaves
  #get 'cancel_leave_application' => 'leave_applications#cancel_leave', as: :cancel_leave
  #get 'approve_leave_application' => 'leave_applications#approve_leave', as: :approve_leave
  get 'process_leave_application' => 'leave_applications#process_leave', as: :process_leave
  resources :projects do
    member do
      post 'update_sequence_number'
      post 'add_team_member', as: "add_team_member"
      delete 'remove_team_member/:user_id' => "projects#remove_team_member", as: :remove_team_member
    end
    get 'export_project_report', as: :export_report, on: :collection
    get 'generate_code', as: :generate_code, on: :collection
  end

  resource :repositories do
    get 'overview_index', as: :overview_index, on: :collection
    get 'repository_issues', as: :repository_issues, on: :collection
    get 'get_repo_issues', as: :get_repo_issues, on: :collection
  end

  resources :companies do
    resources :projects, only: [:new, :create, :edit, :update]
  end

  resources :attachments do
    member do
      get :download_document
    end
  end

  resources :schedules do
    patch :get_event_status
    patch :feedback
  end

  namespace :api, :defaults => {:format => 'json'} do
    namespace :v1 do
      get 'users/info', to: 'users#info'
      get 'team', to: "website#team"
      get 'news', to: "website#news"
      get 'portfolio', to: "website#portfolio"
      post 'contact_us', to: "website#contact_us"
      post 'contact_clipp', to: "clipp_contacts#contact_clipp"
      post 'career', to: "website#career"
    end
  end

  resources :time_sheets, only: [:create, :index, :new] do
    post :daily_status, on: :collection
    post :import, on: :collection
    post :add_time_sheet, on: :collection
    get :add_time_sheet, on: :collection
    get :projects_report, on: :collection
    get :individual_project_report, on: :member
    get :export_project_report, on: :collection
    get :export_resource_report, on: :collection

    collection do
      get 'users_timesheet/:user_id' => 'time_sheets#users_timesheet', as: 'users'
      get 'edit_timesheet/:user_id' => 'time_sheets#edit_timesheet', as: 'edit'
      put 'update_timesheet/:user_id' => 'time_sheets#update_timesheet', as: 'update'
    end
  end

  resources :slack, only: :projects do
    post :projects, on: :collection
  end

  post '/blog_publish_hook' => 'application#blog_publish_hook', as: :blog_publish_hook
  # You can have the root of your site routed with "root"
  # root 'welcome#index'
  root 'home#index'
  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

end

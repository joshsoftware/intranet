require 'sidekiq/web'
Intranet::Application.routes.draw do
  
  mount RedactorRails::Engine => '/redactor_rails'
  devise_for :users, controllers: { omniauth_callbacks: "omniauth_callbacks" }
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  resources :policies
  get '/unsubscribe/:id' => 'light/users#unsubscribe', as: 'users/unsubscribe'
  match '/subscribe/:id' => 'light/users#subscribe', as: 'users/subscribe', via: [:get, :post]
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
  resources :leave_applications, only: [:index, :edit, :update] 
  resources :users, except: [:new, :create, :destroy] do
    resources :leave_applications, except: [:view_leave_status, :index, :edit, :update] 
    member do
      match :public_profile, via: [:get, :put]
      match :private_profile, via: [:get, :put]
      get :download_document
    end
  end

  resources :vendors do
    collection do
      post :import_vendors
    end
  end
  
  put 'available_leave/:type/:id' => 'leave_details#update_available_leave', as: :update_available_leave 
  get 'view/leave_applications' => 'leave_applications#view_leave_status', as: :view_leaves 
  get 'cancel_leave_application' => 'leave_applications#cancel_leave', as: :cancel_leave 
  get 'approve_leave_application' => 'leave_applications#approve_leave', as: :approve_leave
  resources :projects
  resources :attachments do 
    member do
      get :download_document
    end
  end

  resources :schedules do
    patch :get_event_status
    patch :feedback
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

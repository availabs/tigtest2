NymtcGateway::Application.routes.draw do

  resources :snapshots

  resources :sources do
    member do
      get 'metadata', to: 'sources#show'
      get 'import'
      get 'watch'
      get 'unwatch'
      get 'get_disclaimer'
    end
    collection do
      get 'state'
      patch 'update_state'
      patch 'switch_catalog_view'
      post 'render_catalog_table'
      post 'render_catalog_list'
    end
  end

  resources :views do
    member do
      get 'table'
      get 'map'
      get 'base_overlay'
      get 'data_overlay'
      get 'export_shp'
      get 'feature_geometry'
      get 'layer_ui'
      post 'symbology'
      get 'chart', controller: :view_charts
      get 'metadata', to: 'views#show'
      post 'update_year'
      get 'demo_statistics'
      get 'tmc_roadname'
      get 'link_roadname'
      get 'watch'
      get 'unwatch'
      get 'restore'
    end
    collection do
      get 'data_recovery'
    end
  end

  resources :comments do
    collection do 
      get 'preview_last_n'
    end
    member do
      post 'block'
      post 'unblock'
    end
  end


  # authenticated :user do
  #   root :to => 'home#index'
  # end
  root :to => "home#index"

  devise_for :users, :controllers => { passwords: 'passwords' }, :skip => [:registrations]
  devise_scope :user do
    post '/users/create_from_sign_up', to: 'registrations#create', as: 'user_registration'
    get '/users/sign_up', to: 'registrations#new', as: 'new_user_registration'
    get '/users/edit', to: 'registrations#edit', as: 'edit_user_registration'
    put '/users/edit', to: 'registrations#update', as: nil
  end
  resources :users
  resources :agencies
  resources :access_controls, only: [:new, :create, :edit, :update, :destroy] do
    collection do
      get 'restore_default'
      get 'use_source'
    end
  end
  resources :watches do
    collection do
      # post 'trigger'
      post 'update_last_seen_at'
    end
  end

  resources :uploads, only: [:index, :new, :create, :show] do
    collection do
      get 'new_help'
    end
    member do
      get 'queue'
      get 'reset'
      get 'status'
    end
  end

  resources :shapefile_exports, only: [] do
    member do
      get 'status'
      get 'download'
    end
  end

  resources :study_areas

  resources :symbologies, only: [:create, :destroy]

  get 'system_usage_report', controller: :application
  get 'system_change_report', controller: :application
  get 'user_activity_report', controller: :application
end

Orderviewer::Application.routes.draw do
  get "sessions/new"
  root :to => "home#index"
  post 'login', to: 'sessions#new', as: 'login'
  get 'logout', to: 'sessions#destroy', as: 'logout'
  
  resources :sessions
  
  resources :home do
    member do
    end
  end

  resources :process_orders do
    member do
    end
  end  
  
  resources :orders, :items do
    member do
      get 'show'
    end
  end
end

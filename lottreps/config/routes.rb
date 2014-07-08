Lottreps::Application.routes.draw do
  match 'users/sign_up' => 'users#sign_in'
  
  devise_for :users

  root :to => "main#index"
  match 'artists' => "main#artists"
  match 'collections' => "main#collections"
  match 'artists_admin' => 'artists#index'
  get '/admin' => redirect("/admin/artists/?artist_type=1")
  match 'admin' => 'artists#index'
  match 'admin/artists' => 'artists#index'
  match 'admin/artworks' => 'artworks#index'
  match 'about' => 'main#about'
  put '/admin/artists/:id/update_position' => 'artists_admin#update_position'
  match 'artworks/:id/update_position' => 'artworks#update_position'
  get '/artists_admin/:id/edit' => 'artists#edit'
  get '/artists_admin/:id/delete' => 'artists#delete'
  get '/artists_admin/new' => 'artists#new'
  post '/artists_admin/create' => 'artists#create'
  post "/artists/create"  => 'artists_admin#create'
  match '/artist/new' => 'artists_admin#new'
  match '/artist/new_placeholder' => 'artists#new_placeholder'
  match 'contact' => 'main#contact'

  resources :admin, :artists_admin, :artists, :artworks do
    member do
      get 'delete'
      get 'show'
      get 'bio'
      get 'email'
    end
  end
  
  resources :main do
    member do
      get 'contact'
    end
  end

  resources :email_forms, :contact_forms

end
class MainController < ApplicationController
   
   before_filter :if_logged_in
   
   def index
     show_public_menu
   end
  
   def if_logged_in
     session[:user_id] = cookies.signed[:user_id] if cookies[:user_id]
     if session[:user_id]
       redirect_to(:controller => 'habits', :action => 'entry')
     end
   end
   
end

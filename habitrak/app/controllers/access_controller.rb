class AccessController < ApplicationController

   def index
     render('login')
   end

   def login
     show_public_menu
     # login form
   end

   def attempt_login
     authorized_user = User.authenticate(params[:email], params[:pass])
     if authorized_user
       session[:user_id] = authorized_user.id
       if params[:remember_me][:remember] == '1'
         cookies.signed[:user_id] = { :value => authorized_user.id.to_s, :expires => 2.weeks.from_now }
       end  
       flash[:alert] = "Welcome back #{authorized_user.first_name.capitalize}!"
       redirect_to habits_url 
     else
       flash[:error] = "Invalid username/password combination."
       redirect_to(:action => 'login')
     end
   end

   def logout
     session.delete :user_id 
     cookies.delete :user_id 
     cookies.delete :trend
     flash[:alert] = "Goodbye. Come back soon."
     redirect_to root_url
   end

end
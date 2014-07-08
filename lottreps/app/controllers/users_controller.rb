class UsersController < ApplicationController
  
  def sign_in
    redirect_to new_user_session_url
  end  
end

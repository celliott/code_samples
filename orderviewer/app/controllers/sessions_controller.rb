class SessionsController < ApplicationController
  require 'digest'
  require 'rest-client'
  require 'json'
  
  skip_before_filter :verify_authenticity_token
  
  def new
  end

  def create
    auth_hash = {
      :email => params[:login][:email],
      :password => params[:login][:password],
    }
    api_path = '/access_token'
    api_auth(api_path, auth_hash)
    
    if params[:login][:email] != "" && auth_hash[:password] != "" && @user_hash
      if @user_hash[:email] == auth_hash[:email] && @user_hash[:type] == 'A'
        cookies.signed[:makr] = { :value => auth_hash[:email], :expires => 4.weeks.from_now }
        redirect_to orders_url
      end  
    else
      render "new"
    end
  end

  def destroy
    sleep 0.5
    cookies.delete :makr
    redirect_to root_url
  end

end

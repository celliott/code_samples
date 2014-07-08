class HomeController < ApplicationController
  require 'actionpack/action_caching'
  
  #caches_action :index
    
  def index
    sleep 0.3
    session[:makr] = cookies[:makr]
    if session[:makr]
      redirect_to orders_url
    end  
  end

end

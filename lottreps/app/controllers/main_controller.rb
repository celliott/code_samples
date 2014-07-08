class MainController < ApplicationController
  
  def index
    @artists = Artist.order(:position).where('active = true AND artist_type = 1')
    @artists_arr = [*0..(@artists.count)]
    if current_user
      @admin = true if current_user.admin == true
    end
  end 
  
  def artists
    @artists = Artist.order(:position).where('active = true AND artist_type = 1')

    @artists_arr = [*0..(@artists.count)]
    if current_user
      @admin = true if current_user.admin == true
    end
  end
  
  def collections
    @collection = Artist.order(:position).where('active = true AND artist_type = 2')
    @collections_arr = [*0..(@collection.count)]
    if current_user
      @admin = true if current_user.admin == true
    end
  end
  
  def contact
  end
  
  def admin
    @admin = true
  end 
  
  def about
    respond_to do |format|
      format.html
      format.js
    end
  end
    
end

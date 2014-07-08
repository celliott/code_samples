class ArtistsAdminController < ApplicationController

  before_filter :authenticate_user!
  
  skip_before_filter :authenticate_user!, :only => [:show, :bio, :email]

  def index
    @admin = true    
    respond_to do |format|
      format.html
      format.json { render json: ArtistsDatatable.new(view_context) }
    end

  end

  def new
    @artist = Artist.new
    respond_to do |format|
      format.html
      format.js
    end
  end
  
  def new_placeholder
    @artist = Artist.new
    @artist.name = "placeholder"
    @artist.save
    redirect_to artists_url
  end  

  def create
    @artist = Artist.new(params[:artist])
    if @artist.artist_type == "Artists"
      @artist.artist_type = 1
    elsif @artist.artist_type == "Collections"
      @artist.artist_type = 2
    end
    
    session[:artist_type] =
    
    respond_to do |format|
      if @artist.save
        flash[:success] = 'artist created'
        format.html { redirect_to "/admin/artists/?artist_type=#{ @artist.artist_type}" }
        format.js { render '/layouts/index' }
      else
        format.html { render :partial => "new" }
        format.js { render :action => "new" }
      end
    end
  end

  def email
    @artist = Artist.find(params[:id])
  end
    
  def show
    if current_user
      @admin = true if current_user.admin == true
    end
    @artist = Artist.find(params[:id])
    @back_url = "artists"
    @back_url = "collections" if @artist.artist_type ==2
    @artworks = Artwork.order(:position).where('artist_id = ?', @artist.id)
    @artworks_arr = [*0..(@artworks.count)]
  end
  
  def bio
    if current_user
      @admin = true if current_user.admin == true
    end
    @artist = Artist.find(params[:id])
    respond_to do |format|
      format.html
      format.js
    end
  end

  def edit
    @artist = Artist.find(params[:id])
    respond_to do |format|
      format.html
      format.js 
    end
  end

  def update
    @artist = Artist.find(params[:id])
    if @artist.artist_type == 1
      @artist_type_sel = "Artist"
    elsif @artist.artist_type == 2
      @artist_type_sel = "Collection"
    end  
    respond_to do |format|
      if @artist.update_attributes(params[:artist])
        flash[:success] = "#{@artist.name} updated"
        format.html { redirect_to "/admin/artists/?artist_type=#{ @artist.artist_type}" }
        format.js { render '/layouts/index' }
      else
        format.html { render :partial => "edit" }
        format.js { render :action => "edit" }
      end
    end
  end
  
  def update_position
    new_position = params[:artist].delete(:position)
    @artist = Artist.find(params[:id])
    artist_type = session[:artist_type]
    respond_to do |format|
      if @artist.update_attributes(params[:artist])
        @artist.move_to_position(new_position)
        flash[:success] = "#{@artist.name}'s position updated"
        format.html { redirect_to "/admin/artists/?artist_type=#{ @artist.artist_type}" }
        format.js { render '/layouts/index' }
      else
        flash[:error] = "#{@artist.name}'s position not updated"
        format.html { redirect_to "/admin/artists/?artist_type=#{ @artist.artist_type}" }
        format.js { render '/layouts/index' }
      end
    end
  end

  def delete
    @artist = Artist.find(params[:id])
    respond_to do |format|
      format.html
      format.js
    end
  end

  def destroy
    @artist = Artist.find(params[:id])
    @artist.destroy
    @artist.reset_position
    respond_to do |format|
      flash[:success] = 'artist removed'
      format.html { redirect_to artists_url}
      format.js { render '/layouts/index' }
    end
  end  

end
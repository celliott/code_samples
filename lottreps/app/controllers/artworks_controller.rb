class ArtworksController < ApplicationController
  require 'RMagick'
  
  before_filter :authenticate_user!

  skip_before_filter :authenticate_user!, :only => :show
  
  def index
    @admin = true
    @artist = Artist.find(params[:artist_id]) if params[:artist_id]
    respond_to do |format|
      format.html
      format.json { render json: ArtworksDatatable.new(view_context) }
    end
    
  end

  def show
    @artwork = Artwork.find(params[:id])
  end

  def new
    @artwork = Artwork.new
  end

  def create
    @artwork = Artwork.new(params[:artwork])
    @artwork.artist_id = params[:artist_id]
    @artwork.position = @artwork.default_position(@artwork.artist_id)
    @artwork.thumb_position = "2"
    @artwork.save!
  end

  def edit
    @artwork = Artwork.find(params[:id])
      respond_to do |format|
        format.html
        format.js 
    end
  end

  def update
    @artwork = Artwork.find(params[:id])
    respond_to do |format|
        if @artwork.update_attributes(params[:artwork])
          flash[:success] = 'artwork updated'
          format.html { redirect_to "/artworks?artist_id=#{@artwork.artist_id}" }
          format.js { render '/layouts/index' }
        else
          format.html { render :partial => "edit" }
          format.js { render '/layouts/index' }
        end
      end
  end
  
  def update_position
    new_position = params[:artwork].delete(:position)
    @artwork = Artwork.find(params[:id])
    respond_to do |format|
      if @artwork.update_attributes(params[:artwork])
        @artwork.move_to_position(new_position)
        flash[:success] = "#{@artwork.image_original_name}'s position updated"
        format.html { redirect_to "/artworks?artist_id=#{@artwork.artist_id}" }
        format.js { render '/layouts/index' }
      else
        flash[:error] = "#{@artwork.image_original_name}'s position not updated"
        format.html { redirect_to artworks_url }
        format.js { redirect_to "/artworks?artist_id=#{@artwork.artist_id}" }
      end
    end
  end

  def delete
    @artwork = Artwork.find(params[:id])
    respond_to do |format|
      format.html
      format.js
    end
  end

  def destroy
    @artwork = Artwork.find(params[:id])
    s3_delete(@artwork.image)
    @artist = Artist.find(@artwork.artist_id)
    @artwork.destroy
    @artwork.reset_position(@artist.id)
    
    respond_to do |format|
      flash[:success] = 'artwork removed'
      format.html { redirect_to artists_url(:artist_id => @artist.id) }
      format.js { render '/layouts/index' }
    end
  end
  
  def s3_download_image(image)
    image_hash = {
      :tmp_image_path =>  Rails.root.join('tmp/process'),
      :key =>  image.gsub('https://lott-reps-prod.s3.amazonaws.com/', ''),
    }
    
    image_name_arr = image_hash[:key].split('/')
    image_hash[:image_dir]  =  image_name_arr.first
    image_hash[:image_name]  =  image_name_arr.last
    image_hash[:image_path_local] = File.join(image_hash[:tmp_image_path], image_hash[:key])
    image_hash[:image_dir_local] = File.join(image_hash[:tmp_image_path], image_hash[:image_dir])
    
    s3_image = ArtworksObject.find(image_hash[:key])
        
    if s3_image
        FileUtils.mkdir_p(image_hash[:image_dir_local])
        File.chmod(0777, image_hash[:image_dir_local])
        File.open(image_hash[:image_path_local], 'a') do |f|
          f.write(s3_image.value.force_encoding('UTF-8')) 
      end
    end
    puts image_hash[:key]
    image_hash
  end
  
  def resize_image(img_obj, image_hash)    
    image_ext = File.extname(image_hash[:image_path_local]).downcase
    image = Magick::Image::read(image_hash[:image_path_local]).first

    dimensions = {
      :standard => ['600', '1125'],
      :retina => ['500', '938'],
      :thumb => ['1200', '2250'],
    }

    dimensions.each do |d|
      width = d[1][0]
      height = d[1][1]
      if d[0].to_s == "standard"
        key = image_hash[:key].gsub('jpeg', 'jpg')
        
        puts key
      elsif d[0].to_s == "retina"
        key = image_hash[:key].gsub("/", "/thumb-")
        puts key
      elsif d[0].to_s == "thumb"
        key = image_hash[:key].gsub(".jpg", "@2x.jpg")
        puts key
      end      
      
      new_local = File.join(image_hash[:tmp_image_path], key)
      local = image_hash[:image_path_local]
      
      # convert png to jpg
      if image_ext == ".png"
        image.format = "JPG"
        old_key = key
        key = key.gsub('png', 'jpg')
        local = local.gsub('png', 'jpg')
        converted_path = File.join('https://lott-reps-prod.s3.amazonaws.com/', key)
        puts converted_path
        img_obj.update_attribute(:image, converted_path)
        s3_delete(old_key)
      end
      
      # convert cmyk to rgb
      if image.colorspace == Magick::CMYKColorspace
        image.strip!
        image.add_profile("#{Rails.root}/lib/color_profiles/USWebCoatedSWOP.icc")
        image.colorspace == Magick::SRGBColorspace
        image.add_profile("#{Rails.root}/lib/color_profiles/AdobeRGB1998.icc")
      end
      
      # convert to 72 dpi
      image.density = "72"
      image.interlace = Magick::PlaneInterlace
      

      image.resize_to_fit!(width, height)
      image.write(new_local) { self.quality = 75 }
      File.chmod(0777, new_local)
      img = File.open(new_local, 'rb') {|file| file.read }
      ArtworksObject.store(key, img, :access => :public_read)
    end  
    
    image.destroy!
    FileUtils.rm_rf(image_hash[:image_dir_local])
  end
  
  def s3_upload(image_hash)
    File.chmod(0777, image_hash[:image_path_local])
    File.chmod(0777, image_hash[:thumb_path_local])
    img = File.open(image_hash[:image_path_local], 'rb') {|file| file.read }
    thumb = File.open(image_hash[:thumb_path_local], 'rb') {|file| file.read }
    s3_store(image_hash[:key], img)
    s3_store(image_hash[:thumb_key], thumb)
    FileUtils.rm_rf(image_hash[:image_dir_local])  
  end
  
  def s3_delete(image)
    img = image.gsub('https://lott-reps-prod.s3.amazonaws.com/', '')
    ArtworksObject.delete(img)
  end
  
  def marked_processed(image)
    image.update_attribute(:processed, '1')    
  end    
  
end
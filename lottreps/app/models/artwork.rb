class Artwork < ActiveRecord::Base
  attr_accessible :image, :name, :position, :artist_id, :thumb_position, :processed
  
  belongs_to :artist, counter_cache: true
  
  include PositionMover
  
  # extend FriendlyId
  # friendly_id :name, use: :slugged
    
  scope :artist_image, :conditions => {:position => 1}
  
  THUMB_POSITION = [['top','1'], ['middle','2'], ['bottom','3'], ['left','4'], ['right','5']]
  
  def artist_name
    if self.artist_id
      artist = Artist.find(self.artist_id)
      name = artist.name
      return name
    else
      return nil  
    end  
  end

  def image_original_name
    if self.image
      self.image = File.basename(self.image)
      self.image = self.image.gsub("thumb-", "")
      return image
    else
      return nil  
    end  
  end
    
  def default_position(artist_id)
    default_position = Artwork.where('artist_id = ?', artist_id).count + 1
    return default_position
  end
  
  def reset_position(artist_id)
    position_reset = 0
    @artworks = Artwork.order(:position).where('artist_id = ?', artist_id)
    @artworks.each do |artwork| 
      position_reset = position_reset + 1
      artwork.position = position_reset
      artwork.save!
    end  
  end  
  
  def crop_from
    if self.thumb_position == 1
      crop_from = "top"
    elsif self.thumb_position == 2
      crop_from = "middle"
    elsif self.thumb_position == nil
      crop_from = "middle"  
    elsif self.thumb_position == 3
      crop_from = "bottom"
    elsif self.thumb_position == 4
      crop_from = "left"
    elsif self.thumb_position == 5
      crop_from = "right"      
    end
    return "thumb-#{crop_from}"
  end 
  
  private
  
  def position_scope
    "artworks.artist_id = #{artist_id.to_i}"
  end
  
end

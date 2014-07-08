class Artist < ActiveRecord::Base
  attr_accessible :name, :position, :bio, :active, :image, :artist_type
  
  has_many :artworks
  
  extend FriendlyId
  friendly_id :name, use: :slugged  

  include PositionMover
  
  validates :name, :presence => true, :length => { :maximum => 50 }
  
  before_create :default_position
  #before_create :type
  
  def should_generate_new_friendly_id?
    new_record?
  end 
  
  def has_bio?   
    if self.bio.present?
      return '<i class="icon-ok"></i>'
    end
  end 
  
  def reset_position
    position_reset = 0
    @artists = Artist.order(:position)
    @artists.each do |artist| 
      position_reset = position_reset + 1
      artist.position = position_reset
      artist.save!
    end
  end
  
  # def type
  #   if self.artist_type == "Artist"
  #     self.artist_type = 1
  #   elsif self.artist_type == "Collection"
  #     self.artist_type = 2
  #   end  
  # end
  # 
  private
  
  def default_position
    self.position = Artist.all.count + 1
  end
  
end

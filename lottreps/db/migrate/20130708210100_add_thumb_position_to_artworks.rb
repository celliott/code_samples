class AddThumbPositionToArtworks < ActiveRecord::Migration
  def change
    add_column :artworks, :thumb_position, :integer
  end
  
  def down
    drop_column :artworks, :thumb_position
  end
end

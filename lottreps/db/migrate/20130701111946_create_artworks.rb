class CreateArtworks < ActiveRecord::Migration
  def change
    create_table :artworks do |t|
      t.string   :image
      t.string   :name
      t.integer  :position
      t.integer  :processed, :default => 0, :null => false
      t.integer  :artist_id
      
      t.timestamps
    end
    add_index :artworks, :artist_id
  end
  
  def down
    drop_table :artworks
  end
end

class CreateArtists < ActiveRecord::Migration
  def change
    create_table :artists do |t|
      t.string   :name
      t.integer  :position
      t.text     :bio, limit: 1200
      t.boolean  :active, :default => false
      
      t.timestamps
    end
  end
  
  def down
    drop_table :artists
  end
end

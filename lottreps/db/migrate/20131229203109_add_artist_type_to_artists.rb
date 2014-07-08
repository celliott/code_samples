class AddArtistTypeToArtists < ActiveRecord::Migration
  def change
    add_column :artists, :artist_type, :integer, null: false
  end
end

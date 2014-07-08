class AddArtworksCountToArtists < ActiveRecord::Migration
  def change
    add_column :artists, :artworks_count, :integer, default: 0, null: false
  end
end

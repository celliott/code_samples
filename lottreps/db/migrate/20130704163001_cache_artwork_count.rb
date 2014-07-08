class CacheArtworkCount < ActiveRecord::Migration
  def up
    execute "update artists set artworks_count=(select count(*) from artworks where artist_id=artists.id)"
  end

  def down
  end
end
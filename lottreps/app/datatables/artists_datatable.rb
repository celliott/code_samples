# borrowed code from Ryan Bates' railscast #340

class ArtistsDatatable
  delegate :params, :cookies, :h, :link_to, :content_tag, :form_for, :artists_admin, :artist_type, :artist_count, :collection_select, :like_path, :image_tag, :artwork_count, :truncate, to: :@view

  def initialize(view)
    @view = view
    @artist_count =  Artist.where('artist_type = ?', "#{params[:artist_type]}").count
  end

  def as_json(options = {})
    {
      sEcho: params[:sEcho].to_i,
      iTotalRecords: @artist_count,
      iTotalDisplayRecords: artists.total_entries,
      aaData: data
    }
  end

private

  def data
    artists.map do |artist|
      [
        form_for(artist, :remote => true, :url => "/admin/artists/#{artist.id}/update_position", 
        :method => (:put)) do |f|  
          f.select(:position, 
            ((1..@artist_count).map {|i| [i,i] }), 
            {:prompt => false, :selected => artist.position}, 
            {:class => 'input-mini', :onchange => 'this.form.submit();'})
        end,
        "<p class='table-text'>#{artist.name}</p>",
        "<p class='table-text icon'>#{artist.artworks.size}</p>",
        "<p class='table-text icon'>#{artist.has_bio?}</p>",
        if !artist.name.include?('placeholder')
          link_to("images", "/admin/artworks/?artist_id=#{artist.id}", 
            :class => "btn btn-link"
          )
        end,
        if !artist.name.include?('placeholder')
          link_to("info", {
            :controller => :artists_admin, 
            :action => :edit, 
            :id => artist.id
            }, 
            :remote => true, 
            data: { 
              toggle: 'modal',
              target: '#modal-window' 
            },
            :class => "btn btn-link"
          )
        end,
        link_to("delete", {
          :controller => :artists_admin, 
          :action => :delete, 
          :id => artist.id
          }, 
          :remote => true, 
          data: { 
            toggle: 'modal',
            target: '#modal-window' 
          },
          :class => "btn btn-link delete-btn"
        )
      ]
    end
  end

  def artists
    @artists ||= fetch_artists
  end

  def fetch_artists
    artists = Artist.where('artist_type = ?', "#{params[:artist_type]}").order("#{sort_column} #{sort_direction}")
    artists = artists.page(page).per_page(per_page)
    if params[:sSearch].present?
      artists = artists.where(
        "artists.name like :search
        or artists.bio like :search", 
        search: "%#{params[:sSearch]}%"
      )
    end
    artists
  end

  def page
    params[:iDisplayStart].to_i/per_page + 1
  end

  def per_page
    params[:iDisplayLength].to_i > 0 ? params[:iDisplayLength].to_i : 10
  end

  def sort_column
    columns = %w[position name images bio]
    columns[params[:iSortCol_0].to_i]
  end

  def sort_direction
    params[:sSortDir_0] == "desc" ? "desc" : "asc"
  end
end
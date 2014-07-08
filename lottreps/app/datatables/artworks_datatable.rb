# borrowed code from Ryan Bates' railscast #340

class ArtworksDatatable
  delegate :params, :h, :link_to, :form_for, :content_tag, :artworks_path, :collection_select, :image_tag, :truncate, to: :@view

  def initialize(view)
    @view = view
    @artworks_count = Artwork.where('artist_id = ?',params[:artist_id]).count
  end

  def as_json(options = {})
    {
      sEcho: params[:sEcho].to_i,
      iTotalRecords: @artworks_count,
      iTotalDisplayRecords: artworks.total_entries,
      aaData: data
    }
  end

private

  def data
    
    artworks.map do |artwork|
      [
        form_for(artwork, 
        :remote => true, 
        :url => "/artworks/#{artwork.id}/update_position", 
        :method => (:put)) do |f|  
          f.select(:position, 
            ((1..@artworks_count).map {|i| [i,i] }), 
            {:prompt => false, :selected => artwork.position}, 
            {:class => 'input-mini', :onchange => 'this.form.submit();'})
        end,
        content_tag(:div, 
          link_to( image_tag(artwork.image, :class => 'artwork-thumb-link'), 
          artwork.image, 
          :data => { 
          	:colorbox => true, 
          	:colorbox_max_height => '95%', 
          	:colorbox_max_width => '600px'
          }),
            :class => "artwork-thumb #{artwork.crop_from}",
            :style => "background-image:url('#{artwork.image}')"
        ),  
        artwork.image_original_name,
        form_for(artwork, :remote => true, :url => "/artworks/#{artwork.id}", 
        :method => (:put)) do |f|  
          f.select :thumb_position, 
            Artwork::THUMB_POSITION, 
            {:prompt => false, :selected => artwork.thumb_position}, 
            {:class => 'input-small', :onchange => 'this.form.submit();'}
        end,
        link_to("delete", {
          :controller => :artworks, 
          :action => :delete, 
          :id => artwork.id
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

  def artworks
    @artworks ||= fetch_artworks
  end

  def fetch_artworks
    artworks = Artwork.order("#{sort_column} #{sort_direction}").where('artist_id = ?', params[:artist_id])
    artworks = artworks.page(page).per_page(per_page)
    artworks.each do |a|
      if a.processed == 1
        bucket_path = "https://lott-reps-prod.s3.amazonaws.com/"
        path = a.image
        path = path.gsub(bucket_path, "")
        path = path.gsub("/", "/thumb-")
        a.image = File.join(bucket_path, path)
      end
    end
    if params[:sSearch].present?
      artworks = artworks.where(
        "artworks.image like :search", 
        search: "%#{params[:sSearch]}%"
      )
    end
    artworks
  end

  def page
    params[:iDisplayStart].to_i/per_page + 1
  end

  def per_page
    params[:iDisplayLength].to_i > 0 ? params[:iDisplayLength].to_i : 10
  end

  def sort_column
    columns = %w[position image image thumb_position ]
    columns[params[:iSortCol_0].to_i]
  end

  def sort_direction
    params[:sSortDir_0] == "desc" ? "desc" : "asc"
  end
end
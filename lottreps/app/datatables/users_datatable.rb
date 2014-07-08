# borrowed code from Ryan Bates' railscast #340

class UsersDatatable
  delegate :params, :h, :link_to, to: :@view

  def initialize(view)
    @view = view
  end

  def as_json(options = {})
    {
      sEcho: params[:sEcho].to_i,
      iTotalRecords: User.count,
      iTotalDisplayRecords: users.total_entries,
      aaData: data
    }
  end

private

  def data
    users.map do |user|
      [
        user.first_name+' '+user.last_name,
        link_to("edit", {
          :controller => :users, 
          :action => :edit, 
          :id => user.id
          }, 
          :remote => true, 
          data: { 
            toggle: 'modal',
            target: '#modal-window' 
          },
          :class => "btn btn-mini btn-primary"
        ),
        link_to("delete", {
          :controller => :users, 
          :action => :delete, 
          :id => user.id
          }, 
          :remote => true, 
          data: { 
            toggle: 'modal',
            target: '#modal-window' 
          },
          :class => "btn btn-mini btn-danger"
        )
      ]
    end
  end

  def users
    @users ||= fetch_users
  end

  def fetch_users
    users = User.order("#{sort_column} #{sort_direction}")
    users = users.page(page).per_page(per_page)
    if params[:sSearch].present?
      users = users.where(
        "users.first_name like :search 
        or users.last_name ilike :search", 
        search: "%#{params[:sSearch]}%"
      )
    end
    users
  end

  def page
    params[:iDisplayStart].to_i/per_page + 1
  end

  def per_page
    params[:iDisplayLength].to_i > 0 ? params[:iDisplayLength].to_i : 10
  end

  def sort_column
    columns = %w[last_name ]
    columns[params[:iSortCol_0].to_i]
  end

  def sort_direction
    params[:sSortDir_0] == "desc" ? "desc" : "asc"
  end
end
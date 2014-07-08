# borrowed code from Ryan Bates' railscast #340

class OrdersDatatable
  delegate :params, :h, :link_to, :content_tag, :form_for, :order_count, :collection_select, :like_path, :image_tag, :truncate, to: :@view

  def initialize(view)
    @view = view
    @order_count = Order.count
  end

  def as_json(options = {})
    {
      sEcho: params[:sEcho].to_i,
      iTotalRecords: @order_count,
      iTotalDisplayRecords: orders.total_entries,
      aaData: data
    }
  end

private

  def data
    orders.map do |order|
      [
        order.status,
        link_to(order.order_number, {
          :controller => :orders, 
          :action => :show, 
          :id => order.order_number
          }, 
          :class => "btn btn-mini btn-success"
        ),
        order.ship_to_first_name + " " + order.ship_to_last_name,
        order.order_created.strftime("%m/%d/%Y"),
        order.item_count,
      ]
    end
  end

  def orders
    @orders ||= fetch_orders
  end

  def fetch_orders
    orders = Order.order("#{sort_column} #{sort_direction}")
    orders = orders.page(page).per_page(per_page)
    if params[:sSearch].present?
      begin  
        start_date = "%#{DateTime.strptime(params[:sSearch], '%m/%d/%Y')}%"
        end_date = "%#{(DateTime.strptime(params[:sSearch], '%m/%d/%Y') + 1.day)}%"
      rescue
      end  
      orders = orders.where(
        "orders.order_number ilike :search
        or orders.status ilike :search
        or order_created between :date_search_start and :date_search_end
        or orders.ship_to_full_name ilike :search", 
        search: "%#{params[:sSearch]}%",
        date_search_start: start_date,
        date_search_end: end_date
      )
    end
    orders
  end

  def page
    params[:iDisplayStart].to_i/per_page + 1
  end

  def per_page
    params[:iDisplayLength].to_i > 0 ? params[:iDisplayLength].to_i : 10
  end

  def sort_column
    columns = %w[status order_number ship_to_full_name order_created item_count]
    columns[params[:iSortCol_0].to_i]
  end

  def sort_direction
    params[:sSortDir_0] == "desc" ? "desc" : "asc"
  end
end
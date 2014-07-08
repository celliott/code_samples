class OrdersController < ApplicationController  
  require 'actionpack/action_caching'
  
  before_filter :confirm_logged_in
  caches_action :show, :layout => false
  helper_method :generate_secure_s3_url
  
  def index
    respond_to do |format|
      format.html
      format.json { render json: OrdersDatatable.new(view_context) }
    end
  end
  
  def show
    @order = Order.find_by_order_number(params[:id])
    @items = @order.items.order("item_number")
    path = '/orders'
    order_number = @order.order_number

    if @order.status != "SH"
      path = '/orders'
      order_hash = get_order(path, @order.order_number)
      @order.status = order_hash[:status]
      @order.update_attribute(:status, order_hash[:status])
    end 
    
    if @order.status == "TR"
      @status_desc = 'Transferred to printer, not yet in process'
    elsif @order.status == "IP"
      @status_desc = 'In-process at printer'
    elsif @order.status == "SH"
      @status_desc = 'Shipped to customer'
    elsif @order.status == "CA"
      @status_desc = 'Manually cancelled'
    else 
      @status_desc = ""  
    end
 
  end
  
  def create
    Order.create!(params.require(:order_number).permit(:status, :item_count, :ship_method, :ship_to_full_name, :ship_to_first_name, :ship_to_last_name, :ship_to_company, :ship_to_addr1, :ship_to_addr2, :ship_to_city, :ship_to_state, :ship_to_zip, :ship_to_phone, :order_created))
  end
    
    def generate_secure_s3_url(s3_key)
      bucket            = ENV['S3_BUCKET'] 
      s3_base_url       = "http://#{bucket}.s3.amazonaws.com"
      access_key_id     = ENV['S3_KEY']
      secret_access_key = ENV['S3_SECRET']
      expiration_date   = 1.days.from_now.utc.to_i
      string_to_sign = "GET\n\n\n#{expiration_date}\n/#{bucket}/#{s3_key}".encode("UTF-8")
      signature = CGI.escape(Base64.encode64(
                              OpenSSL::HMAC.digest(
                                  OpenSSL::Digest::Digest.new('sha1'),
                                  secret_access_key, string_to_sign)).gsub("\n",""))
      return "#{s3_base_url}/#{s3_key}?AWSAccessKeyId=#{access_key_id}&Expires=#{expiration_date}&Signature=#{signature}"
    end
    
end

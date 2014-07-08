class ProcessOrdersController < ApplicationController
  require 'csv'
  require 'zip'
  require 'aws/s3'
  
  before_filter :confirm_logged_in
  
  def create
    check_for_new_orders
    if @count > 0
      flash[:notice] = "#{@count} New Order(s)"
    else
      flash[:notice] = "No New Orders"
    end    
    redirect_to orders_url
  end    
  
  def check_for_new_orders
    begin
      first_order_number = Order.last.order_number #if Rails.env.production?
    rescue
      first_order_number = ""
    end
    
    if first_order_number == ""
      first_order_number = "131114000000"
      first_order_number = "131114000000" if Rails.env.development?
    end

    @process_new_orders = s3_search(first_order_number)
    @count = 0
    @process_new_orders.each do |order|
      if !Order.find_by_order_number(order) && order > first_order_number
        @count = @count+ 1
        s3_download_order(order)
        process_order(order)
        cleanup(order)
      end  
    end
    update_order
  end  
  
  def s3_search(first_order_number)
    processed_orders = []
    OrdersBucket.objects(:marker => "processed/#{first_order_number}").each do |object|
      regex = /\d+{1}\//i
      object_data = object.key.match regex
      processed_orders << object_data.to_s.gsub("/", '')
    end  
    processed_orders.uniq.reject{ |e| e.empty? }
  end  
  
  def s3_download_order(order_number)
    tmp_zip_path = Rails.root.join('tmp/orders', order_number)
    zip_path = File.join("processed/", order_number, "processed_#{order_number}.zip")
    zip_path_local = File.join(tmp_zip_path, "processed_#{order_number}.zip")
    s3_order = OrdersObject.find(zip_path)
    if s3_order
        FileUtils.mkdir_p(tmp_zip_path)
        File.chmod(0777, tmp_zip_path)
        File.open(zip_path_local, 'a') do |f|
          f.write(s3_order.value.force_encoding('UTF-8')) 
          break
      end
    end
  end    
    
  def process_order(order_number)
    tmp_path = Rails.root.join('tmp/orders')
    order_path = File.join(tmp_path,order_number)
    zip_path = File.join(order_path,"processed_#{order_number}.zip")    
    unzip_order(zip_path, order_path)
    csv_count = Dir[File.join(order_path,"*.csv")].length
    csv_count.times do |i|
       item = i+1
       csv_path = File.join(order_path,"#{order_number}.#{item}.csv")
       parse_csv(csv_path)
    end
  end
  
  def unzip_order(zip_path, order_path)
    Zip::File.open(zip_path) do |zipfile|
      zipfile.each do |f|
        f_path=File.join(order_path, f.name)
        zipfile.extract(f, f_path) unless File.file?(f_path)
      end
    end
  end
  
  def parse_csv(csv_path)
    csv_text = File.read(csv_path)
    csv = CSV.parse(csv_text, :headers => true)
    csv.each do |row|
      @item = row.to_hash.symbolize_keys
    end
    ship_to_full_name = "#{@item[:ShipToFirstName]} #{@item[:ShipToLastName]}"
    @order_hash = {
      :order_number => @item[:OrderNum], 
      :ship_method => @item[:ShipMethod], 
      :ship_to_full_name => ship_to_full_name,
      :ship_to_first_name => @item[:ShipToFirstName], 
      :ship_to_last_name => @item[:ShipToLastName], 
      :ship_to_company => @item[:ShipToCompany], 
      :ship_to_addr1 => @item[:ShipToAddr1], 
      :ship_to_addr2 => @item[:ShipToAddr2], 
      :ship_to_city => @item[:ShipToCity], 
      :ship_to_state => @item[:ShipToState], 
      :ship_to_zip => @item[:ShipToZip], 
      :ship_to_phone => @item[:ShipToPhone], 
    }    
    order = Order.find_or_create_by_order_number(@order_hash)
    
    @item_hash = {
      :order_id => order.id,
      :item_number => @item[:ItemNum], 
      :file_1 => @item[:File1], 
      :file_2 => @item[:File2], 
      :product_code => @item[:ProductCode], 
      :product_name => @item[:ProductName], 
      :quantity => @item[:Quantity], 
      :paper => @item[:Paper], 
      :trim_size => @item[:TrimSize], 
      :final_size => @item[:FinalSize], 
      :score => @item[:Score], 
      :color_process => @item[:ColorProcess], 
      :pick_out_item => @item[:PickOutItem], 
      :uv_coating => @item[:UVCoating], 
      :drill => @item[:Drill]
    }
    Item.find_or_create_by_file_1(@item_hash)
    
    if Rails.env.production?
      s3_upload(@order_hash[:order_number], @item_hash[:file_1])
      if @item_hash[:file_2] != "none"
        s3_upload(@order_hash[:order_number], @item_hash[:file_2])
      end  
    end
      
    if order.status != "SH"
      path = '/orders'
      order_hash = get_order(path, @order_hash[:order_number])
      order.update_attribute(:status, order_hash[:status])
    end
    order.update_attribute(:item_count, order.items.size)
  end

  def s3_upload(order_number, file)
    tmp_path = Rails.root.join('tmp/orders')
    img_path = File.join(tmp_path, order_number, file)
    s3_img_path = File.join('orderviewer', order_number, file)
    File.chmod(0777, img_path)
    img = File.open(img_path, 'rb') {|file| file.read }
    exists = 0
    begin
      OrdersObject.find(s3_img_path)
      exists = 1
    rescue
      exists = 0
    end    
    if exists == 0
      OrdersObject.store(s3_img_path, img)
    end  
  end  

  def cleanup(order_number)
    tmp_path = Rails.root.join('tmp/orders')
    tmp_order_path = File.join(tmp_path, order_number)
    FileUtils.rm_rf(tmp_order_path)
  end  

  def update_order
    active_orders = Order.where.not(status: 'SH')
    active_orders.each do |order|
      path = '/orders'
      order_hash = get_order(path, order.order_number)
      order.update_attribute(:status, order_hash[:status])
    end
    active_orders = Order.where("date_processed = 'FALSE'")
    active_orders.each do |order|
      path = '/orders'
      order_hash = get_order(path, order.order_number)
      order.update_attribute(:order_created, order_hash[:order_created])
      order.update_attribute(:date_processed, TRUE)
    end
  end  

end

#!/usr/bin/ruby

# dependencies
# gem install rest-client
# gem install json
# gem install aws-s3
# gem install xml-simple
# gem install builder
# gem install mime-types
# gem install rmagick
# gem install rubyzip

require 'rubygems'
require 'digest'
require 'net/ftp'
require 'csv'
require 'fileutils'
require 'zip'
require 'pathname'
require 'rest-client'
require 'json'
require 'aws/s3'
require 'RMagick'
require 'date'
require File.join(File.dirname(__FILE__), 'settings_handler.rb')


class ProcessHandler
  
  # create $CONFIG from settings.rb
  def initialize
  	SettingsHandler.new
  end
  
  
  # checks for running processes and free memory and exits if needed
  def checkAvailableResources
  	running_count = `sudo ps cax | grep -E "process_order.r" | wc -l`
  	free_memory = `free -t | grep Mem | awk '{print $2}'`
		
		#puts "- processes already running: #{running_count}"
		puts " "

  	if running_count.to_i > $CONFIG[:processes]
			puts "script not run, #{($CONFIG[:processes])} processes are already running"
			exit
		end
		
		if free_memory.to_i < 140000
			puts "available memory: #{free_memory}"
	  	puts 'script not run: not enough available memory'
			exit
		end
  end
  
  
#   # checks for running processes and exits if already running
# 	def checkPendingEmailsIsRunning
# 		running_count = `sudo ps cax | grep -E "pending_emails.rb" | wc -l`
# 		if running_count.to_i > 0
# 			puts 'quitting, check pending_emails is already running'
# 			exit
# 		end
# 	end
	
  
  # enable stress mode if 'stress' passed as arg or if zip_file_name = 'stress.zip'
  def stressMode(args, order_hash)
  	args.each do|a|
		  order_hash[:mode] = a
			break
		end
	  if order_hash[:mode] == 'stress' || order_hash[:image_zip_file].downcase == 'stress.zip'
			order_hash[:mode] = 'stress'
			$CONFIG[:ftp_server] = $CONFIG[:ftp_server_stress].to_s
			$CONFIG[:ftp_user] = $CONFIG[:ftp_user_stress].to_s
			$CONFIG[:ftp_pass] = $CONFIG[:ftp_pass_stress].to_s
		end
  end
  
  
  # builds auth path for api calls
  def apiAuth
  	signature = "version=#{$CONFIG[:api_version]}&path=#{$CONFIG[:api_path]}&app_key=#{$CONFIG[:app_key]}&app_secret=#{$CONFIG[:app_secret]}&timestamp=#{$CONFIG[:timestamp]}"
  	signature_hash = Digest::SHA2.new << signature
  	url = "#{$CONFIG[:api_url]}#{$CONFIG[:api_version]}#{$CONFIG[:api_path]}?app_key=#{$CONFIG[:app_key]}&timestamp=#{$CONFIG[:timestamp]}&signature=#{signature_hash}"
  
  	url
	end
  
  
  # gets the next pending order from api and creates order_hash
  def getNextPendingOrder(status_hash)
    $CONFIG[:api_path] +='/next_pending_order'
    new_order_hash = Hash.new
    response = RestClient.get(apiAuth, {:accept => :json})
    
    if response.to_s.include?('{"meta":{"status":200,"msg":"OK"}')
    	new_order_hash = JSON.parse(response)
    	new_order = new_order_hash["response"]["order"]["order_number"]
    	status_hash[:msg] = "order: #{new_order} received"
    	$LOG.info(status_hash[:msg])
    	puts status_hash[:msg]
  	else
  		status_hash[:status] = 1
    	status_hash[:msg] = 'no new orders'
    	puts status_hash[:msg]
    	$LOG.info(status_hash[:msg])
    	exit
  	end
		
		order_hash = {
  		:order_number					=>  new_order_hash["response"]["order"]["order_number"].to_s,
    	:order_number 				=> 	new_order_hash["response"]["order"]["order_number"],
    	:image_zip_file 			=> 	new_order_hash["response"]["order"]["image_zip_file"].to_s,
    	:status_email 				=> 	$CONFIG[:status_email],
    	:ship_option 					=> 	new_order_hash["response"]["order"]["ship_option"],
    	:ship_to_first_name 	=> 	new_order_hash["response"]["order"]["ship_to_first_name"],
    	:ship_to_last_name 		=> 	new_order_hash["response"]["order"]["ship_to_last_name"],
    	:customer_first_name 	=> 	new_order_hash["response"]["order"]["customer_first_name"],
    	:customer_first_name 	=>	new_order_hash["response"]["order"]["customer_first_name"],
    	:customer_last_name 	=> 	new_order_hash["response"]["order"]["customer_last_name"],
    	:customer_email 			=> 	new_order_hash["response"]["order"]["customer_email"],
    	:ship_to_company 			=> 	new_order_hash["response"]["order"]["ship_to_company"],
    	:ship_to_addr1 				=> 	new_order_hash["response"]["order"]["ship_to_addr1"],
    	:ship_to_addr2 				=> 	new_order_hash["response"]["order"]["ship_to_addr2"],
    	:ship_to_city 				=> 	new_order_hash["response"]["order"]["ship_to_city"],
    	:ship_to_state 				=> 	new_order_hash["response"]["order"]["ship_to_state"],
    	:ship_to_zip 					=> 	new_order_hash["response"]["order"]["ship_to_zip"],
    	:ship_to_phone 				=> 	new_order_hash["response"]["order"]["ship_to_phone"],
    	:items         				=> 	new_order_hash["response"]["order"]["items"]
    }
    order_hash
  end
  
  
  # call api /next_cancelled_order and return cancelled_order_hash
  def getNextCancelledOrder(status_hash)
  	$CONFIG[:api_path] +='/next_cancelled_order'
  	
    begin
    	response = RestClient.get(apiAuth)
		rescue
			status_hash[:status] = 1
    	status_hash[:msg] = "couldn't connect to api"
		end

  	if response.to_s.include?('{"meta":{"status":200,"msg":"OK"}')
    	tmp_order_hash = JSON.parse(response)
    	status_hash[:status] = 0
    	status_hash[:msg] = 'cancelled order received'
  	else
  		status_hash[:status] = 1
    	status_hash[:msg] = 'no cancelled orders'
    	puts status_hash[:msg]    	
    	exit
  	end
  	
  	order_hash = {
  		:order_number 				=> 	tmp_order_hash["response"]["order"]["order_number"].to_s,
			:customer_first_name 	=> 	tmp_order_hash["response"]["order"]["customer_first_name"],
			:customer_last_name 	=> 	tmp_order_hash["response"]["order"]["customer_last_name"],
			:customer_email 			=> 	tmp_order_hash["response"]["order"]["customer_email"],
			:status 							=> 	tmp_order_hash["response"]["order"]["status"]
  	}
		order_hash
  end
  
  
  # call api /pending_emails
	def getPendingEmails(status_hash)
		$CONFIG[:api_path] ='/pending_emails'
		
	  begin
	  	response = RestClient.get(apiAuth)
		rescue
			status_hash[:status] = 1
	  	status_hash[:msg] = "couldn't connect to api"
		end
	
		if response.to_s.include?('{"meta":{"status":200,"msg":"OK"}')
			tmp_email_hash = JSON.parse(response)
		end

		tmp_email_hash["response"]["pending_emails"] #if tmp_email_hash["response"]["pending_emails"] != ""
	end
	
  
  # posts the order status to API
  def postStatustoAPI(order_hash, status_hash)
  	$CONFIG[:api_path] = "/orders/update_status"
  	tmp_order_hash = Hash.new
  	tracking_number = order_hash[:tracking_number].to_s
  	status_detail = status_hash[:msg]

  	update_status_hash = {
  		:order_number			=>	order_hash[:order_number],
  		:status						=>	order_hash[:status]
  	}
  	
  	if status_hash[:status] == 0 || order_hash[:status] == 'TR'
  		status_detail = ""
  	end
  	
  	if order_hash[:status] == 'PF'
  		status_detail = order_hash[:status_detail]
  	end
    
    update_status_hash[:status_detail] = ""   
    update_status_hash[:status_detail] = status_detail if status_detail != ''
    update_status_hash[:tracking_number] = tracking_number if tracking_number != ''

    payload = 'payload='+JSON.generate(update_status_hash)

    begin
    	response = RestClient.post(apiAuth, payload, :accept => :json)
    rescue => e
    	status_hash[:status] = 1
    	order_hash[:api_status] = 1
    	status_hash[:msg] = "couldn't connect to api"
    	puts "api msg: #{e}"
    end	
    
    sleep 2

    if response.to_s.include?('{"meta":{"status":200,"msg":"OK"}')
    	tmp_order_hash = JSON.parse(response)
    	order_hash[:order_number] = tmp_order_hash["response"]["order"]["order_number"].to_s
			order_hash[:customer_first_name] = tmp_order_hash["response"]["order"]["customer_first_name"]
			order_hash[:customer_last_name] = tmp_order_hash["response"]["order"]["customer_last_name"]
			order_hash[:ship_to_first_name] = tmp_order_hash["response"]["order"]["ship_to_first_name"]
			order_hash[:ship_to_last_name] = tmp_order_hash["response"]["order"]["ship_to_last_name"]
			order_hash[:ship_to_company] = tmp_order_hash["response"]["order"]["ship_to_company"]
			order_hash[:customer_email] = tmp_order_hash["response"]["order"]["customer_email"]
			order_hash[:status] = tmp_order_hash["response"]["order"]["status"]
			order_hash[:ship_option] = tmp_order_hash["response"]["order"]["ship_option"]
			order_hash[:ship_to_addr1] = tmp_order_hash["response"]["order"]["ship_to_addr1"]
			order_hash[:ship_to_addr2] = tmp_order_hash["response"]["order"]["ship_to_addr2"]
			order_hash[:ship_to_city] = tmp_order_hash["response"]["order"]["ship_to_city"]
			order_hash[:ship_to_state] = tmp_order_hash["response"]["order"]["ship_to_state"]
			order_hash[:ship_to_zip] = tmp_order_hash["response"]["order"]["ship_to_zip"]
  	else
  		status_hash[:status] = 1
    	order_hash[:api_status] = 1
    	response = "api not updated"
  	end
  	puts "api response: #{response}"
  end
  
  
  # creates item_hash from each item
  def createItemHash(item, order_hash, status_hash)
    item_hash = Hash.new
    
    base_file_name = "#{order_hash[:order_number]}.#{item["item_number"]}"
    item_hash = {
    	:file_1 					=> 	"#{base_file_name}.A.jpg",
    	:file_2						=> 	"#{base_file_name}.B.jpg",
	    :s3_file_1 				=> 	item["image_file_id"].to_s+'_print_front.jpg',
	    :s3_file_2 				=> 	item["image_file_id"].to_s+'_print_reverse.jpg',
	    :item_number 			=> 	item["item_number"],
	    :product_code 		=> 	item["product_code"].to_s,
	    :product_desc 		=> 	item["product_desc"].to_s,
	    :quantity 				=> 	item["quantity"],
	    :paper 						=> 	item["paper"],
	    :trim_size 				=> 	item["trim_size"],
	    :final_size 			=> 	item["final_size"],
	    :score						=>	item["score"],
	    :color_process 		=> 	item["color_process"],
	    :pick_out_item 		=> 	item["pick_out_item"],
	    :uv_coating 			=> 	item["uv_coating"],
	    :drill 						=> 	item["drill"]
    }

    if item_hash 
    	status_hash[:msg] = "item_hash for #{order_hash[:order_number]} has been created"
    else
    	status_hash[:status] = 1
    	status_hash[:msg] = "couldn't create item_hash"
    end

    item_hash
  end 	
  
  
  # gets order status from the email subject
	def orderStatusFromSubject(order_hash, status_hash)
		
		if status_hash[:status] == 0
			subject = order_hash[:subject].downcase.to_s
					
			order_hash[:status] = subject.match(/^\S+/).to_s
			
			full_order_number = subject.match(/\s*#{order_hash[:status]}\s+\S+/).to_s.gsub("#{order_hash[:status]}", '').lstrip!.split('.')
			
			if order_hash[:status] == 'start'
				order_hash[:status] = 'IP'
			elsif order_hash[:status] == 'complete'
				order_hash[:status] = 'SH'
			elsif order_hash[:status] == 'error'
				order_hash[:status] = 'PF'
			end
			
			
			order_hash[:order_number] = full_order_number[0].to_s
			if full_order_number[1]
			  order_hash[:item_number] = full_order_number[1]
			end
						
						
			if !is_number?(order_hash[:order_number])
				order_hash[:order_number] = nil
			end			
						
						
			order_hash[:shipper] = 'FDX'
			
			shipping_types = [
				"ground", 
				"3 day", 
				"2 day", 
				"2nddayair", 
				"3dayselect",
				"nextdayair",
				"nextdayairsaver",
				"overnight",
				"overnight standard" 
			]
			
			shipping_types.each do |type|
			  if subject.match(/\s*#{type}\s+\S+/)
			    order_hash[:tracking_number] = subject.match(/\s*#{type}\s+\S+/).to_s.gsub("#{type}", '').lstrip!	
			    order_hash[:ship_method] = subject.match(/\s*#{type}\s+\S+/).to_s.gsub("#{order_hash[:tracking_number]}", '').lstrip!.chomp(' ')		
			  end 
			end
			
			if subject.match(/\s*error\s+\S+/)
			  remove = subject.match(/\s*error\s+\S+/).to_s
			  order_hash[:status_detail] = subject.to_s.gsub(remove, '').lstrip!
			else
				order_hash[:status_detail] = ""  
			end
	
			if order_hash[:status] != nil
				status_hash[:msg] = 'email status has been parsed'
			else
				status_hash[:status] = 1
				status_hash[:msg] = 'email status was not parsed'
			end	
		end			
		
	end
	
	
	def is_number?(object)
  	true if Float(object) rescue false
	end

	
		
	#checks if order update have order_number and if status == SH, then it must have a tracking number and ship method
	def update_ok?(order_hash)
		if !order_hash[:order_number]
			return false
		elsif order_hash[:status] == 'SH' 
				return true unless order_hash[:tracking_number] == nil || order_hash[:ship_method] == nil
		else
			return true
		end	
	end
  
  # connects to s3 bucket and returns bucket name
  def s3Connect(status_hash)
  	status_hash[:s3_msg] = 'not connected'
    AWS::S3::Base.establish_connection!(
      :access_key_id     => $CONFIG[:aws_key], 
      :secret_access_key => $CONFIG[:aws_secret]
    )
    
    status_hash[:s3_msg] = 'connected'
    puts "s3: #{status_hash[:s3_msg]}"
  end  
  
  
  # s3 image download
  def s3Download(order_hash, status_hash)        
    self.s3Connect(status_hash)
    order_number = order_hash[:order_number]
    zip = order_hash[:image_zip_file]
    tmp_path = File.join(File.dirname(__FILE__), 'orders', order_number)
    
    tmp_zip_path = File.join(tmp_path, zip)
    
    #create tmp path for working directory
    FileUtils.mkdir_p(tmp_path)
    status_hash[:s3_process_bucket] = 'none'
    $CONFIG[:aws_buckets].each do |s3_bucket|
    	if s3_bucket == 'is.happy.makr.orders'
    		zip_path = zip
    	else
    		zip_path = File.join('orders/new/', zip)
    	end
 
    	begin
    		s3_image = AWS::S3::S3Object.find(zip_path, s3_bucket)
    		status_hash[:msg] = 'images found on s3'
    		status_hash[:s3_status] = 1 # success
    	rescue AWS::S3::NoSuchKey
    		status_hash[:status] = 1
  			status_hash[:msg] = 'unable to find zip file on s3'
  			status_hash[:s3_status] = 0 # failure
  		rescue AWS::S3::AccessDenied
    		status_hash[:status] = 1
  			status_hash[:msg] = 'unable to connect to s3'
  			status_hash[:s3_status] = 0 # failure	
    	end
			
			if s3_image
	    	File.open(tmp_zip_path, 'a') do |f|
	  			f.write(s3_image.value) 
	  			break
				end
			end
			    	
    	if status_hash[:status] == 0	
    		status_hash[:s3_process_bucket] = s3_bucket
				begin
				# unzip downloaded file
				Zip::File.open(tmp_zip_path) do |zipfile|
				  zipfile.each do |f|
				    f_path=File.join(tmp_path, f.name)
				    FileUtils.mkdir_p(File.dirname(f_path))
				    zipfile.extract(f, f_path) unless File.file?(f_path)
				  end
				end

	    	rescue (TypeError)
	    		return nil
	    	end
	    	
	    	# remove downloaded zip file
	    	FileUtils.rm(tmp_zip_path)
			end			
		end
  end  
  
  
  #up res the images to 300 dpi
  def upRes(file_path)  
  	original_image = Magick::Image.read(file_path) { self.density = "300.0x300.0" }
		original_image.each do |image|
		   image = image.resample(300.0, 300.0)
		   image.write(file_path) { self.quality = 100 }
		end
  end
  
  
  # uploads original images to s3
	def uploadOriginalImagesToS3(image_path, image_name, order_number, status_hash)
		self.s3Connect(status_hash)
    s3_bucket = $CONFIG[:s3_original_bucket]
  	tmp_path = File.join(File.dirname(__FILE__), 'orders', order_number)
		
		begin
    	s3_obj_store = AWS::S3::S3Object.store(image_name, open(image_path), s3_bucket)
    	status_hash[:status] = 0
    	status_hash[:msg] = "original image upload to s3"
    	$LOG.info("order_number: #{order_number}")
    	$LOG.info("s3_bucket: #{s3_bucket}")
    	$LOG.info("image_name: #{image_name}")
    	$LOG.info("image_path: #{image_path}")
    	$LOG.info("s3_obj_store: #{s3_obj_store}")
    	$LOG.info(status_hash[:msg])
    rescue => e
    	$LOG.info("uploadOriginalImagesToS3 error: #{e}")
    end		
	end
  
  
  # rename downloaded images
  def renameImages(order_hash, item_hash, status_hash)
  	order_number = order_hash[:order_number]
  	tmp_path = File.join(File.dirname(__FILE__), 'orders', order_number)
    file_1_path = File.join(tmp_path, item_hash[:file_1])
  	s3_file_1_path = File.join(tmp_path, item_hash[:s3_file_1])    
    file_2_path = File.join(tmp_path, item_hash[:file_2])
    s3_file_2_path = File.join(tmp_path, item_hash[:s3_file_2])
  	
  	if File.exist?(s3_file_1_path)
  		uploadOriginalImagesToS3(s3_file_1_path, item_hash[:s3_file_1], order_number, status_hash)
  		FileUtils.copy(s3_file_1_path, file_1_path)
  		upRes(file_1_path)
  		if File.exist?(file_1_path)
  			status_hash[:status] = 0
  			status_hash[:msg] = "local files renamed"
  		else
  			status_hash[:status] = 1
  			status_hash[:msg] = "local files couldn't be found"				
  		end
  	end
  	
  	if File.exist?(s3_file_2_path)
  		uploadOriginalImagesToS3(s3_file_2_path, item_hash[:s3_file_2], order_number, status_hash)
  		FileUtils.copy(s3_file_2_path, file_2_path)
  		upRes(file_2_path)
  		if File.exist?(file_2_path)
  			status_hash[:status] = 0
  			status_hash[:msg] = "local files renamed"
  		else
  			status_hash[:status] = 1
  			status_hash[:msg] = "local files couldn't be found"
  		end
  	end
  end
  
  
  def deleteOriginalImages(order_hash, status_hash)
  	tmp_path = File.join(File.dirname(__FILE__), 'orders', order_hash[:order_number].to_s)
	  order_hash[:items].each do |item|
		
			s3_file_1 = item["image_file_id"]+'_print_front.jpg'
    	s3_file_2 = item["image_file_id"]+'_print_reverse.jpg'
			s3_file_1_path = File.join(tmp_path, s3_file_1) 
  		s3_file_2_path = File.join(tmp_path, s3_file_2)
  	
	  	if File.exist?(s3_file_1_path)
	  		FileUtils.remove(s3_file_1_path)
	  		status_hash[:msg] = "item: #{item} image(s): 1 removed"			
	  	end
	  	
	  	if File.exist?(s3_file_2_path)
	  		FileUtils.remove(s3_file_2_path)
	  		status_hash[:msg] = "item: #{item} image(s): 2 removed"
	  	end
		end
  end

  
  # creates csv from order_hash
  def createCSV(order_hash, item_hash, status_hash)
  	tmp_path = File.join(File.dirname(__FILE__), 'orders', order_hash[:order_number])
		s3_file_2_path = File.join(tmp_path, item_hash[:s3_file_2])
		
		if !File.exist?(s3_file_2_path)
			item_hash[:file_2] = "none"	
		end
  
		csv_arr = [{
			:OrderNum 				=> 	order_hash[:order_number],
			:ItemNum 					=> 	item_hash[:item_number],
			:StatusEmail 			=> 	order_hash[:status_email],
			:File1 						=> 	item_hash[:file_1],
			:File2 						=> 	item_hash[:file_2],
			:ProductCode 			=> 	item_hash[:product_code],
			:ProductName			=> 	item_hash[:product_desc],
			:Quantity 				=> 	item_hash[:quantity],
			:Paper 						=> 	item_hash[:paper],
			:TrimSize 				=> 	item_hash[:trim_size],
			:FinalSize 				=> 	item_hash[:final_size],
			:Score						=>  item_hash[:score],
			:ColorProcess 		=> 	item_hash[:color_process],
			:PickOutItem 			=> 	item_hash[:pick_out_item],
			:ShipMethod 			=> 	order_hash[:ship_option],
			:ShipToFirstName 	=>	order_hash[:ship_to_first_name],
			:ShipToLastName 	=> 	order_hash[:ship_to_last_name],
			:ShipToCompany 		=> 	order_hash[:ship_to_company],
			:ShipToAddr1 			=> 	order_hash[:ship_to_addr1],
			:ShipToAddr2 			=> 	order_hash[:ship_to_addr2],
			:ShipToCity 			=> 	order_hash[:ship_to_city],
			:ShipToState 			=> 	order_hash[:ship_to_state],
			:ShipToZip 				=> 	order_hash[:ship_to_zip],
			:ShipToPhone 			=> 	order_hash[:ship_to_phone],
			:UVCoating 				=> 	item_hash[:uv_coating],
			:Drill 						=> 	item_hash[:drill]
		}]
		
    order_number = order_hash[:order_number]
    item_number = item_hash[:item_number]
    file_name_base = "#{order_number}.#{item_number}"

		csv_path = File.join(File.dirname(__FILE__), 'orders', order_number, "#{file_name_base}.csv")
    column_names = csv_arr.first.keys
		
    CSV.open(csv_path, "w") do |csv|
      csv << column_names
      csv_arr.each do |x|
        csv << x.values
      end
    end
    
    if File.exist?(csv_path)
    	status_hash[:msg] = "csv created"
    else
    	status_hash[:status] = 1
    	status_hash[:msg] = "unable to create csv"
    end	
  end
  
  
  # uploads files to ftp
  def uploadFilestoFTP(order_hash, status_hash)
  	order_number = order_hash[:order_number]
    file_path = File.join(File.dirname(__FILE__), 'orders', order_number, "*")
    begin
	  	Net::FTP.open($CONFIG[:ftp_server]) do |ftp|
	      ftp.passive = true
	      ftp.login(user = $CONFIG[:ftp_user], passwd = $CONFIG[:ftp_pass])
	      ftp.mkdir("#{order_number}") if !ftp.list("/").any?{|dir| dir.match("#{order_number}")}
		            
	      Dir.glob(file_path).each do|file|
	        file_name = Pathname.new(file).basename.to_s
	        ftp.putbinaryfile(file, "/#{order_number}/#{file_name}", 1024)
	      end
	      status_hash[:ftp_status] = 1
	      status_hash[:ftp_msg] = 'files copied to ftp'
	    end
	  rescue => e
	   	status_hash[:status] = 1
	   	status_hash[:ftp_status] = 0
	   	status_hash[:ftp_msg] = 'not connected'
	   	status_hash[:s3_status] = 0
		  status_hash[:msg] = e
		end  
		
		#puts "ftp: #{status_hash[:ftp_msg]}"
		
  end
  
  
  # uploads csv and images to ftp, ties 3 times if error
  def ftpImagesAndCSVAndCreateZip(order_hash, status_hash)
  	order_number = order_hash[:order_number]
		tmp_path = File.join(File.dirname(__FILE__), 'orders', order_number)
  	zip = order_hash[:image_zip_file]
  	zip_path = File.join('orders/new/', zip)
    tmp_zip_path = File.join(tmp_path, zip)
    status_hash[:ftp_status] = 0
    		
		if status_hash[:status] == 0
	  	3.times do
	  		if status_hash[:ftp_status] == 0
			    	uploadFilestoFTP(order_hash, status_hash)  
			    	#status_hash[:msg] = "files were not uploaded to ftp"
				end
			end	  	
		end
		
		if status_hash[:status] == 0
	  	# zip downloaded files 
	    Zip::File.open(tmp_zip_path, 'w') do |zipfile|
				Dir["#{tmp_path}/**/**"].reject{|f|f==tmp_zip_path}.each do |file|
					begin  
			    	zipfile.add(file.sub(tmp_path+'/',''),file)   
			  	rescue Zip::ZipEntryExistsError
			  	end
				end
			end
	    status_hash[:msg] = "processed order has been zipped"
		end
  end

  
  # moves s3 images from /new to /processed or /failure accordingly
  def moveFilesAfterProcessing(order_hash, status_hash)
    self.s3Connect(status_hash)
    s3_bucket = status_hash[:s3_process_bucket]

    image_array = Array.new    
    status_hash[:s3_move_status] = 0
    
    order_number = order_hash[:order_number]
    tmp_path = File.join(File.dirname(__FILE__), 'orders', order_number)
    tmp_failure_path = File.join(File.dirname(__FILE__), 'orders/failure', order_number)
  	zip = order_hash[:image_zip_file]
  	tmp_zip_path = File.join(tmp_path, zip)
  	
  	if s3_bucket == 'is.happy.makr.orders'
	  	delete_zip_path = zip
	    s3_orig_path = zip
	    s3_finish_path = ''
		else
			delete_zip_path = File.join('orders/new/', zip)
	    s3_orig_path = File.join('orders/new/', zip)
	    s3_finish_path = 'orders/'
		end    
    
    # moves files to approriate folder based on order_status
    if status_hash[:status] == 0 && File.exist?(tmp_zip_path) && status_hash[:s3_status] == 1
    	s3_path = File.join(s3_finish_path, 'processed', order_number)
    	s3_zip_path = File.join(s3_path, "processed_#{order_number}.zip")
    	orig_s3_zip_path = File.join(s3_path, zip)
    	
    	begin
    		AWS::S3::S3Object.store(s3_zip_path, open(tmp_zip_path), s3_bucket)
    		if order_hash[:mode] == 'stress'
    			AWS::S3::S3Object.copy(s3_orig_path, orig_s3_zip_path, s3_bucket)
    		else
    			AWS::S3::S3Object.rename(s3_orig_path, orig_s3_zip_path, s3_bucket)
    		end
    		status_hash[:s3_move_status] = 1
    		status_hash[:msg] = 'files moved to s3 processed folder'
    	rescue AWS::S3::NoSuchKey
    		status_hash[:status] = 1
    		status_hash[:msg] = 'received order zip not found on s3'
    	end
    
    elsif status_hash[:status] == 3
    	s3_path = File.join(s3_finish_path, 'failure', order_number)
    	s3_zip_path = File.join(s3_path, zip)
    	begin    		
    		if order_hash[:mode] == 'stress'
    			AWS::S3::S3Object.copy(s3_orig_path, s3_zip_path, s3_bucket)
    		else
    			AWS::S3::S3Object.rename(s3_orig_path, s3_zip_path, s3_bucket)
    		end
    		status_hash[:s3_move_status] = 1
    		status_hash[:msg] = 'files moved to s3 failure folder'
    	rescue
    		status_hash[:status] = 1
    		status_hash[:msg] = 'received order zip not found on s3'
    	end
    end
    
    if status_hash[:status] == 0 && status_hash[:s3_move_status] == 1
    	status_hash[:s3_move_msg] = 'processed order zip moved to processed folder'
    elsif status_hash[:status] == 1 && status_hash[:s3_move_status] == 1
    	status_hash[:s3_move_msg] = 'received order zip moved to failure folder'
    else
    	status_hash[:s3_move_msg] = 'no s3 files were moved'	
    end

    FileUtils.rm_rf(tmp_path)
  end  
   	 
	
	# start logging
	def startTag(status_hash)
		started = Time.now.strftime("%I:%M:%S %p")
		pid = Process.pid
		started_full = Time.new
		puts "#{started_full.inspect}: checking for new orders"
		#$LOG.info("#{started_full.inspect}: checking for new orders")
	end
	
	
	# finish logging
	def finishTagAndUpdateAPI(order_hash, status_hash)
		
		if status_hash[:status] == 0
			status_hash[:finish_msg] = "success!"
			order_hash[:status] = 'TR'
			postStatustoAPI(order_hash, status_hash)
		else
			status_hash[:finish_msg] = "there was an error!"
			order_hash[:status] = 'ER'
			postStatustoAPI(order_hash, status_hash)
		end
		
		#puts "process time: #{order_time}"
		puts "last msg: #{status_hash[:msg]}"
		puts "finished: #{status_hash[:finish_msg]}"
	end
	
	
	# format phone number for receipt email
	def formatPhoneNumber(phone_number)
		phone_number = phone_number.split('.')
		phone_number = "(#{phone_number[0]}) #{phone_number[1]}-#{phone_number[2]}"
	
		phone_number
	end
	
	
	# construct shipping address for receipt email
	def constructShippingAddress(tmp_email_order_hash, email_order_hash)
		email_order_hash[:ship_to_first_name] = tmp_email_order_hash["response"]["order"]["ship_to_first_name"].to_s
		email_order_hash[:ship_to_last_name] = tmp_email_order_hash["response"]["order"]["ship_to_last_name"].to_s
		email_order_hash[:ship_to_company] = tmp_email_order_hash["response"]["order"]["ship_to_company"].to_s
		email_order_hash[:ship_to_addr1] = tmp_email_order_hash["response"]["order"]["ship_to_addr1"].to_s
		email_order_hash[:ship_to_addr2] = tmp_email_order_hash["response"]["order"]["ship_to_addr2"].to_s
		email_order_hash[:ship_to_city] = tmp_email_order_hash["response"]["order"]["ship_to_city"].to_s
		email_order_hash[:ship_to_state] = tmp_email_order_hash["response"]["order"]["ship_to_state"].to_s
		email_order_hash[:ship_to_zip] = tmp_email_order_hash["response"]["order"]["ship_to_zip"].to_s
		email_order_hash[:ship_to_phone] = formatPhoneNumber(tmp_email_order_hash["response"]["order"]["ship_to_phone"].to_s)
		email_order_hash[:ship_to_phone] = tmp_email_order_hash["response"]["order"]["ship_to_phone"].to_s
	
		email_order_hash[:shipping_address] = "#{email_order_hash[:ship_to_first_name]} #{email_order_hash[:ship_to_last_name]}<br />"
		email_order_hash[:shipping_address] += "#{email_order_hash[:ship_to_company]}<br />" if email_order_hash[:ship_to_company] !=""
		email_order_hash[:shipping_address] += "#{email_order_hash[:ship_to_addr1]}<br />"
		email_order_hash[:shipping_address] += "#{email_order_hash[:ship_to_addr2]}<br />" if email_order_hash[:ship_to_addr2] !=""
		email_order_hash[:shipping_address] += "#{email_order_hash[:ship_to_city]}, #{email_order_hash[:ship_to_state]} #{email_order_hash[:ship_to_zip]}<br />"  
		email_order_hash[:shipping_address] += "#{email_order_hash[:ship_to_phone]}<br />" if email_order_hash[:ship_to_phone] !=""
		
	end
	
	
	# construct order items for receipt email
	def constructOrderItems(email_order_items)
		email_items = ""
		email_order_items.each do |item|
			email_item_hash = Hash.new
			email_item_hash = {
				:item_name	=> item["project"]["title"].to_s,
				:item_amount	=> item["quantity"].to_s,
				:item_total	=> "%.2f" % (item["price"].to_f/100)
			}
			
			email_item = $CONFIG[:email_receipt_item].gsub('[item_name]', email_item_hash[:item_name]).gsub('[item_amount]', email_item_hash[:item_amount]).gsub('[item_total]', email_item_hash[:item_total])
			
			email_items += email_item
		end
		email_items
	end
	
	
	# construct payment method for receipt email
	def constructPaymentMethod(tmp_email_order_hash, email_order_hash)
		email_order_hash[:card_type] = tmp_email_order_hash["response"]["order"]["card_type"].to_s
		email_order_hash[:card_last4] = tmp_email_order_hash["response"]["order"]["card_last4"].to_s
		email_order_hash[:card_exp_month] = tmp_email_order_hash["response"]["order"]["card_exp_month"].to_s
		email_order_hash[:card_exp_year] = tmp_email_order_hash["response"]["order"]["card_exp_year"].to_s[-2..-1]
		
		if email_order_hash[:card_exp_month].length == 1
			email_order_hash[:card_exp_month] = "0#{email_order_hash[:card_exp_month]}"
		end
	
		email_order_hash[:payment_method] = "#{email_order_hash[:card_type]} - #{email_order_hash[:card_last4]} / Exp #{email_order_hash[:card_exp_month]}/#{email_order_hash[:card_exp_year]}"
	end
	
	
	# construct receipt from order number for receipt email
	def constructReceipt(order_number, status_hash)
	  $CONFIG[:api_path] = "/orders/receipt_detail/#{order_number}"
	  email_order_hash = Hash.new
	  response = RestClient.get(apiAuth, {:accept => :json})
	  
	  if response.to_s.include?('{"meta":{"status":200,"msg":"OK"}')
	  	tmp_email_order_hash = JSON.parse(response)
		else
			status_hash[:status] = 1
	  	status_hash[:msg] = "unable to get order info from api: #{response}"
		end
	
		email_order_hash[:order_items] = tmp_email_order_hash["response"]["order"]["order_items"]
		email_order_hash[:items_total] = "%.2f" % (tmp_email_order_hash["response"]["order"]["sub_total"].to_f/100)
		email_order_hash[:shipping_amount] = "%.2f" % (tmp_email_order_hash["response"]["order"]["ship_charge"].to_f/100)
		email_order_hash[:discount] = "%.2f" % (tmp_email_order_hash["response"]["order"]["discount"].to_f/100)
		email_order_hash[:tax_amount] = "%.2f" % (tmp_email_order_hash["response"]["order"]["tax_charge"].to_f/100)
		email_order_hash[:total_amount] = "%.2f" % (tmp_email_order_hash["response"]["order"]["grand_total"].to_f/100)
		email_order_hash[:payment_method] = tmp_email_order_hash["response"]["order"]["ship_option"].to_s
		email_order_hash[:shipment_method] = tmp_email_order_hash["response"]["order"]["shipping_decription"].to_s
		email_order_hash[:promo_code] = tmp_email_order_hash["response"]["order"]["promo_code"].to_s
		email_order_hash[:promo_code_description] = tmp_email_order_hash["response"]["order"]["promo_code_description"].to_s
		email_order_hash[:tax_rate] = tmp_email_order_hash["response"]["order"]["tax_rate"].to_s
		
		if email_order_hash[:promo_code] != ""
			email_order_hash[:promo] = "<strong>Promo Code: </strong>#{email_order_hash[:promo_code]} - #{email_order_hash[:promo_code_description]}<br/>"
		else
			email_order_hash[:promo] = " "
		end
		
		if email_order_hash[:discount] != '0.00'
			email_order_hash[:discount] = "<tr><td width='355px' height='100%'></td><td width='150px' style='text-align:right'><strong>Discount:</strong></td><td width='70px' style='text-align:right'>- $#{email_order_hash[:discount]}</td></tr>"
		else 
			email_order_hash[:discount] = " "
		end
		
		if email_order_hash[:tax_rate] != "0.000"
			email_order_hash[:tax_title] = "Tax (#{email_order_hash[:tax_rate]}%)"
		else
			email_order_hash[:tax_title] = "Tax"
		end
		
		email_order_hash[:tax] = "<tr><td width='355px' height='100%'></td><td width='150px' style='text-align:right'><strong>#{email_order_hash[:tax_title]}:</strong></td><td width='70px' style='text-align:right'>$#{email_order_hash[:tax_amount]}</td><tr>"
		
		constructShippingAddress(tmp_email_order_hash, email_order_hash)
		constructPaymentMethod(tmp_email_order_hash, email_order_hash)
		email_order_hash[:created_at] = (Date.parse tmp_email_order_hash["response"]["order"]["created_at"]).strftime("%b %d, %Y")	
		items = constructOrderItems(email_order_hash[:order_items])
	
		if status_hash[:status] == 0
			message = $CONFIG[:email_receipt]
				.gsub('[order_number]', order_number)
				.gsub('[items_total]', email_order_hash[:items_total])
				.gsub('[shipping_amount]', email_order_hash[:shipping_amount])
				.gsub('[promo]', email_order_hash[:promo])
				.gsub('[discount]', email_order_hash[:discount])
				.gsub('[total_amount]', email_order_hash[:total_amount])
				.gsub('[payment_method]', email_order_hash[:payment_method])
				.gsub('[tax]', email_order_hash[:tax])
				.gsub('[shipment_method]', email_order_hash[:shipment_method])
				.gsub('[shipping_address]', email_order_hash[:shipping_address])
				.gsub('[order_date]', email_order_hash[:created_at])
				.gsub('[items]', items)		
			message
		else
			status_hash[:msg] = 'unable to construct receipt'
			puts status_hash[:msg]
		end	
	end
	

end
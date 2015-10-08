#!/usr/bin/ruby

# dependencies
# gem install mail

require 'rubygems'
require 'net/imap'
require 'net/smtp'
require 'mail'
require File.join(File.dirname(__FILE__), 'process_handler.rb')


class EmailHandler

	# sends email
	def sendMail(order_hash)
		content = <<EOM
From: #{$CONFIG[:sender_address]}	 
To: #{order_hash[:email]}
Subject: #{order_hash[:subject]}	
Date: #{Time.now.rfc2822}
MIME-Version: 1.0
Content-Type: text/html; charset=UTF-8 

#{order_hash[:body]}

EOM

		smtp = Net::SMTP.new(
			$CONFIG[:smtp_server], 
			587
		)
		smtp.enable_starttls
		smtp.start(
			$CONFIG[:server],	 
			$CONFIG[:smtp_address], 
			$CONFIG[:smtp_password], 
			:login
		) do
			smtp.send_message(
				content, 
				$CONFIG[:smtp_address], 
				order_hash[:email]
			)
		end		 
	end


	#checks if order update has order_number and if status == SH, then it must have a tracking number and ship method
	def update_ok?(order_hash)
		if !order_hash[:order_number]
			return false
		elsif order_hash[:status] == 'SH' 
				return true unless order_hash[:tracking_number] == nil || order_hash[:ship_method] == nil
		else
			return true
		end 
	end


	# check print.status@happy.is for new messages and respond accordingly
	def checkNewMessageAndProcess(process, order_hash, status_hash)
		imap = Net::IMAP.new(
			$CONFIG[:imap_server], 
			$CONFIG[:imap_port], 
			usessl = true, 
			certs = nil, 
			verify = false
		)
		
		imap.login( 
			$CONFIG[:imap_address], 
			$CONFIG[:imap_password] 
		)
		
		imap.select('INBOX')
		
		#imap.search("UNSEEN").slice(0, 1).each do |message_id|
				
		imap.search("UNSEEN").each do |message_id|
			envelope = imap.fetch(message_id, "ENVELOPE")[0].attr["ENVELOPE"]
			msg = imap.fetch(message_id,'RFC822')[0].attr['RFC822'].to_s
			mail = Mail.read_from_string(msg)
			
			order_hash = Hash.new
			status_hash[:status] = 0
			order_hash[:subject] = mail.subject
			order_hash[:sender] = mail.from
			
			# parse email
			process.orderStatusFromSubject(order_hash, status_hash)		
			
			puts "order number: #{order_hash[:order_number]}"
			puts "tracking_number: #{order_hash[:tracking_number]}"
			puts "ship_method: #{order_hash[:ship_method]}"
			puts "before api order status: #{order_hash[:status]}" 
			
			# updates order status on api
			process.postStatustoAPI(order_hash, status_hash) if process.update_ok?(order_hash)		
			
			#send customer an email with order status 
			begin
				if order_hash[:api_status] != 1 && order_hash[:customer_email] != ""
					sendStatusEmail(order_hash, status_hash)
					puts "email sent to: #{order_hash[:customer_email]}"
				end
			rescue
				status_hash[:status] = 1
				status_hash[:msg] = 'unable to send email'
				exit
			end 
			
			
			puts "after api order status: #{order_hash[:status]}" 
		end
		
		if order_hash[:sender] == nil
			status_hash[:status] = 1
			status_hash[:msg] = 'no new mail'
			puts status_hash[:msg]
		else
			status_hash[:status] = 0
			status_hash[:msg] = "new email received and processed"
			puts status_hash[:msg]
		end

	end
	
	
	# send status email(s)
	def sendStatusEmail(order_hash, status_hash)
		order_hash[:email] = order_hash[:customer_email]

		# send shipped email to user
		if order_hash[:status] == 'SH' && order_hash[:tracking_number] != nil
			order_hash[:subject] = "Your Makr Order Has Shipped"
			order_hash[:message] = $CONFIG[:email_shipped].gsub('[tracking_number]', order_hash[:tracking_number])
			assembleAndSendEmail(status_hash, order_hash)
		
			order_hash[:email] = $CONFIG[:dev_email]
			order_hash[:subject] = "Makr Order #: #{order_hash[:order_number]} Has Shipped"
			order_hash[:body] = createShippedTeamEmailBody(order_hash)
			sendMail(order_hash)
		
		elsif order_hash[:status] == 'SH' && order_hash[:tracking_number].nil?
			# send email to dev team when status complete w/o tracking
			order_hash[:email] = $CONFIG[:dev_email]
			order_hash[:body] = createCompleteNoTrackingErrorEmailBody(order_hash)
			order_hash[:subject] = "ATTENTION: Received Completion Email Without Shipping Info"
			sendMail(order_hash)
		
		elsif order_hash[:status] == 'PF'
			# send printer problem email to customer
			order_hash[:subject] = "An Issue With Your Order"
			order_hash[:message] = $CONFIG[:email_issue]
			assembleAndSendEmail(status_hash, order_hash)
			
			# send printer error email to dev team
			order_hash[:email] = $CONFIG[:dev_email]
			order_hash[:subject] = "Makr Order #: #{order_hash[:order_number]} Has An Error"
			order_hash[:body] = createErrorTeamEmailBody(order_hash, status_hash)
			sendMail(order_hash)
		
		#send order canceled email to customer
		elsif order_hash[:status] == 'CN'
			order_hash[:subject] = "Your Makr Order is Canceled"
			order_hash[:message] = $CONFIG[:email_canceled]
			assembleAndSendEmail(status_hash, order_hash)
		
			# send order canceled email to dev team
			order_hash[:email] = $CONFIG[:dev_email]
			order_hash[:subject] = "Makr Order #: #{order_hash[:order_number]} Has Been Canceled"
			order_hash[:body] = createErrorTeamCanceledBody(order_hash)
			sendMail(order_hash)
			
		# send received email to printer and devteam	
		elsif status_hash[:status] == 0 && order_hash[:status] == nil			
			# to printer
			if order_hash[:mode] == 'stress'
				order_hash[:email] =	$CONFIG[:stress_test_email]
			else
				order_hash[:email] = $CONFIG[:printer_email]
			end
			order_hash[:subject] = "#{order_hash[:order_number]}"
			order_hash[:message] = createPrinterReceivedEmail(order_hash, status_hash)
			sendMail(order_hash)
			
			# to dev team
			if order_hash[:mode] == 'stress'
				order_hash[:email] =	$CONFIG[:stress_test_email]
			else
				order_hash[:email] = $CONFIG[:dev_email]
			end
			sendMail(order_hash)			
			status_hash[:msg] = 'status email(s) sent'

		elsif status_hash[:status] == 1 && order_hash[:status] == nil
			order_hash[:status_detail] = status_hash[:msg]

			# send problem email to customer
			if order_hash[:mode] == 'stress'
				order_hash[:email] =	$CONFIG[:stress_test_email]
			end
			order_hash[:subject] = "An Issue With Your Order"
			order_hash[:message] = $CONFIG[:email_issue]
			assembleAndSendEmail(status_hash, order_hash)
			
			# send error email to dev team
			if order_hash[:mode] == 'stress'
				order_hash[:email] =	$CONFIG[:stress_test_email]
			else
				order_hash[:email] = $CONFIG[:dev_email]
			end
			order_hash[:subject] = "Makr Order #: #{order_hash[:order_number]} Had An Error"
			order_hash[:body] = createErrorTeamEmailBody(order_hash, status_hash)
			sendMail(order_hash)	
		end
		
	end
	
	
	# assembles and sends email
	def assembleAndSendEmail(status_hash, order_hash)
		email_template = $CONFIG[:email_template]
		order_hash[:body] = email_template.gsub('[stylesheet]', $CONFIG[:email_stylesheet]).gsub('[message_content]', order_hash[:message]).gsub('[order_number]', order_hash[:order_number])
		
			begin
				sendMail(order_hash)
			rescue
				status_hash[:status] = 1
				status_hash[:msg] = 'unable to send email'
			end 

	end 
	

	# create body text for order
	def createPrinterReceivedEmailBody(order_hash)
		body = <<EOM	
OrderNum: #{order_hash[:order_number]}<br/>
ShipMethod: #{order_hash[:ship_option]}<br/>
ShipToFirstName: #{order_hash[:ship_to_first_name]}<br/>
ShipToLastName: #{order_hash[:ship_to_last_name]}<br/>
ShipToCompany: #{order_hash[:ship_to_company]}<br/>
ShipToAddr1: #{order_hash[:ship_to_addr1]}<br/>
ShipToAddr2: #{order_hash[:ship_to_addr2]}<br/>
ShipToCity: #{order_hash[:ship_to_city]}<br/>
ShipToState: #{order_hash[:ship_to_state]}<br/>
ShipToZip: #{order_hash[:ship_to_zip]}<br/>
ShipToPhone: #{order_hash[:ship_to_phone]}<br/>
<br/>
Order Items:<br/>
EOM

		body
	end

	
	# create body text for order item
	def itemForEmailBody(order_hash, item_hash)
		tmp_path = File.join(File.dirname(__FILE__), 'orders', order_hash[:order_number])
		file_2_path = File.join(tmp_path, item_hash[:file_2])
		
		if !File.exist?(file_2_path)
			item_hash[:file_2] = "none" 
		end
		
		item_body = <<EOM 
ItemNum: #{item_hash[:item_number]}<br/>
File1: #{item_hash[:file_1]}<br/>
File2: #{item_hash[:file_2]}<br/>
ProductCode: #{item_hash[:product_code]}<br/>
ProductName: #{item_hash[:product_desc]}<br/>
Quantity: #{item_hash[:quantity]}<br/>
Paper: #{item_hash[:paper]}<br/>
TrimSize: #{item_hash[:trim_size]}<br/>
FinalSize: #{item_hash[:final_size]}<br/>
Score: #{item_hash[:score]}<br/>
ColorProcess: #{item_hash[:color_process]}<br/>
PickOutItem: #{item_hash[:pick_out_item]}<br/>
UVCoating: #{item_hash[:uv_coating]}<br/>
Drill: #{item_hash[:drill]}<br/>
<br/>
EOM
		item_body
	end
	
	# create body text for team order shipped email
	def createShippedTeamEmailBody(order_hash)	
		body = <<EOM	
OrderNum: #{order_hash[:order_number]}<br/>
ShipMethod: #{order_hash[:ship_option]}<br/>
TrackingNum: #{order_hash[:tracking_number]}<br/>
ShipToFirstName: #{order_hash[:ship_to_first_name]}<br/>
ShipToLastName: #{order_hash[:ship_to_last_name]}<br/>
ShipToCompany: #{order_hash[:ship_to_company]}<br/>
ShipToAddr1: #{order_hash[:ship_to_addr1]}<br/>
ShipToAddr2: #{order_hash[:ship_to_addr2]}<br/>
ShipToCity: #{order_hash[:ship_to_city]}<br/>
ShipToState: #{order_hash[:ship_to_state]}<br/>
ShipToZip: #{order_hash[:ship_to_zip]}<br/>
EOM

		body
	end 
	
	# create body text for team order error email
	def createErrorTeamEmailBody(order_hash, status_hash)
		body = <<EOM	
OrderNum: #{order_hash[:order_number]}<br/>
Error: #{order_hash[:status_detail]}<br/>
S3 Status: #{status_hash[:s3_move_msg]}<br/>
EOM

		body
	end
	
	
	# create body text for team order canceled email
	def createErrorTeamCanceledBody(order_hash)
		body = <<EOM	
OrderNum: #{order_hash[:order_number]}<br/>
EOM

		body
	end 
	
	
		# create body text for status complete w/o tracking
	def createCompleteNoTrackingErrorEmailBody(order_hash)
		body = <<EOM	
OrderNum: #{order_hash[:order_number]}<br/>
EmailSubject: #{order_hash[:subject]}
EOM

		body
	end 

	
	# creates body for printer received mail containing order and items details
	def createPrinterReceivedEmail(order_hash, status_hash)
		process = ProcessHandler.new
		body = createPrinterReceivedEmailBody(order_hash)
		order_hash[:items].each do |item|
			body += itemForEmailBody(order_hash, process.createItemHash(item, order_hash, status_hash))
		end	 

		order_hash[:body] = body
	end

end

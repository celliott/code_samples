#!/usr/bin/ruby

# dependencies
require 'rubygems'
require 'json'

require File.join(File.dirname(__FILE__), 'email_handler.rb')
require File.join(File.dirname(__FILE__), 'process_handler.rb')
require File.join(File.dirname(__FILE__), 'settings_handler.rb')

process = ProcessHandler.new
email_handler = EmailHandler.new

started_full = Time.new
receipt = 0
order_number = ""
success = ""

status_hash = {
	:status 				=> 	0,
	:msg 						=> 	'started',
	:started_time		=>	started_full
}

pending_emails = process.getPendingEmails(status_hash)

if pending_emails.any?
	pending_emails.each do |email| 
		receipt = 0
		email_hash = {
			:recipient 						=> 	email["recipient"],
			:subject 							=> 	email["subject"],
			:template 						=> 	email["template"],
			:template_data 				=> 	email["template_data"],
		}
			
		begin
			if email["template_data"] != 'null' || email_hash[:template] != 'none'
				email_hash[:template_data] = JSON.parse(email["template_data"])
			end	
		rescue
		end	
		
		if email_hash[:template] == 'none'
			email_hash[:template] = email_hash[:template_data]	
		elsif email_hash[:template] == 'welcome'
			email_hash[:template] = $CONFIG[:email_welcome]
		elsif email_hash[:template] == 'order_received'
			receipt = 1
			email_hash[:template] = $CONFIG[:email_receipt]
		elsif email_hash[:template] == 'order_canceled'
			email_hash[:template] = $CONFIG[:email_canceled]
		elsif email_hash[:template] == 'promo_code_granted'
			email_hash[:template] = $CONFIG[:email_promo_code]
		elsif email_hash[:template] == 'email_changed'
			email_hash[:template] = $CONFIG[:email_changed]
		elsif email_hash[:template] == 'password_forgot'
			email_hash[:template] = $CONFIG[:email_password_forgot]	
		elsif email_hash[:template] == 'password_changed'
			email_hash[:template] = $CONFIG[:email_password_changed]
		elsif email_hash[:template] == 'referral_invitation'
			email_hash[:template] = $CONFIG[:email_referral_invitation]
		elsif email_hash[:template] == 'referral_accepted_grant'
			email_hash[:template] = $CONFIG[:email_referral_accepted_grant]
		elsif email_hash[:template] == 'referral_accepted_left'
			email_hash[:template] = $CONFIG[:email_referral_accepted_left]
		elsif email_hash[:template] == 'welcome_referral'
			email_hash[:template] = $CONFIG[:email_welcome_referral]
		elsif email_hash[:template] == 'cohort_engage_new_user_to_order'
			email_hash[:template] = $CONFIG[:email_cohort_engage_new_user_to_order]				
		end
		
		begin
			if email["template_data"] != 'null' && email["template"] != 'none'
				email_hash[:template_data].each do |replace, value|
					if replace != 'description'
						value = value.to_s
						if receipt == 1
							order_number = value if replace == 'order_number'
							email_hash[:template] = process.constructReceipt(order_number, status_hash)
							success = "receipt constructed for #{email_hash[:recipient]}"
						else
						  email_hash[:template] = email_hash[:template].gsub("[#{replace}]", value)
						end
					end
				end
			end
		rescue => e
			status_hash[:status] = 1
			status_hash[:msg] = e
		end
		
		if e
			puts "api error: #{e}"
		end
		
		if receipt == 1 && order_number != ""
			puts "success: #{success}"
			puts "receipt sent: #{receipt}"
			puts "order_number: #{order_number}"
		end
				
		order_hash = {
			:email					=> 	email_hash[:recipient],
			:subject				=>	email_hash[:subject],
			:message				=> 	email_hash[:template].to_s,
			:status					=>	'pending_email',
		}	
		
		if email["template"] != 'none'
			email_template = $CONFIG[:email_template]
			order_hash[:body] = email_template.gsub('[stylesheet]', $CONFIG[:email_stylesheet]).gsub('[message_content]', order_hash[:message])
		else
			order_hash[:body] = email_hash[:template].to_s
		end	
		
		order_hash[:body].force_encoding("UTF-8")
		order_hash[:subject].force_encoding("UTF-8")
		
		if status_hash[:status] == 0		
			begin
	    	email_handler.sendMail(order_hash)
	    	status_hash[:msg] = "message sent to #{order_hash[:email]}"
	    rescue
	    	status_hash[:status] = 1
	  		status_hash[:msg] = 'unable to send email'
	    end	
    end
    
    puts Time.new
    puts "status: #{status_hash[:msg]}"
	end

else
	puts Time.new
	puts "status: no pending emails"	
end
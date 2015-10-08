#!/usr/bin/ruby

require 'net/http'

class SettingsHandler
	
	# create $CONFIG for all the scripts
	def initialize
		web_url = 'http://www.makrplace.com/email_templates'
		
		$CONFIG = {
			:processes	=>	10,
		
			# api auth params
			:app_key							=>	'app_key',
			:app_secret						=>	'app_secret',
			:api_url							=>	'https://api.example.com/',
			:api_path							=>	'/orders',
			:api_version					=>	'v1',
			:timestamp						=>	Time.now.to_i,
			
			# aws auth params
			:aws_key							=>	'aws_key',
			:aws_secret						=>	'aws_secret',
			:aws_buckets					=>	['aws_bucket'],
			:s3_original_bucket		=>	"aws_bucket",
			
			
			# ftp auth params			
			:ftp_server						=>	'ftp.example.com',
			:ftp_user							=>	'ftp_user',
			:ftp_pass							=>	'ftp_pass',
			
			# ftp setting for stress mode
			:ftp_server_stress		=>	'ftp_server_stress',
			:ftp_user_stress			=>	'ftp_user_stress',
			:ftp_pass_stress			=>	'ftp_pass_stress',
			:stress_test_email		=>	'stress_test_email',
			
			# email auth params
			:status_email					=>	'status_email',
			:dev_email						=>	'dev_email', 
			:printer_email				=>	'printer_email',
			:imap_address					=>	'imap_address',
			:imap_password				=>	'imap_password',
			:smtp_address					=>	'smtp_address',
			:sender_address				=>	'sender_address',
			:smtp_password				=>	'smtp_password',
			:imap_server					=>	'imap.gmail.com',
			:smtp_server					=>	'smtp.mandrillapp.com',
			:server								=>	'gmail.com',
			:imap_port						=>	993,
			
			# email template locations
			:email_template													=>	Net::HTTP.get(URI("#{web_url}/email_template.html")).to_s,
			:email_stylesheet												=>	Net::HTTP.get(URI("#{web_url}/style.css")).to_s,
			:email_received													=>	Net::HTTP.get(URI("#{web_url}/received.html")).to_s,
			:email_received2												=>	Net::HTTP.get(URI("#{web_url}/received2.html")).to_s,
			:email_started													=>	Net::HTTP.get(URI("#{web_url}/started.html")).to_s,
			:email_shipped													=>	Net::HTTP.get(URI("#{web_url}/shipped.html")).to_s,
			:email_canceled													=>	Net::HTTP.get(URI("#{web_url}/canceled.html")).to_s,
			:email_issue														=>	Net::HTTP.get(URI("#{web_url}/issue.html")).to_s,
			:email_error														=>	Net::HTTP.get(URI("#{web_url}/error.html")).to_s,
			:email_error_printer										=>	Net::HTTP.get(URI("#{web_url}/error_printer.html")).to_s,
			:email_changed													=>	Net::HTTP.get(URI("#{web_url}/email_changed.html")).to_s,
			:email_password_forgot									=>	Net::HTTP.get(URI("#{web_url}/password_forgot.html")).to_s,
			:email_password_changed									=>	Net::HTTP.get(URI("#{web_url}/password_changed.html")).to_s,
			:email_promo_code												=>	Net::HTTP.get(URI("#{web_url}/promo_code.html")).to_s,
			:email_welcome													=>	Net::HTTP.get(URI("#{web_url}/welcome.html")).to_s,
			:email_receipt													=>	Net::HTTP.get(URI("#{web_url}/receipt.html")).to_s,
			:email_receipt_item											=>	Net::HTTP.get(URI("#{web_url}/receipt_item.html")).to_s,
			:email_referral_invitation							=>	Net::HTTP.get(URI("#{web_url}/referral_invitation.html")).to_s,
			:email_referral_accepted_grant					=>	Net::HTTP.get(URI("#{web_url}/referral_accepted_grant.html")).to_s,
			:email_referral_accepted_left						=>	Net::HTTP.get(URI("#{web_url}/referral_accepted_left.html")).to_s,
			:email_welcome_referral									=>	Net::HTTP.get(URI("#{web_url}/welcome_referral.html")).to_s,
			:email_cohort_account_creation					=>	Net::HTTP.get(URI("#{web_url}/cohort_account_creation.html")).to_s,
			:email_cohort_engage_new_user_to_order	=>	Net::HTTP.get(URI("#{web_url}/cohort_engage_new_user_to_order.html")).to_s,
		}	 
		
		$CONFIG
	end
	
end

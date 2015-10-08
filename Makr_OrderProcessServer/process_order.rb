#!/usr/bin/ruby

# dependencies
require 'rubygems'
require 'logger'
require File.join(File.dirname(__FILE__), 'email_handler.rb')
require File.join(File.dirname(__FILE__), 'process_handler.rb')
require File.join(File.dirname(__FILE__), 'settings_handler.rb')

# initiate ProcessHandler and EmailHandler Classes
process = ProcessHandler.new
email = EmailHandler.new
args = ARGV
$LOG = Logger.new(File.join(File.dirname(__FILE__), 'logs/process_orders_ruby.log'), 'monthly');

status_hash = {
	:status				=>	0,
	:msg					=>	'started',
	:start_time		=>	Time.now
}

def status_ok?(status_hash)
	return true if status_hash[:status] == 0
end

begin
	# prints order started tag
	process.startTag(status_hash) if status_ok?(status_hash)

	# get next pending order from api, create csv and download images
	order_hash = process.getNextPendingOrder(status_hash) if status_ok?(status_hash)

	# set stress mode params if stress arg is set or .zip file name is stress.zip
	process.stressMode(args, order_hash)

	# downloads order zip from s3
	process.s3Download(order_hash, status_hash) if status_ok?(status_hash)

	# uploads images, creates csv and renames images for each item in order
	order_hash[:items].each do |item|
	
  # creates hash for each item
  item_hash = process.createItemHash(item, order_hash, status_hash) if status_ok?(status_hash)

  # creates csv and renames images
  process.renameImages(order_hash, item_hash, status_hash) if status_ok?(status_hash)
  process.createCSV(order_hash, item_hash, status_hash) if status_ok?(status_hash)
	end

	# deletes unziped image files
	process.deleteOriginalImages(order_hash, status_hash) if status_ok?(status_hash)

	# uploads images to ftp and creates zip of order files
	process.ftpImagesAndCSVAndCreateZip(order_hash, status_hash) if status_ok?(status_hash)

	# send email to user on success and dev team on failure
	email.sendStatusEmail(order_hash, status_hash)

	# moves s3 order zip to processed or failure accordingly
	process.moveFilesAfterProcessing(order_hash, status_hash)

rescue => e
end		 

# prints order process info
process.finishTagAndUpdateAPI(order_hash, status_hash)

puts "last msg: #{status_hash[:msg]}"
puts "finished: #{status_hash[:finish_msg]}"
$LOG.info("finished: #{status_hash[:finish_msg]}")
$LOG.info("last msg: #{status_hash[:msg]}")
$LOG.info("script errors: #{e}") if e

#!/usr/bin/ruby

# dependencies
require 'rubygems'
require 'logger'
require File.join(File.dirname(__FILE__), 'email_handler.rb')
require File.join(File.dirname(__FILE__), 'process_handler.rb')

email = EmailHandler.new
process = ProcessHandler.new
started_full = Time.new

order_hash = Hash.new
status_hash = {
	:status 	=> 	0,
	:msg 			=> 	'started'
}

puts "#{started_full.inspect}: checking for new email"

# check for new email and process emails
email.checkNewMessageAndProcess(process, order_hash, status_hash)


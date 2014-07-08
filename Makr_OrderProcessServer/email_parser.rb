#!/usr/bin/ruby

# dependencies
require 'rubygems'
require 'logger'
require File.join(File.dirname(__FILE__), 'process_handler.rb')



process = ProcessHandler.new
started_full = Time.new


order_hash = Hash.new
status_hash = {
	:status 	=> 	0,
	:msg 			=> 	'started'
}

ARGV.each do|a|
  order_hash[:email_subject] = a.to_i
	break
end

order_hash[:subject] = 'Start 131119000001' if order_hash[:email_subject] == 0
order_hash[:subject] = 'COMPLETE 131119000001.2 Ground 576443308859' if order_hash[:email_subject] == 1
order_hash[:subject] = 'COMPLETE 131119000005.3 2ndDayAir 576453309936' if order_hash[:email_subject] == 2
order_hash[:subject] = 'COMPLETE 2ndDayAir 576443308859' if order_hash[:email_subject] == 3
order_hash[:subject] = 'COMPLETE 131119000001.1 NextDayAirSaver' if order_hash[:email_subject] == 4
order_hash[:subject] = 'COMPLETE 131119000001.1  576443308859' if order_hash[:email_subject] == 5
order_hash[:subject] = 'COMPLETE 131119000001' if order_hash[:email_subject] == 6
order_hash[:subject] = 'COMPLETE SAMPLE0001' if order_hash[:email_subject] == 7
order_hash[:subject] = 'ERROR 131119000001 Printer had a problem' if order_hash[:email_subject] == 8

$CONFIG[:api_url] = 'https://happy-makr-dev.herokuapp.com/'

# parse email
process.orderStatusFromSubject(order_hash, status_hash)		


puts "order number: #{order_hash[:order_number]}"

puts "status: #{order_hash[:status]}" 
puts "api_code: #{order_hash[:api_code]}"

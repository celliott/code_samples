#!/usr/bin/ruby

require 'rubygems'
require 'logger'
require File.join(File.dirname(__FILE__), 'process_handler.rb')

12.times do		
	# initiate ProcessHandler and EmailHandler Classes
	process = ProcessHandler.new
	
	# check to make sure that too many processes aren't running and there is enough free memory
	process.checkAvailableResources
	
	# run script if there are available resources
	Thread.new do
		process_order = `"#{File.join(File.dirname(__FILE__), 'process_order.rb')}"`
		puts process_order
		if process_order.include? 'no new orders'
			exit
		end
	end
	
	sleep 5
	
end

#!/usr/bin/ruby

running_count = `sudo ps cax | grep -E "init_pending_em" | wc -l`
if running_count.to_i > 1
	puts 'quitting, check init_pending_emails is already running'
	exit
end

5.times do
	begin
		running_count = `sudo ps cax | grep -E "pending_emails" | wc -l`
	rescue
		running_count = 0
	end
	
	if running_count.to_i > 0
		puts 'quitting, check pending_emails is already running'
		exit
	end

	Thread.new do
		pending_emails = `"#{File.join(File.dirname(__FILE__), 'pending_emails.rb')}"`
		puts pending_emails
	end
	
	sleep 60
	
end

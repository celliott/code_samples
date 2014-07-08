desc "This task is called by the Heroku scheduler add-on"
task :process_orders => :environment do
  puts "Processing orders..."
  process = ProcessOrdersController.new
  process.check_for_new_orders
  puts "done."
end
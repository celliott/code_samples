Makr_OrderProcessServer
=======================

Processes new Makr app orders. Scriptes located in /ruby

1. process_order.rb - checks the api once a minute for /next_pending_order and processes any new order
	
2. check_email.rb - checks print.status@happy.is for new messages from the printer and responds accordingly

3. check_cancelled_orders.rb - check api for /next_cancelled_job and notifies the user the job has been cancelled


url: order.makrplace.com


handlers:
1. process_handler.rb

2. gmail_handler.rb 

3. settings_handler.rb


html email templates (located in /ruby/email_templates):

1. cancelled.html

2. error.html

3. error_printer.html

4. problem.html

5. email.html

6. received.html

7. received_printer.html

8. shipped.html

9. started.html



Script descriptions:

settings_handler.rb

This script is initiated by the ProcessHandler and creates a global hash called $CONFIG; which contains all the params for authentication and email that all the scrips use. Edit this page if any of the authentication/email params.

class: 
SettingsHandler

use:
$CONFIG[:param]

params:
# api auth params: 
app_key, app_secret, api_url, api_path, api_version, timestamp

# aws auth params:
aws_key, aws_secret, aws_bucket

# ftp auth params:   
ftp_server, ftp_user, ftp_pass

# email auth params:
status_email, dev_email, printer_email, imap_address, imap_password, smtp_address, smtp_password, imap_server, smtp_server, server, imap_port


check_email.rb
This script checks the gmail account $CONFIG[:imap_address] using $CONFIG[:imap_password] for new messages and loops through any new messages parses the subject and send emails/updates the api accordingly. Uses email_handler methods to check/send email. Uses process_handler methods to update api.

if subject  = START 130823000021
  - post the status of IP to the api for the order
  - send user 'started' email 

if subject  = COMPLETE 130823000021.1
  - do nothing, there is no completed but not shipped status in the api

if subject  = COMPLETE 130823000021.2 FDX 930293848940
  - post the status of SH and tracking number to the api for the order
  - send user 'shipped' email 

if subject  = ERROR 130823000021.1 Missing image files
  - post the status of to the api for the order
  - send user 'problem' email w/o the error description
  - send devteam 'err
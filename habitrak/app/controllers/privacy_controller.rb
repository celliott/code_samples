class PrivacyController < ApplicationController
      
   def index
	   if current_user_id
	     show_menu
	   else
	     show_public_menu
	   end  
   end

   
end

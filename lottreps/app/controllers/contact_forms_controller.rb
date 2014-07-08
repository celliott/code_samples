class ContactFormsController < ApplicationController

  def create
    message = ContactForm.new(params[:contact_form])
    respond_to do |format|
      if message.deliver
        flash[:success] = "Email has been sent."
        format.js { render '/layouts/index' }
      else
        flash[:error] = "Email could not be sent."
        format.js { render '/layouts/index' }
      end
    end
  end

end
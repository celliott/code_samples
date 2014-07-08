class EmailFormsController < ApplicationController
  #respond_to :html

  def index
  end

  def create
    message = EmailForm.new(params[:email_form])
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
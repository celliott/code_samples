require 'securerandom'

class UsersController < ApplicationController
  
  before_filter :confirm_logged_in, :except => [:new, :create, :login, :attempt_login, :logout, :reset_password, :change_password, :update_password, :send_reset_password]
     
  def new
    show_public_menu
    @user = User.new
  end

  def create
    show_public_menu
    @user = User.new(params[:user])
    if @user.save
      UserMailer.registration_confirmation(@user).deliver
      session[:user_id] = @user.id      
      redirect_to habits_url 
    else
      render("new")
    end
  end
  
  def edit
    show_menu
    @user = User.find(current_user_id)
  end
  
  def change_password
    show_public_menu
    @user = User.find_by_email(params[:email])
  end
  
  def reset_password
    show_public_menu
    @new_password = SecureRandom.hex(10)
  end
  
  def send_reset_password
    @user = User.find_by_email(params[:user][:email])
    if @user
      @user.update_attributes(params[:user])
      @user = User.find_by_email(params[:user][:email])
      UserMailer.reset_password(@user).deliver
      flash[:alert] = 'Password reset email has been sent.'
      redirect_to root_url
    else
		  flash[:error] = "No user with that email exists" 
      redirect_to reset_password_url
    end
  end
  
  def update
    show_menu
    @user = User.find(current_user_id)
    if @user.update_attributes(params[:user])
      flash[:error] = 'Password updated.'
      redirect_to(:controller => 'settings')
    else
      render("edit")
    end
  end
  
  def update_password
    show_public_menu
    email = params[:user][:email].gsub('%40', '@')
    @user = User.find_by_email(params[:user][:email])
    if @user.password == params[:user][:password_reset]
	    @user = User.find(@user.id)
	    if @user.update_attributes(params[:user])
	      flash[:alert] = 'Password updated.'
	      session[:user_id] = @user.id
        redirect_to habits_url
	    else
	      flash[:error] = "Passwords don't match or is empty."
	      redirect_to :controller => 'change_password', :email => params[:user][:email], :token => params[:user][:password_reset]
	    end
	  else
	    flash[:error] = 'Password reset incorrect, Please reset password again.'
	    redirect_to reset_password_url
	  end  
  end

  def delete
    show_menu
    @user = User.find(@current_user_id)
    render("delete")
  end

  def destroy
    show_menu
    @user = User.find(current_user_id)
    if @user.email == params[:email][:delete_user]
      User.find(current_user_id).destroy
      Habit.where('user_id=?', current_user_id).delete_all
      UsersHabit.where('user_id=?', current_user_id).delete_all
      HabitsUser.where('user_id=?', current_user_id).delete_all
      session.delete :user_id 
      cookies.delete :user_id 
      cookies.delete :trend
      flash[:alert] = "User removed. Goodbye."
      redirect_to root_url
    else
      flash[:notice] = "Email does not match." 
      render("delete")
    end  
  end
  
end
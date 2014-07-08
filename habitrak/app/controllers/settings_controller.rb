class SettingsController < ApplicationController

  before_filter :confirm_logged_in

  def index
		show_menu
		@habits = Habit.order("name ASC").find_all_by_user_id([0, current_user_id])
		@user = User.find(current_user_id)
		@habit_types = UsersHabit.where('user_id=?', current_user_id)
  end
  
  def habit_types
		@habits = Habit.order("name ASC").find_all_by_user_id([0, current_user_id])
		@habit_types = UsersHabit.where('user_id=?', current_user_id)
		  
  end
  
  def create
	    @habits = Habit.order("name ASC").find_all_by_user_id([0, current_user_id])
			@habit_types = UsersHabit.where('user_id=? AND habit_id = ?"', current_user_id, params[:id])
	    @habit = Habit.create!(params[:habit_type].merge(:user_id => current_user_id))
	    @user = User.find(current_user_id)
	    @habit = Habit.where('name=? AND user_id=?', params[:habit_type][:name], current_user_id)
	    if @habit.exists?
	      flash[:notice] = "#{params[:habit_type][:name]} has been added and selected!"   
	      @user.habits << @habit
      else
        flash[:error] = '#{params[:habit_type][:name]} was not added.'
        redirect_to habit_types_url
      end
    respond_to do |format|
      format.html { redirect_to settings_url}
      format.js
    end  
  end
  
  def add
    @user = User.find(current_user_id)
    @habit = Habit.find(params[:id])
    @habit_type = UsersHabit.where('user_id=? AND habit_id = ?', current_user_id, params[:id])
    if @habit_type.exists?
      flash[:notice] = "#{@habit.name} has been unselected"
      @user.habits.delete(@habit)
    else
      @user.habits << @habit
      flash[:notice] = "#{@habit.name} selected"
    end
    respond_to do |format|
      format.html { redirect_to settings_url}
      format.js
    end
  end

  def destroy
    @user = User.find(current_user_id)
    @habit = Habit.find(params[:id])
    @user.habits.delete(@habit)
    @habit.users.delete(@user)
    Habit.find(params[:id]).destroy
    flash[:notice] = "#{@habit.name} has been removed"
    respond_to do |format|
      format.html { redirect_to settings_url}
      format.js
    end 
  end
  
end

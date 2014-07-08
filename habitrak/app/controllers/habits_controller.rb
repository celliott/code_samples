class HabitsController < ApplicationController
  
  before_filter :confirm_logged_in
  
  def entry
    show_menu 
    habit_ids = UsersHabit.where("user_id=?", current_user_id).collect {|i| i.habit_id}
    @habits = Habit.order("name ASC").where(:id => habit_ids)
    @user = User.find(current_user_id)
    if @habits.empty?
      redirect_to(:controller => 'settings')
      flash[:alert] = 'add or select some habits to get started'
    end
  end
  
  def chart
    @current_user_id = current_user_id
    daily_habits = HabitsUser.where("user_id=?", @current_user_id).collect {|i| i.habit_id}
    @habits = Habit.order("name ASC").where(:id => daily_habits)
    cookies[:trend] = { :value => '1' } if !cookies[:trend]
    respond_to do |format|
      format.html
      format.js
    end
  end
  
  def trends
    show_menu  
    habit_check = HabitsUser.where("user_id=?", current_user_id).count
    if habit_check < 1
      redirect_to(:controller => 'habits')
      flash[:alert] = 'you need to track a habit before viewing trends'
    end
  end
  
  def create
    @habit = Habit.new(params[:habit])
    if @habit.save
      redirect_to root_url, notice: "#{@habit.name} has been added!"
    else
      flash[:notice] = '#{@habit.name} not created.'
      render("settings")
    end
  end
  
  def add
    @habit = Habit.find(params[:add][:habit])
    @habit.users << User.find(current_user_id)
    @habit_user = HabitsUser.where('user_id = ? AND habit_id=?', current_user_id, @habit).last
    @habit_user.habit_time = Time.now.in_time_zone(cookies[:time_stamp]).to_datetime
    @habit_user.save
    flash[:notice] = "#{@habit.name} recorded!"
    redirect_to(:action => 'entry')
  end
  
  def undo
    @user = User.find(current_user_id)
    @habit = Habit.find(params[:undo][:habit])
    @habit_user = HabitsUser.where('user_id = ? AND habit_id=?', current_user_id, @habit).last
    @habit_user.delete
    flash[:notice] = "last #{@habit.name} removed!"
    redirect_to(:action => 'entry')
  end

  def destroy
    Habit.find(params[:id]).destroy
    flash[:notice] = "Habit removed."
    redirect_to(:action => 'list')
  end
  
end

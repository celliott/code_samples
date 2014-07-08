class Habit < ActiveRecord::Base
  
  attr_accessible :name, :user_id
  
  has_many :habits_user
  has_many :users, :through => :habits_user
  
  validates :name, :presence => true
  validates_uniqueness_of :name, :case_sensitive => false, :scope => :user_id
  
  before_save { |habit| habit.name = habit.name.downcase }

end

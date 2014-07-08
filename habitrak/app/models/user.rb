require 'digest/sha1'

class User < ActiveRecord::Base
  attr_accessible :email, :password, :password_confirmation, :password_reset, :last_name, :first_name
  
  attr_reader :password_reset
  attr_accessor :password_reset
  
  has_many :users_habit
  has_many :habits, :through => :users_habit
    
  EMAIL_REGEX = /^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}$/i
    
  validates :password, :presence => true, :confirmation => true
  validates :first_name, :presence => true, :length => { :maximum => 25 }
  validates :last_name, :presence => true, :length => { :maximum => 50 }
  validates :email, :presence => true, :uniqueness => true, :length => { :maximum => 100 }, 
    :format => EMAIL_REGEX, :confirmation => true
  validates_length_of :password, :within => 8..25, :on => :create

  before_save :create_password
  after_save :clear_password
  
  def name
    "#{first_name} #{last_name}"
  end
  
  def self.authenticate(email="", pass="")
    user = User.find_by_email(email)
    if user && user.password == Digest::SHA256.hexdigest(pass)
      return user
    else
      return false
    end
  end 
   
  private
  
  def create_password
    unless password.blank?
      self.password = Digest::SHA256.hexdigest(password)
    end
  end

  def clear_password
    self.password = nil
  end
  
end
